// Sandbox visual de TriageStatusBadge: flutter run -t test/shared/widgets/triage_status_badge_visual_test.dart
import 'package:flutter/material.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: TriageColors.canvas,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Estados del paciente', style: TriageTextStyles.labelSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in PatientLifecycleStatus.values)
                    TriageStatusBadge.patient(status),
                  const TriageStatusBadge.rejected(),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Etiqueta larga en 140 px',
                style: TriageTextStyles.labelSmall,
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 140,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TriageStatusBadge(
                      label: 'Esperando confirmación del hospital',
                      dotColor: TriageColors.warning,
                      textColor: TriageColors.warningText,
                      background: TriageColors.warningBackground,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
