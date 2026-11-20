import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Evento del historial ya formateado: hora, descripción y quién lo hizo
class MedicoRoomHistoryItem {
  final String time;
  final String event;
  final String? actor;

  const MedicoRoomHistoryItem({
    required this.time,
    required this.event,
    this.actor,
  });
}

/// "Fotografías e historial" (mockup 06): fila de fotos con botón "Añadir" y
/// los últimos cambios de estado / triage del paciente
class MedicoRoomPhotosHistory extends StatelessWidget {
  const MedicoRoomPhotosHistory({
    super.key,
    required this.photos,
    required this.history,
    this.onAddTap,
  });

  /// Rutas locales o enlaces http(s)
  final List<String> photos;
  final List<MedicoRoomHistoryItem> history;

  /// Null oculta "Añadir" (p. ej. paciente ya dado de alta)
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E7ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Fotografías e historial',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (onAddTap != null)
                TextButton(
                  onPressed: onAddTap,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1C69AA),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    textStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Añadir'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (photos.isEmpty && onAddTap == null)
            const Text(
              'Sin fotografías.',
              style: TextStyle(fontSize: 13, color: Color(0xFF8A949E)),
            )
          else
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in photos) ...[
                    _photo(context, p),
                    const SizedBox(width: 10),
                  ],
                  if (onAddTap != null) _addTile(),
                ],
              ),
            ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Historial',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5C6670),
              ),
            ),
            const SizedBox(height: 4),
            for (final h in history) _historyRow(h),
          ],
        ],
      ),
    );
  }

  static bool _isRemote(String p) =>
      p.startsWith('http://') || p.startsWith('https://');

  Widget _image(String p, BoxFit fit) {
    Widget broken(BuildContext _, Object _, StackTrace? _) =>
        const Icon(Icons.image_not_supported_outlined, color: Colors.white);
    if (_isRemote(p) || kIsWeb) {
      return Image.network(p, fit: fit, errorBuilder: broken);
    }
    return Image.file(File(p), fit: fit, errorBuilder: broken);
  }

  Widget _photo(BuildContext context, String p) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              InteractiveViewer(
                child: Center(child: _image(p, BoxFit.contain)),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Cerrar',
                ),
              ),
            ],
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 90,
          height: 90,
          color: const Color(0xFFB8C2CC),
          child: _image(p, BoxFit.cover),
        ),
      ),
    );
  }

  Widget _addTile() {
    return Material(
      color: const Color(0xFFF1F4F7),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onAddTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD3DBE3)),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_camera_outlined,
                color: Color(0xFF5C6670),
                size: 22,
              ),
              SizedBox(height: 4),
              Text(
                'Añadir',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF5C6670)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyRow(MedicoRoomHistoryItem h) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              h.time,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5C6670),
              ),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: h.event,
                children: [
                  if (h.actor != null)
                    TextSpan(
                      text: ' · ${h.actor}',
                      style: const TextStyle(color: Color(0xFF8A949E)),
                    ),
                ],
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
            ),
          ),
        ],
      ),
    );
  }
}
