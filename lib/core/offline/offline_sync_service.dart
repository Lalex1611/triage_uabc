import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sistema_triage/core/offline/offline_capture_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class CaptureRemote {
  Future<Capture> create(
    String account,
    String kind,
    String id,
    Capture payload,
  );
  Future<void> upload(
    String kind,
    String remoteId,
    Capture photo,
    Uint8List bytes,
  );
  Future<void> link(
    String account,
    String kind,
    String remoteId,
    Capture photo,
  );
}

abstract class SupabaseOfflineCaptureRemote implements CaptureRemote {
  SupabaseOfflineCaptureRemote(this.client);
  final SupabaseClient client;
  static const timeout = Duration(seconds: 20);

  String photoPath(String id, Capture photo) =>
      '$id/${photo['id']}.${photo['extension']}';

  @override
  Future<void> upload(
    String kind,
    String remoteId,
    Capture photo,
    Uint8List bytes,
  ) async {
    final bucket = client.storage.from(
      kind == 'incident' ? 'incident_photos' : 'patient_photos',
    );
    try {
      await bucket
          .uploadBinary(
            photoPath(remoteId, photo),
            bytes,
            fileOptions: FileOptions(contentType: photo['mime'] as String),
          )
          .timeout(timeout);
    } on StorageException catch (e) {
      // La ruta con UUID se conserva al reintentar si se pierde la respuesta.
      // La RPC comprueba que el archivo exista y pertenezca a la cuenta antes
      // de vincularlo.
      if (e.statusCode != '409' && e.error != 'Duplicate') rethrow;
    }
  }
}

typedef _SyncSession = ({String account, String scope, int generation});

/// Procesa un solo lote a la vez y guarda el avance para retomarlo si la app
/// se cierra.
class OfflineSyncService extends ChangeNotifier {
  OfflineSyncService({
    required this.store,
    required this.remote,
    required this.currentAccount,
    required this.sessionGeneration,
    this.storageScope,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final OfflineCaptureStore store;
  final CaptureRemote remote;
  final String? Function() currentAccount;
  final int Function() sessionGeneration;
  final String? Function(String account)? storageScope;
  final DateTime Function() now;
  Future<void>? _running;
  _SyncSession? _runningSession;
  bool _runningForced = false;
  Completer<void>? _forcedFollowUp;
  bool get syncing => _running != null;
  String? storageError;
  (String, int)? _authenticationRequired;

  _SyncSession? get _session {
    final account = currentAccount();
    if (account == null) return null;
    final scope = storageScope == null ? account : storageScope!(account);
    if (scope == null) return null;
    return (account: account, scope: scope, generation: sessionGeneration());
  }

  Future<void> sync({bool force = false}) {
    final session = _session;
    if (_running case final running?) {
      if (force && !_runningForced && session == _runningSession) {
        return (_forcedFollowUp ??= Completer<void>()).future;
      }
      return running;
    }
    if (session == null ||
        _authenticationRequired == (session.account, session.generation)) {
      return Future.value();
    }
    return _start(session, force, Completer<void>());
  }

  Future<void> _start(
    _SyncSession session,
    bool force,
    Completer<void> completion,
  ) {
    _runningSession = session;
    _runningForced = force;
    _running = completion.future;
    completion.complete(
      _run(
        session.account,
        session.scope,
        session.generation,
        force,
      ).whenComplete(() {
        final followUp = _forcedFollowUp;
        _forcedFollowUp = null;
        if (followUp != null &&
            _session == session &&
            _authenticationRequired != (session.account, session.generation)) {
          _start(session, true, followUp);
          return;
        }
        _running = null;
        _runningSession = null;
        followUp?.complete();
        notifyListeners();
      }),
    );
    notifyListeners();
    return completion.future;
  }

  Future<void> _run(
    String account,
    String scope,
    int generation,
    bool force,
  ) async {
    bool authorized() =>
        currentAccount() == account &&
        sessionGeneration() == generation &&
        (storageScope == null || storageScope!(account) == scope);
    try {
      storageError = null;
      final (rows: captures, :unreadableIds) = await store.list(scope);
      final unreadable = unreadableIds.toSet();
      captures.sort(
        (a, b) => (a['kind'] == 'incident' ? 0 : 1).compareTo(
          b['kind'] == 'incident' ? 0 : 1,
        ),
      );
      for (final c in captures) {
        if (!authorized()) return;
        if (c['state'] == 'synced' || c['state'] == 'attention') continue;
        final next = DateTime.tryParse(c['next_attempt'] as String? ?? '');
        if (!force && next != null && next.isAfter(now())) continue;
        final payload = Capture.from(c['payload'] as Map);
        final parentId = c['parent_id'] as String?;
        if (parentId != null) {
          if (unreadable.contains(parentId)) continue;
          // Tras el borrado local, incident_id sigue identificando el incidente
          // en el servidor porque la RPC lo crea con el UUID de la captura.
          final parent = await store.get(scope, parentId);
          if (parent != null) {
            if (parent['remote_id'] == null) {
              c['message'] = parent['state'] == 'attention'
                  ? 'El incidente requiere atención antes de enviar este paciente.'
                  : 'Espera la confirmación del incidente.';
              await store.save(scope, c);
              continue;
            }
            payload['incident_id'] = parent['remote_id'];
            c['payload'] = payload;
            await store.save(scope, c);
          }
        }
        try {
          c['state'] = 'syncing';
          await store.save(scope, c);
          notifyListeners();
          if (!authorized()) return;
          if (c['remote_id'] == null) {
            final result = await remote.create(
              account,
              c['kind'] as String,
              c['id'] as String,
              payload,
            );
            final code = result['code'];
            if (result['id'] is! String ||
                (result['id'] as String).isEmpty ||
                (c['kind'] == 'patient' &&
                    (!result.containsKey('code') ||
                        (code != null && (code is! String || code.isEmpty))))) {
              throw const FormatException(
                'El servidor no confirmó el registro y su código.',
              );
            }
            c['remote_id'] = result['id'];
            c['code'] = code;
            await store.save(scope, c);
          }
          for (final raw in c['photos'] as List) {
            final photo = raw as Capture;
            if (photo['linked'] == true) continue;
            for (var attempt = 0; attempt < 2; attempt++) {
              if (!authorized()) return;
              if (photo['uploaded'] != true) {
                final bytes = await store.attachment(
                  scope,
                  photo['id'] as String,
                );
                if (!authorized()) return;
                await remote.upload(
                  c['kind'] as String,
                  c['remote_id'] as String,
                  photo,
                  bytes,
                );
                photo['uploaded'] = true;
                await store.save(scope, c);
              }
              if (!authorized()) return;
              try {
                await remote.link(
                  account,
                  c['kind'] as String,
                  c['remote_id'] as String,
                  photo,
                );
              } on PostgrestException catch (error) {
                if (error.code != 'P0801') rethrow;
                // Conserva el archivo y vuelve a subirlo si Storage lo perdió.
                photo['uploaded'] = false;
                await store.save(scope, c);
                if (attempt == 1) rethrow;
                continue;
              }
              photo['linked'] = true;
              await store.save(scope, c);
              break;
            }
          }
          c['state'] = 'synced';
          c.remove('message');
          await store.save(scope, c);
        } catch (error) {
          if (error is AuthException ||
              (error is PostgrestException &&
                  ['PGRST301', 'PGRST303', '28000'].contains(error.code)) ||
              (error is StorageException && error.statusCode == '401')) {
            _authenticationRequired = (account, generation);
            c['state'] = 'pending';
            c['message'] = 'Inicia sesión con esta misma cuenta para enviar.';
            await store.save(scope, c);
            return;
          }
          final permanent =
              error is StateError ||
              error is FormatException ||
              (error is PostgrestException &&
                  ((error.code?.startsWith('22') ?? false) ||
                      (error.code?.startsWith('23') ?? false) ||
                      ['42501', 'P0001', 'P0002'].contains(error.code))) ||
              (error is StorageException &&
                  ['400', '403', '413', '415'].contains(error.statusCode));
          c['state'] = permanent ? 'attention' : 'pending';
          c['message'] = permanent
              ? 'Revisa los datos, fotos y permisos con el administrador. La captura se conserva; no vuelvas a registrarla.'
              : 'El envío no se confirmó. Se volverá a intentar.';
          c['attempts'] = (c['attempts'] as int) + 1;
          c['next_attempt'] = now()
              .add(
                Duration(
                  seconds: min(
                    300,
                    5 * pow(2, min(c['attempts'] as int, 6)).toInt(),
                  ),
                ),
              )
              .toIso8601String();
          await store.save(scope, c);
        }
        notifyListeners();
      }
    } catch (_) {
      storageError =
          'No se pudo actualizar el almacenamiento local. Libera espacio y reintenta; tus capturas se conservan.';
    }
  }
}
