import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_patient_card_data.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_patient_card_widget.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

/*
  COMANDO PARA PROBAR: 
  flutter run -t test/features/medico/presentation/home/widgets/medico_patient_card_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MedicoPatientCardVisualTest(),
    ),
  );
}

class MedicoPatientCardVisualTest extends StatelessWidget {
  const MedicoPatientCardVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    final mockPatient = MedicoPatientCardData(
      id: 'PAC-28320',
      number: 1,
      triageCategory: TriageCategory.rojo,
      name: 'Paciente Numero 1 - 12-Mar-2026 14:32 - Blvd. 2000',
      dateStr: '12/03/206 14:32:54',
      coordinates: '19.4326, -99.1332',
      eta: 'A 10 Min...',
      ambulanceUnit: 'No. de Unidad: 156',
      status: PatientStatus.trasladando,
    );

    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'VISTA PREVIA DE TARJETA MÉDICO',
                  style: AppTextStyles.ESC_Bold_titleLarge,
                ),
                const SizedBox(height: 20),
                MedicoPatientCard(data: mockPatient),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
