// Test visual aislado del widget de captura de fotografía del paciente (médico).
//
// Run:
// flutter run -t test/features/medico/presentation/register_patient/widgets/medico_register_photo_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_photo_data.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_photo_widget.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _Demo(),
  ));
}

class _Demo extends StatelessWidget {
  const _Demo();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: MedicoRegisterPhotoWidget(
            data: MedicoRegisterPhotoData(
              photos: const [],
              onCameraTap: () => debugPrint('camera'),
              onAddImageTap: () => debugPrint('add'),
              onRemovePhotoTap: (i) => debugPrint('remove $i'),
            ),
          ),
        ),
      ),
    );
  }
}
