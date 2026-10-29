import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_card_data.dart';
import 'package:sistema_triage/shared/widgets/patient_lifecycle_status_badge.dart';

// Tarjeta de paciente
class PatientCard extends StatelessWidget {
  final PatientCardData data;

  const PatientCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Si no hay nombre registrado, muestra 'Paciente sin nombre'
    final displayName = data.name.trim().isNotEmpty
        ? data.name
        : 'Paciente sin nombre';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                  // Línea de color del triaje fina y redondeada (Píldora)
                  Container(
                    width: 12,
                    decoration: BoxDecoration(
                      color: data.triageCategory.color,
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
                                style:
                                    AppTextStyles
                                        .ESC_SemiBold_bodyMedium.copyWith(
                                      fontSize: 14,
                                      color: const Color(0xFF111827),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              data.dateStr,
                              style:
                                  AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                                    fontSize: 11,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                            ),
                            if (data.onEditTap != null) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: data.onEditTap,
                                child: SvgPicture.asset(
                                  AppIcons.paramedicoIncidenteEdit,
                                  width: 15,
                                  height: 15,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF6B7280),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 6),

                        /* FILA 2: Código ID (PAC-4494), 'Ver mapa' y Flecha */
                        Row(
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              size: 14,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              data.id.isNotEmpty ? data.id : 'Sin código',
                              style:
                                  AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                                    fontSize: 12,
                                    color: const Color(0xFF4B5563),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            if (data.onMapTap != null) ...[
                              GestureDetector(
                                onTap: data.onMapTap,
                                child: Text(
                                  'Ver mapa',
                                  style:
                                      AppTextStyles
                                          .ESC_Bold_titleSmall.copyWith(
                                        fontSize: 11,
                                        color: const Color(0xFF111827),
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Color(0xFFD1D5DB),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        /* FILA 3: Estado del paciente */
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            PatientLifecycleStatusBadge(status: data.status),
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
}
