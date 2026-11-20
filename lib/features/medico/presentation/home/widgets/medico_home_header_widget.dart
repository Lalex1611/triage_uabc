import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/shared/widgets/triage_pressable_widget.dart';

/// Cabecera del Home médico (mockup 01): avatar + nombre + hospital + campana.
class MedicoHomeHeader extends StatelessWidget {
  const MedicoHomeHeader({
    super.key,
    required this.userName,
    required this.hospitalLabel,
    required this.hasNotifications,
    required this.onNotificationTap,
    required this.onProfileTap,
  });

  final String userName;
  final String hospitalLabel;
  final bool hasNotifications;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C69AA),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFBFD0DE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.ESC_Bold_titleLarge.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  hospitalLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Campana con punto rojo
          TriagePressable(
            onTap: onNotificationTap,
            builder: (context, pressed) => Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF3D7EB4),
                shape: BoxShape.circle,
                boxShadow: triagePressedShadow(pressed: pressed),
              ),
              child: SizedBox(
                width: 28,
                height: 28,
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
                    if (hasNotifications)
                      Positioned(
                        right: 6,
                        top: 6,
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
            ),
          ),
        ],
      ),
    );
  }
}
