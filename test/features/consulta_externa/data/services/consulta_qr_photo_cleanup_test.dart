import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sistema_triage/features/consulta_externa/data/services/consulta_qr_photo_cleanup.dart';

void main() {
  const uuid = '11111111-2222-4333-8444-555555555555';
  late Directory root;
  late Directory cache;
  late Directory temporary;
  late Directory base;

  setUp(() async {
    base = await Directory(
      'build/consulta_photo_cleanup_tests',
    ).absolute.create(recursive: true);
    root = await base.createTemp('case-');
    cache = await Directory(p.join(root.path, 'cache')).create();
    temporary = await Directory(p.join(root.path, 'tmp')).create();
  });
  tearDown(() async {
    final basePath = await base.resolveSymbolicLinks();
    final rootPath = await root.resolveSymbolicLinks();
    if (!p.isWithin(basePath, rootPath)) {
      throw StateError('Limpieza fuera de la carpeta de pruebas');
    }
    await Directory(rootPath).delete(recursive: true);
  });

  ConsultaQrPhotoCleanup cleanup(TargetPlatform platform) =>
      ConsultaQrPhotoCleanup(
        platform: platform,
        cacheDirectory: () async => cache,
        systemTemporaryDirectory: () => temporary,
      );

  Future<File> photo(String path) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    return file.writeAsString('imagen ficticia');
  }

  test(
    'Android elimina la copia seleccionada y el directorio UUID vacío',
    () async {
      final file = await photo(p.join(cache.path, uuid, 'QR.png'));
      await cleanup(TargetPlatform.android).deleteTemporaryPhoto(file.path);
      expect(await file.exists(), isFalse);
      expect(await file.parent.exists(), isFalse);
    },
  );

  test('Android conserva otros archivos del mismo directorio', () async {
    final file = await photo(p.join(cache.path, uuid, 'QR.png'));
    final other = await photo(p.join(file.parent.path, 'otra.png'));
    await cleanup(TargetPlatform.android).deleteTemporaryPhoto(file.path);
    expect(await file.exists(), isFalse);
    expect(await other.exists(), isTrue);
  });

  test(
    'Android conserva un original fuera de la caché aunque la carpeta sea UUID',
    () async {
      final file = await photo(p.join(root.path, 'galeria', uuid, 'QR.png'));
      await cleanup(TargetPlatform.android).deleteTemporaryPhoto(file.path);
      expect(await file.exists(), isTrue);
    },
  );

  test('Android no borra archivos de caché ajenos al selector', () async {
    for (final path in [
      p.join(cache.path, 'original.png'),
      p.join(cache.path, 'fotos_paciente', 'QR.png'),
    ]) {
      final file = await photo(path);
      await cleanup(TargetPlatform.android).deleteTemporaryPhoto(file.path);
      expect(await file.exists(), isTrue);
    }
  });

  test('Una ruta con recorrido fuera de caché conserva el archivo', () async {
    final file = await photo(p.join(root.path, uuid, 'QR.png'));
    final path = p.join(cache.path, '..', uuid, 'QR.png');
    await cleanup(TargetPlatform.android).deleteTemporaryPhoto(path);
    expect(await file.exists(), isTrue);
  });

  test(
    'iOS elimina solo el archivo del selector dentro de temporales',
    () async {
      final file = await photo(
        p.join(temporary.path, 'image_picker_identificador.png'),
      );
      final other = await photo(p.join(temporary.path, 'otra.png'));
      await cleanup(TargetPlatform.iOS).deleteTemporaryPhoto(file.path);
      expect(await file.exists(), isFalse);
      expect(await other.exists(), isTrue);
      expect(await temporary.exists(), isTrue);
    },
  );

  test(
    'iOS conserva archivos fuera de temporales o sin el prefijo del selector',
    () async {
      for (final path in [
        p.join(cache.path, 'image_picker_original.png'),
        p.join(temporary.path, 'original.png'),
      ]) {
        final file = await photo(path);
        await cleanup(TargetPlatform.iOS).deleteTemporaryPhoto(path);
        expect(await file.exists(), isTrue);
      }
    },
  );

  test(
    'macOS conserva el original seleccionado incluso si coincide con el patrón',
    () async {
      final file = await photo(
        p.join(temporary.path, 'image_picker_original.png'),
      );
      await cleanup(TargetPlatform.macOS).deleteTemporaryPhoto(file.path);
      expect(await file.exists(), isTrue);
    },
  );

  test('Un archivo ya eliminado no impide continuar', () async {
    await cleanup(
      TargetPlatform.android,
    ).deleteTemporaryPhoto(p.join(cache.path, uuid, 'QR.png'));
  });

  test(
    'Una carpeta no se interpreta como archivo ni se borra recursivamente',
    () async {
      final file = await photo(
        p.join(cache.path, uuid, 'QR.png', 'conservar.txt'),
      );
      await cleanup(
        TargetPlatform.android,
      ).deleteTemporaryPhoto(file.parent.path);
      expect(await file.exists(), isTrue);
    },
  );

  test(
    'Un error al comprobar la caché se comunica y conserva el archivo',
    () async {
      final file = await photo(p.join(cache.path, uuid, 'QR.png'));
      final service = ConsultaQrPhotoCleanup(
        platform: TargetPlatform.android,
        cacheDirectory: () async =>
            throw const FileSystemException('Caché no disponible'),
      );
      await expectLater(
        service.deleteTemporaryPhoto(file.path),
        throwsA(isA<ConsultaQrPhotoCleanupException>()),
      );
      expect(await file.exists(), isTrue);
    },
  );

  test(
    'Un enlace simbólico no permite borrar el original',
    () async {
      final original = await photo(p.join(root.path, 'original.png'));
      final parent = await Directory(p.join(cache.path, uuid)).create();
      final link = await Link(
        p.join(parent.path, 'QR.png'),
      ).create(original.path);
      await cleanup(TargetPlatform.android).deleteTemporaryPhoto(link.path);
      expect(await original.exists(), isTrue);
      expect(await link.exists(), isTrue);
    },
    skip: Platform.isWindows
        ? 'Crear enlaces en Windows requiere privilegios adicionales'
        : false,
  );
}
