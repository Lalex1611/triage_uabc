import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_header_data.dart';
import 'package:sistema_triage/shared/widgets/triage_pressable_widget.dart';

/// Encabezado azul de la Sala (mockup 05): título, campana y conteo por nivel
class MedicoQueueHeaderWidget extends StatelessWidget {
  final MedicoQueueHeaderData data;

  const MedicoQueueHeaderWidget({super.key, required this.data});

  static const Color _background = Color(0xFF1C69AA);
  static const Color _tile = Color(0xFF3D7EB4);

  // Mismas medidas que el encabezado de Entrantes (MedicoHomeHeader +
  // MedicoMinidash) para que el bloque azul no cambie de tamaño al cambiar
  // de pestaña: 10 + 42 + 20 + 64 + 14 = 150 px.
  static const double _topRowHeight = 42;
  static const double _rowGap = 20;
  static const double _tileHeight = 64;

  @override
  Widget build(BuildContext context) {
    final count = data.patientsInCare;
    final title = count == 1
        ? '1 paciente en atención'
        : '$count pacientes en atención';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _topRowHeight,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SALA HOSPITALARIA',
                        style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.2,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.ESC_Bold_titleLarge.copyWith(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _bell(),
              ],
            ),
          ),
          const SizedBox(height: _rowGap),
          Row(
            children: [
              for (var i = 0; i < data.levelCounts.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _levelTile(data.levelCounts[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _bell() {
    return TriagePressable(
      onTap: data.onNotificationTap,
      builder: (context, pressed) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _tile,
          shape: BoxShape.circle,
          boxShadow: triagePressedShadow(pressed: pressed),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(
              TriageIcons.bell,
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            if (data.hasUnreadNotifications)
              Positioned(
                right: 9,
                top: 9,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB6070C),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _levelTile(MedicoQueueLevelCount level) {
    return Container(
      height: _tileHeight,
      decoration: BoxDecoration(
        color: _tile,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: level.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${level.count}',
            style: AppTextStyles.ESC_Bold_titleLarge.copyWith(
              color: Colors.white,
              fontSize: 20,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
