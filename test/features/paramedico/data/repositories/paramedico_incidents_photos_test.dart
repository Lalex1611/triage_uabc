import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bucket = '/storage/v1/object/incident_photos';

ParamedicoIncidentsRepository _repo(List<http.Request> requests) {
  final client = MockClient((request) async {
    requests.add(request);
    return http.Response(
      request.url.path.contains('/sign/')
          ? jsonEncode([
              {'path': 'inc/a.jpg', 'signedURL': '/object/sign/a?token=t'},
            ])
          : request.method == 'DELETE'
          ? '[]'
          : jsonEncode({'Key': 'k', 'Id': 'i'}),
      200,
      headers: {'content-type': 'application/json'},
    );
  });
  return ParamedicoIncidentsRepository(
    client: SupabaseClient(
      'https://x.test',
      'key',
      httpClient: client,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    ),
  );
}

void main() {
  test('sube dentro de la carpeta del incidente y devuelve la ruta', () async {
    final dir = Directory.systemTemp.createTempSync('b9');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/foto.JPG')..writeAsBytesSync([1, 2, 3]);
    final requests = <http.Request>[];

    final path = await _repo(
      requests,
    ).uploadIncidentPhoto(incidentId: 'inc', localPath: file.path);

    expect(path, matches(RegExp(r'^inc/[0-9a-f-]{36}\.jpg$')));
    expect(requests.single.url.path, '$_bucket/$path');
    expect(requests.single.method, 'POST');
  });

  test('firma solo las fotos que están en Storage', () async {
    final requests = <http.Request>[];

    final urls = await _repo(
      requests,
    ).signIncidentPhotos(const ['inc/a.jpg', '/data/antigua.jpg']);

    expect(urls.keys, ['inc/a.jpg']);
    expect(urls['inc/a.jpg'], contains('/object/sign/a?token=t'));
    expect(jsonDecode(requests.single.body)['paths'], ['inc/a.jpg']);
  });

  test('sin fotos en Storage no consulta nada', () async {
    final requests = <http.Request>[];
    expect(await _repo(requests).signIncidentPhotos(const ['/a.jpg']), isEmpty);
    expect(requests, isEmpty);
  });

  test('borra de Storage, pero nunca una ruta local', () async {
    final requests = <http.Request>[];
    final repo = _repo(requests);

    await repo.deleteIncidentPhoto('/data/antigua.jpg');
    expect(requests, isEmpty);

    await repo.deleteIncidentPhoto('inc/a.jpg');
    expect(requests.single.method, 'DELETE');
    expect(jsonDecode(requests.single.body)['prefixes'], ['inc/a.jpg']);
  });
}
