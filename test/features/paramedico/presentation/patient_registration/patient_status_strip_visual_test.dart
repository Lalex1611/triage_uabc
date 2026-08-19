import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_status_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_status_strip_widget.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PatientStatusStripVisualTest(),
    ),
  );
}

class PatientStatusStripVisualTest extends StatefulWidget {
  const PatientStatusStripVisualTest({super.key});

  @override
  State<PatientStatusStripVisualTest> createState() => _PatientStatusStripVisualTestState();
}

class _PatientStatusStripVisualTestState extends State<PatientStatusStripVisualTest> {
  PatientStatus _currentStatus = PatientStatus.enEspera;
  bool _canEdit = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Patient Status Strip Test'),
        actions: [
          Row(
            children: [
              const Text('Can Edit:', style: TextStyle(color: Colors.black, fontSize: 12)),
              Switch(
                value: _canEdit,
                onChanged: (v) => setState(() => _canEdit = v),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Visual Sandbox: PatientStatusStripWidget', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            
            // EL WIDGET A PROBAR
            PatientStatusStripWidget(
              data: PatientStatusData(
                creatorName: 'Carlos Huerta',
                timeElapsed: '28 minutos',
                currentStatus: _currentStatus,
                canEdit: _canEdit,
                onStatusChanged: (newStatus) {
                  setState(() {
                    _currentStatus = newStatus;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 100),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Instrucciones: Toca el chip amarillo para abrir el menú de estatus. Cambia el switch de "Can Edit" para ver cómo se bloquea la interacción.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
