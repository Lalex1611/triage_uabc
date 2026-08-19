// Test visual aislado del dropdown de estatus del paciente (médico).
//
// Run:
// flutter run -t test/features/medico/presentation/register_patient/widgets/medico_register_status_dropdown_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_status.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_status_data.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_status_dropdown_widget.dart';

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
  MedicoPatientStatus _status = MedicoPatientStatus.recibido;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MedicoRegisterStatusDropdownWidget(
                data: MedicoRegisterStatusData(
                  currentStatus: _status,
                  onStatusChanged: (s) => setState(() => _status = s),
                ),
              ),
              const SizedBox(height: 24),
              Text('Estado actual: ${_status.label}'),
            ],
          ),
        ),
      ),
    );
  }
}
