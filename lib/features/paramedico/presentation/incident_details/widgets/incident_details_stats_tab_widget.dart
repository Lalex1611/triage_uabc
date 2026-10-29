import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_card_data.dart';

class IncidentDetailsStatsTab extends StatelessWidget {
  final List<PatientCardData> patients;

  const IncidentDetailsStatsTab({super.key, required this.patients});

  @override
  Widget build(BuildContext context) {
    //Filtrado por categoría de Triaje usando TriageCategory
    final inmediatos = patients
        .where((p) => _matchesTriage(p.triageCategory, ['rojo', 'inmediato']))
        .length;
    final urgentes = patients
        .where((p) => _matchesTriage(p.triageCategory, ['amarillo', 'urgente']))
        .length;
    final leves = patients
        .where((p) => _matchesTriage(p.triageCategory, ['verde', 'leve']))
        .length;
    final fallecidos = patients
        .where((p) => _matchesTriage(p.triageCategory, ['negro', 'fallecido']))
        .length;

    //Avance de traslado accediendo directamente a PatientStatus
    final registrados = patients.length;
    final enEspera = patients
        .where((p) => p.status == PatientStatus.enEspera)
        .length;
    final trasladando = patients
        .where((p) => p.status == PatientStatus.trasladando)
        .length;
    final recibidosHospital = patients
        .where(
          (p) =>
              p.status == PatientStatus.recibido ||
              p.status == PatientStatus.recibido,
        )
        .length;
    final alta = patients.where((p) => p.status == PatientStatus.alta).length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Métrica de Triage
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildTriageCard(
                count: inmediatos,
                label: 'Inmediatos',
                color: const Color(0xFFDC2626),
                backgroundColor: const Color(0xFFFEE2E2),
              ),
              _buildTriageCard(
                count: urgentes,
                label: 'Urgentes',
                color: const Color(0xFFD97706),
                backgroundColor: const Color(0xFFFEF3C7),
              ),
              _buildTriageCard(
                count: leves,
                label: 'Leves',
                color: const Color(0xFF16A34A),
                backgroundColor: const Color(0xFFDCFCE7),
              ),
              _buildTriageCard(
                count: fallecidos,
                label: 'Fallecidos',
                color: const Color(0xFF111827),
                backgroundColor: const Color(0xFFF3F4F6),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Avance de traslado
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avance del traslado',
                  style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                    fontSize: 15,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                _buildProgressRow('Registrados', registrados),
                _buildProgressRow('En espera', enEspera),
                _buildProgressRow('Trasladando', trasladando),
                _buildProgressRow('Recibidos en hospital', recibidosHospital),
                _buildProgressRow('Alta', alta, isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Compara la categoría de triaje de forma segura sin importar si es Enum o Clase
  bool _matchesTriage(TriageCategory category, List<String> keywords) {
    final catName = category.toString().toLowerCase();
    return keywords.any((kw) => catName.contains(kw));
  }

  Widget _buildTriageCard({
    required int count,
    required String label,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
              fontSize: 28,
              color: color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              fontSize: 12,
              color: const Color(0xFF374151),
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
                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                ),
              ),
              Text(
                '$count',
                style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFF3F4F6)),
      ],
    );
  }
}
