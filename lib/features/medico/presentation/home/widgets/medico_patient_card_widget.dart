import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_patient_card_data.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/shared/widgets/triage_pressable_widget.dart';

/// Tarjeta de paciente en Home Entradas (mockup 01)
class MedicoPatientCard extends StatelessWidget {
  final MedicoPatientCardData data;
  final bool panelOnly;

  const MedicoPatientCard({
    super.key,
    required this.data,
    this.panelOnly = false,
  });

  Color _badgeColor(TriageCategory c) {
    switch (c) {
      case TriageCategory.rojo:
        return const Color(0xFFB6070A);
      case TriageCategory.naranja:
        return const Color(0xFFF39223);
      case TriageCategory.amarillo:
        return const Color(0xFFF5C518);
      case TriageCategory.verde:
        return const Color(0xFF2FA835);
      case TriageCategory.azul:
        return const Color(0xFF1D71B8);
      default:
        return c.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inner = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Acento de color (abarca nombre + identificadores) + badge de triage
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _badgeColor(data.triageCategory),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              data.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.ESC_Bold_titleLarge.copyWith(
                                fontSize: 15,
                                color: Colors.black,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _badgeColor(data.triageCategory),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              data.triageCategory.label,
                              style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data.id} · ${data.ambulanceUnit}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Fila 3: unidad / tiempo de llegada (chip)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1D71B8).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    AppIcons.medicoHomeAmbulance,
                    width: 14,
                    height: 14,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF1D71B8),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${data.ambulanceUnit.replaceFirst('Unidad: ', 'Unidad ')} · llega en ${data.eta.replaceFirst('A ', '').replaceAll('…', ' min')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF1D71B8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (panelOnly) return inner;

    return TriagePressable(
      onTap: data.onCardTap,
      builder: (context, pressed) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13.2),
          boxShadow: triagePressedShadow(pressed: pressed),
        ),
        child: inner,
      ),
    );
  }
}
