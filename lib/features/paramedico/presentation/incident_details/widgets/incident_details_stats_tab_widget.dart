import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_card_data.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

class IncidentDetailsStatsTab extends StatelessWidget {
  final List<PatientCardData> patients;

  const IncidentDetailsStatsTab({super.key, required this.patients});

  @override
  Widget build(BuildContext context) {
    // Conteo por TriageLevel
    final inmediatos = patients
        .where((p) => p.triageLevel == TriageLevel.red)
        .length;
    final urgentes = patients
        .where((p) => p.triageLevel == TriageLevel.yellow)
        .length;
    final leves = patients
        .where((p) => p.triageLevel == TriageLevel.green)
        .length;
    final fallecidos = patients
        .where((p) => p.triageLevel == TriageLevel.black)
        .length;

    // Avance de traslado por PatientLifecycleStatus
    final registrados = patients.length;
    final enEspera = patients
        .where((p) => p.status == PatientLifecycleStatus.waiting)
        .length;
    final trasladando = patients
        .where((p) => p.status == PatientLifecycleStatus.transferring)
        .length;
    final recibidosHospital = patients
        .where((p) => p.status == PatientLifecycleStatus.received)
        .length;
    final alta = patients
        .where((p) => p.status == PatientLifecycleStatus.discharged)
        .length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /* Cuadrícula de métricas usando TriageMetric.level */
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: [
              TriageMetric.level(
                TriageLevel.red,
                value: '$inmediatos',
                label: TriageLevel.red.label,
              ),
              TriageMetric.level(
                TriageLevel.yellow,
                value: '$urgentes',
                label: TriageLevel.yellow.label,
              ),
              TriageMetric.level(
                TriageLevel.green,
                value: '$leves',
                label: TriageLevel.green.label,
              ),
              TriageMetric.level(
                TriageLevel.black,
                value: '$fallecidos',
                label: TriageLevel.black.label,
              ),
            ],
          ),

          const SizedBox(height: 20),

          /* Tarjeta de avance de traslado */
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TriageColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TriageColors.borderSubtle, width: 1),
              boxShadow: TriageShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avance del traslado',
                  style: TriageTextStyles.labelLarge.copyWith(
                    color: TriageColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProgressRow('Registrados', registrados),
                _buildProgressRow(
                  PatientLifecycleStatus.waiting.label,
                  enEspera,
                ),
                _buildProgressRow(
                  PatientLifecycleStatus.transferring.label,
                  trasladando,
                ),
                _buildProgressRow(
                  PatientLifecycleStatus.received.label,
                  recibidosHospital,
                ),
                _buildProgressRow(
                  PatientLifecycleStatus.discharged.label,
                  alta,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String title, int count, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TriageTextStyles.bodyMedium.copyWith(
                  color: TriageColors.textSecondary,
                ),
              ),
              Text(
                '$count',
                style: TriageTextStyles.labelLarge.copyWith(
                  color: TriageColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            thickness: 1,
            color: TriageColors.borderSubtle,
          ),
      ],
    );
  }
}
