import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/shared/widgets/triage_pressable_widget.dart';

/// Campana de notificaciones de los encabezados azules del médico (Entradas
/// y Sala), con punto rojo si hay notificaciones sin leer. Un solo widget para
/// que se vea igual en ambas pestañas.
class MedicoBellButton extends StatelessWidget {
  const MedicoBellButton({
    super.key,
    required this.hasUnread,
    required this.onTap,
  });

  final bool hasUnread;
  final VoidCallback? onTap;

  static const _background = Color(0xFF3D7EB4);
  static const _dot = Color(0xFFB6070C);

  @override
  Widget build(BuildContext context) {
    return TriagePressable(
      onTap: onTap,
      builder: (context, pressed) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _background,
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
            if (hasUnread)
              Positioned(
                right: 9,
                top: 9,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: _dot,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
