// Test visual aislado del header (banner azul) de registro de paciente del médico.
//
// Run:
// flutter run -t test/features/medico/presentation/register_patient/widgets/medico_register_header_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_header_data.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_header_widget.dart';

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
        child: MedicoRegisterHeaderWidget(
          data: MedicoRegisterHeaderData(
            patientId: 'PAC-28321',
            patientName: '',
            registrationDateTime: '12/03/2026 14:32:54',
            onNameChanged: (v) => debugPrint('name: $v'),
            onEditNameTap: () => debugPrint('edit name'),
            onEditDateTap: () => debugPrint('edit date'),
            onGenerateQrTap: () => debugPrint('qr'),
          ),
        ),
      ),
    );
  }
}
