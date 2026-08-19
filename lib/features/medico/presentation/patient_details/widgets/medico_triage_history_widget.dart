import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_category.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_details/medico_triage_history_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_details/patient_triage_history_entry.dart';

// Este widget muestra la línea de tiempo del historial de cambios de triage y estado de un paciente

class MedicoTriageHistoryWidget extends StatelessWidget {
  const MedicoTriageHistoryWidget({
    super.key,
    required this.data,
  });

  final MedicoTriageHistoryData data;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 20, color: Colors.black87),
              const SizedBox(width: 8),
              Text(
                'Historial de Triage y Estado',
                style: AppTextStyles.ESC_Bold_titleLarge.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (data.isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (entries.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'No hay registros en el historial de cambios.',
                style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _TriageHistoryCard(entry: entries[index]);
              },
            ),
        ],
      ),
    );
  }
}

class _TriageHistoryCard extends StatelessWidget {
  const _TriageHistoryCard({required this.entry});

  final PatientTriageHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.newTriageColor.color;
    final dtStr = _formatDateTime(entry.changedAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Indicador de color del triage actual
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Fecha y hora del registro
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            dtStr,
                            style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                              color: Colors.black87,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      // Rol que registro el cambio
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryParamedico.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entry.actorRoleLabel,
                          style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                            color: AppColors.primaryParamedico,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTriageChangeRow(entry),
                  if (entry.changedFields.contains('status')) ...[
                    const SizedBox(height: 4),
                    _buildStatusChangeRow(entry),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTriageChangeRow(PatientTriageHistoryEntry entry) {
    final oldCat = entry.oldTriageColor;
    final newCat = entry.newTriageColor;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        Text(
          'Triage:',
          style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
        if (oldCat != null && oldCat != newCat) ...[
          _TriagePill(category: oldCat),
          Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey.shade500),
        ],
        _TriagePill(category: newCat),
      ],
    );
  }

  Widget _buildStatusChangeRow(PatientTriageHistoryEntry entry) {
    final oldSt = _readableStatus(entry.oldStatus);
    final newSt = _readableStatus(entry.newStatus);

    return Row(
      children: [
        Text(
          'Estado: ',
          style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
        if (oldSt.isNotEmpty) ...[
          Text(
            oldSt,
            style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
              color: Colors.grey.shade600,
              fontSize: 12,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.grey.shade500),
          const SizedBox(width: 4),
        ],
        Text(
          newSt,
          style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
            color: Colors.black87,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  static String _readableStatus(String? status) {
    if (status == null) return '';
    switch (status.toLowerCase()) {
      case 'registrado':
        return 'Registrado';
      case 'en_espera':
        return 'En espera';
      case 'trasladando':
        return 'En traslado';
      case 'recibido':
        return 'Recibido';
      case 'alta_medica':
        return 'Alta Médica';
      default:
        return status;
    }
  }

  static String _formatDateTime(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year;
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min:$ss';
  }
}

class _TriagePill extends StatelessWidget {
  const _TriagePill({required this.category});

  final MedicoTriageCategory category;

  @override
  Widget build(BuildContext context) {
    final isWhiteText = category == MedicoTriageCategory.rojo ||
        category == MedicoTriageCategory.azul ||
        category == MedicoTriageCategory.naranja;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: category.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category.code.toUpperCase(),
        style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
          color: isWhiteText ? Colors.white : Colors.black87,
          fontSize: 11,
        ),
      ),
    );
  }
}
