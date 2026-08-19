// Test visual aislado del área de captura de fotos.
//
// Run:
// flutter run -t test/features/paramedico/presentation/start_triage/widgets/photo_capture_area_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/photo_capture_area_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/photo_capture_area_widget.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _Demo(),
  ));
}

class _Demo extends StatefulWidget {
  const _Demo();

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  final List<String> _photos = [];

  void _addMockPhoto() {
    setState(() {
      _photos.add('mock_path_\${_photos.length}');
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Text('Estado Vacío:'),
              const SizedBox(height: 10),
              PhotoCaptureAreaWidget(
                data: PhotoCaptureAreaData(
                  photos: const [],
                  onAddPhotoTap: () => debugPrint('Add Photo (empty) tapped'),
                  onRemovePhotoTap: (idx) {},
                ),
              ),
              const SizedBox(height: 40),
              const Text('Con Fotos:'),
              const SizedBox(height: 10),
              PhotoCaptureAreaWidget(
                data: PhotoCaptureAreaData(
                  photos: _photos.isEmpty ? ['mock_path_0'] : _photos,
                  onAddPhotoTap: _addMockPhoto,
                  onRemovePhotoTap: _removePhoto,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _addMockPhoto,
                child: const Text('Simular añadir foto'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
