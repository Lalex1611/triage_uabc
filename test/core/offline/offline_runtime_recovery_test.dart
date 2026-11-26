import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/connectivity/app_connectivity_notifier.dart';
import 'package:sistema_triage/core/offline/offline_capture_store.dart';
import 'package:sistema_triage/core/session/auth_gate.dart';
import 'package:sistema_triage/features/medico/data/offline/medico_offline_runtime.dart';
import 'package:sistema_triage/features/paramedico/data/offline/paramedico_offline_runtime.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _PkceStorage extends Fake implements GotrueAsyncStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const storage = MethodChannel('triage/offline_storage');
  const network = MethodChannel('dev.fluttercommunity.plus/connectivity');
  final paramedico = ParamedicoOfflineRuntime.instance;
  final medico = MedicoOfflineRuntime.instance;
  var role = 'medico';
  var incidentRequests = 0;
  Directory? protectedDirectory;
  const account = 'f0000000-0000-0000-0000-000000000001';
  const incident = 'f0000000-0000-0000-0000-000000000002';

  setUpAll(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    const url = 'https://example.test';
    const key = 'anonima-de-prueba';
    SupabaseEnv.applyRuntimeFallback(url: url, anonKey: key);
    final supabase = await Supabase.initialize(
      url: url,
      anonKey: key,
      debug: false,
      authOptions: FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        pkceAsyncStorage: _PkceStorage(),
        localStorage: const EmptyLocalStorage(),
      ),
      httpClient: MockClient((request) async {
        final row = switch (request.url.path) {
          '/rest/v1/profiles' => {
            'role': role,
            'is_active': true,
            'hospital_id': 'hospital',
          },
          '/rest/v1/incidents' => {
            'id': incident,
            'generated_title': 'Incidente de prueba',
          },
          _ => fail('Solicitud inesperada: ${request.url.path}'),
        };
        if (request.url.path.endsWith('/incidents')) incidentRequests++;
        return http.Response(
          jsonEncode([row]),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    final expires =
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
        1000;
    final claims = base64Url
        .encode(utf8.encode(jsonEncode({'exp': expires})))
        .replaceAll('=', '');
    await supabase.client.auth.recoverSession(
      jsonEncode({
        'access_token': 'eyJhbGciOiJIUzI1NiJ9.$claims.c2ln',
        'token_type': 'bearer',
        'user': {'id': account},
      }),
    );
  });

  tearDownAll(() async {
    paramedico.dispose();
    medico.dispose();
    await paramedico.store?.db.close();
    await protectedDirectory?.delete(recursive: true);
    debugDefaultTargetPlatformOverride = null;
    await Supabase.instance.dispose();
  });

  test(
    'ambos roles reabren el almacén después de una apertura fallida',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'triage_reapertura_',
      );
      protectedDirectory = directory;
      var attempts = 0;
      messenger.setMockMethodCallHandler(
        storage,
        (_) async => ++attempts == 1 ? null : directory.path,
      );
      messenger.setMockMethodCallHandler(network, (_) async => ['none']);
      await AppConnectivityNotifier.instance.refresh();
      role = 'medico';
      await AuthGate.instance.syncFromSession();
      await Future.wait([medico.start(), paramedico.start()]);
      expect(attempts, 1);
      expect(medico.error, contains('almacenamiento'));
      expect(paramedico.error, contains('almacenamiento'));

      await Future.wait([medico.retryNow(), paramedico.retryNow()]);
      expect(attempts, 2);
      expect(medico.error, isNull);
      expect(medico.canCapture, isTrue);
      role = 'paramedico';
      await AuthGate.instance.syncFromSession();
      expect(paramedico.error, isNull);
      expect(paramedico.canCapture, isTrue);
    },
  );

  test(
    'el detalle remoto tolera el fallo de caché y el registro lo rechaza',
    () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      final previous = paramedico.store;
      final key = await AesGcm.with256bits().newSecretKey();
      paramedico.store = OfflineCaptureStore(db, (_) async => key);
      addTearDown(() async {
        paramedico.store = previous;
        await db.close();
      });
      await OfflineCaptureStore.createSchema(
        db,
        OfflineCaptureStore.schemaVersion,
      );
      await db.execute('''
      CREATE TRIGGER rechazar_cache BEFORE INSERT ON incident_cache
      BEGIN SELECT RAISE(ABORT, 'Fallo de escritura simulado'); END
    ''');
      role = 'paramedico';
      await AuthGate.instance.syncFromSession();
      messenger.setMockMethodCallHandler(network, (_) async => ['wifi']);
      await http.runWithClient(
        AppConnectivityNotifier.instance.refresh,
        () => MockClient((_) async => http.Response('', 200)),
      );
      await paramedico.synchronize();
      final repository = ParamedicoIncidentsRepository();

      final detail = await repository.getIncident(incident);
      expect(detail?.generatedTitle, 'Incidente de prueba');
      await expectLater(
        repository.registerPatientFull(
          incidentId: incident,
          triageColor: 'verde',
          displayName: 'Paciente de prueba',
          demographics: {},
          locationLat: 32,
          locationLng: -115,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'mensaje',
            contains('guardar una copia'),
          ),
        ),
      );
      expect(incidentRequests, 2);
      expect(await db.query('incident_cache'), isEmpty);
      expect(await db.query('outbox'), isEmpty);
    },
  );
}
