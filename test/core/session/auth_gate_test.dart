import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/session/auth_gate.dart';
import 'package:sistema_triage/features/auth/domain/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _TestStorage extends GotrueAsyncStorage {
  const _TestStorage();

  @override
  Future<String?> getItem({required String key}) async => null;

  @override
  Future<void> setItem({required String key, required String value}) async {}

  @override
  Future<void> removeItem({required String key}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final gate = AuthGate.instance;
  final profiles = <FutureOr<Map<String, Object?>> Function()>[];
  const account = 'f0000000-0000-0000-0000-000000000001';

  Map<String, Object?> profile(
    String name, {
    String role = 'paramedico',
    bool active = true,
  }) => {'role': role, 'full_name': name, 'is_active': active};

  setUpAll(() async {
    const url = 'https://example.test';
    const key = 'clave-ficticia-de-prueba';
    SupabaseEnv.applyRuntimeFallback(url: url, anonKey: key);
    String segment(Object data) =>
        base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
    final expiry = DateTime.now().add(const Duration(hours: 1));
    final jwt =
        '${segment({'alg': 'HS256'})}.'
        '${segment({'exp': expiry.millisecondsSinceEpoch ~/ 1000})}.c2ln';
    final client = MockClient((request) async {
      http.Response respond(Object data) => http.Response(
        jsonEncode(data),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
      switch (request.url.path) {
        case '/auth/v1/token':
          return respond({
            'access_token': jwt,
            'refresh_token': 'sesion-ficticia',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': account,
              'aud': 'authenticated',
              'app_metadata': {},
              'user_metadata': {},
              'created_at': '2026-11-25T12:00:00Z',
            },
          });
        case '/auth/v1/logout':
          return http.Response('', 204, request: request);
        case '/rest/v1/profiles':
          return respond([await profiles.removeAt(0)()]);
      }
      fail('Solicitud inesperada en la prueba: ${request.url.path}');
    });
    await Supabase.initialize(
      url: url,
      anonKey: key,
      httpClient: client,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
        pkceAsyncStorage: _TestStorage(),
      ),
      debug: false,
    );
  });

  setUp(() async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: 'ficticio@example.test',
      password: 'contraseña-ficticia',
    );
  });

  tearDownAll(() => Supabase.instance.dispose());

  test('el perfil tardío no reemplaza una respuesta más reciente', () async {
    profiles.add(() => profile('Inicial'));
    await gate.syncFromSession();
    expect(gate.role, AppUserRole.paramedico);
    final generation = gate.sessionGeneration;

    final oldProfile = Completer<Map<String, Object?>>();
    final newProfile = Completer<Map<String, Object?>>();
    profiles.addAll([() => oldProfile.future, () => newProfile.future]);
    final first = gate.syncFromSession();
    final second = gate.syncFromSession();
    newProfile.complete(profile('Reciente'));
    await second;
    oldProfile.complete(profile('Atrasado'));
    await first;

    expect(gate.sessionGeneration, generation);
    expect(gate.fullName, 'Reciente');
  });

  test(
    'un perfil de Consulta Externa inactivo cierra la sesión de personal',
    () async {
      profiles.add(
        () => profile(
          'Consulta Externa',
          role: 'consulta_externa',
          active: false,
        ),
      );
      await gate.syncFromSession();
      expect(gate.takeConsultaExternaStaffBlock(), isTrue);
      expect(gate.role, isNull);
      expect(Supabase.instance.client.auth.currentSession, isNull);
    },
  );
}
