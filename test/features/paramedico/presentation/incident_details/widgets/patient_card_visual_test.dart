import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_card_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/patient_card_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/*
  COMANDO PARA PROBAR:
  flutter run -t test/features/paramedico/presentation/incident_details/widgets/patient_card_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PatientCardVisualTest(),
    ),
  );
}

class PatientCardVisualTest extends StatefulWidget {
  const PatientCardVisualTest({super.key});

  @override
  State<PatientCardVisualTest> createState() => _PatientCardVisualTestState();
}

class _PatientCardVisualTestState extends State<PatientCardVisualTest> {
  void _showEditMock(BuildContext context, String currentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Editar Paciente',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Nombre o Alias'),
          controller: TextEditingController(text: currentName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F1F1),
        appBar: AppBar(
          title: const Text(
            'Ejemplos de PatientCard',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            PatientCard(
              data: PatientCardData(
                id: 'PAC-28320',
                number: 1,
                triageLevel: TriageLevel.red,
                name: 'Paciente Numero 1 - 12-Mar-2026 14:32 - Blvd. 2000',
                dateStr: '12/03/206 14:32:54',
                status: PatientLifecycleStatus.waiting,
                onEditTap: () => _showEditMock(
                  context,
                  'Paciente Numero 1 - 12-Mar-2026 14:32 - Blvd. 2000',
                ),
              ),
            ),
            const SizedBox(height: 16),
            PatientCard(
              data: PatientCardData(
                id: 'PAC-28321',
                number: 2,
                triageLevel: TriageLevel.yellow,
                name: 'Ramiro Hernández',
                dateStr: '12/03/206 14:32:54',
                status: PatientLifecycleStatus.waiting,
                onEditTap: () => _showEditMock(context, 'Ramiro Hernández'),
              ),
            ),
            const SizedBox(height: 16),
            PatientCard(
              data: PatientCardData(
                id: 'PAC-28325',
                number: 3,
                triageLevel: TriageLevel.yellow,
                name: 'Sebastián González Pérez',
                dateStr: '12/03/206 14:32:54',
                status: PatientLifecycleStatus.transferring,
                onEditTap: () =>
                    _showEditMock(context, 'Sebastián González Pérez'),
              ),
            ),
            const SizedBox(height: 16),
            PatientCard(
              data: PatientCardData(
                id: 'PAC-28329',
                number: 4,
                triageLevel: TriageLevel.green,
                name: 'Paciente Numero 4 - 12-Mar-2026 14:32 - Blvd. 2000',
                dateStr: '12/03/206 14:32:54',
                status: PatientLifecycleStatus.received,
                onEditTap: () => _showEditMock(context, 'Paciente Numero 4'),
              ),
            ),
            const SizedBox(height: 16),
            PatientCard(
              data: PatientCardData(
                id: 'PAC-28330',
                number: 5,
                triageLevel: TriageLevel.black,
                name: 'Paciente Numero 5 - 12-Mar-2026 14:32',
                dateStr: '12/03/206 14:32:54',
                status: PatientLifecycleStatus.discharged,
                onEditTap: () => _showEditMock(context, 'Paciente Numero 5'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
