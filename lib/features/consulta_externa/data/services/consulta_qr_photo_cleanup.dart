import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ConsultaQrPhotoCleanupException implements Exception {
  const ConsultaQrPhotoCleanupException();
}

/// Limpia solo la copia seleccionada que image_picker crea en Android/iOS.
/// En escritorio el selector puede devolver el original: nunca se elimina.
class ConsultaQrPhotoCleanup {
  ConsultaQrPhotoCleanup({
    TargetPlatform? platform,
    Future<Directory> Function()? cacheDirectory,
    Directory Function()? systemTemporaryDirectory,
  }) : _platform = platform ?? defaultTargetPlatform,
       _cacheDirectory = cacheDirectory ?? getTemporaryDirectory,
       _systemTemporaryDirectory =
           systemTemporaryDirectory ?? (() => Directory.systemTemp);

  final TargetPlatform _platform;
  final Future<Directory> Function() _cacheDirectory;
  final Directory Function() _systemTemporaryDirectory;
  static final _pickerDirectory = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  Future<void> deleteTemporaryPhoto(String selectedPath) async {
    if (kIsWeb ||
        (_platform != TargetPlatform.android &&
            _platform != TargetPlatform.iOS)) {
      return;
    }
    final file = File(selectedPath);
    final android = _platform == TargetPlatform.android;
    // Formatos de ruta comprobados en las versiones instaladas del selector.
    if (android
        ? !_pickerDirectory.hasMatch(p.basename(file.parent.path))
        : !p.basename(file.path).startsWith('image_picker_')) {
      return;
    }
    try {
      if (await FileSystemEntity.type(file.path, followLinks: false) !=
          FileSystemEntityType.file) {
        return;
      }
      if (await FileSystemEntity.type(file.parent.path, followLinks: false) ==
          FileSystemEntityType.link) {
        return;
      }
      final root = android
          ? await _cacheDirectory()
          : _systemTemporaryDirectory();
      final rootPath = await root.resolveSymbolicLinks();
      final filePath = await file.resolveSymbolicLinks();
      final parentPath = p.dirname(filePath);
      if (!p.isWithin(rootPath, filePath) ||
          !p.equals(android ? p.dirname(parentPath) : parentPath, rootPath)) {
        return;
      }
      await File(filePath).delete();
      if (android) {
        try {
          // Solo elimina el directorio UUID si está vacío; nunca recursivamente.
          await Directory(parentPath).delete();
        } on FileSystemException {
          // Otros archivos del selector, si los hay, se conservan.
        }
      }
    } catch (_) {
      throw const ConsultaQrPhotoCleanupException();
    }
  }
}
