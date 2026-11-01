import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_card_data.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

class PatientCard extends StatelessWidget {
  final PatientCardData data;

  const PatientCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final displayName = data.name.trim().isNotEmpty
        ? data.name
        : 'Paciente sin nombre';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: TriageColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TriageColors.borderSubtle, width: 1),
        boxShadow: TriageShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: data.onCardTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Píldora delgada con color dinámico de TriageLevel
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: data.triageLevel.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Contenido principal de la tarjeta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /* FILA 1: Nombre del paciente, Fecha y Editar */
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TriageTextStyles.labelLarge.copyWith(
                                  color: TriageColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              data.dateStr,
                              style: TriageTextStyles.bodySmall.copyWith(
                                color: TriageColors.textSecondary,
                              ),
                            ),
                            if (data.onEditTap != null) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: data.onEditTap,
                                child: const TriageIcon(
                                  TriageIcons.pencil,
                                  size: 15,
                                  color: TriageColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 6),

                        /* FILA 2: ID del Paciente (PAC-XXXX), Ver mapa y Flecha */
                        Row(
                          children: [
                            const TriageIcon(
                              TriageIcons.user,
                              size: 14,
                              color: TriageColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              data.id.isNotEmpty ? data.id : 'Sin código',
                              style: TriageTextStyles.bodyMedium.copyWith(
                                color: TriageColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (data.onMapTap != null)
                              GestureDetector(
                                onTap: data.onMapTap,
                                child: Text(
                                  'Ver mapa',
                                  style: TriageTextStyles.labelSmall.copyWith(
                                    color: TriageColors.textPrimary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            const TriageIcon(
                              TriageIcons.chevronRight,
                              size: 18,
                              color: TriageColors.textTertiary,
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        /* FILA 3: Insignia de estado con PatientLifecycleStatus */
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Estado:',
                              style: TriageTextStyles.bodySmall.copyWith(
                                color: TriageColors.textSecondary,
                              ),
                            ),
                            _buildStatusBadge(data.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(PatientLifecycleStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TriageTextStyles.labelSmall.copyWith(
              color: status.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
