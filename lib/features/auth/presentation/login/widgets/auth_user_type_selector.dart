import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/auth/domain/constants/auth_role_type.dart';

class AuthUserTypeSelector extends StatefulWidget {
  final AuthRoleType currentRole;
  final ValueChanged<AuthRoleType> onRoleSelected;

  const AuthUserTypeSelector({
    super.key,
    required this.currentRole,
    required this.onRoleSelected,
  });

  @override
  State<AuthUserTypeSelector> createState() => _AuthUserTypeSelectorState();
}

class _AuthUserTypeSelectorState extends State<AuthUserTypeSelector> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDropdownItem('PARAMÉDICO', AuthRoleType.paramedico),
                const Divider(height: 1),
                _buildDropdownItem('MÉDICO', AuthRoleType.medico),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  Widget _buildDropdownItem(String label, AuthRoleType type) {
    return InkWell(
      onTap: () {
        widget.onRoleSelected(type);
        _closeDropdown();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Text(
          label,
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            fontSize: 14,
            color: type.primaryColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          /* Parte izquierda (Texto e Ícono) */
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ), // Abraza el texto con padding (un poco más de 5 para que respire bien)
            decoration: BoxDecoration(
              color: widget.currentRole.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(19),
                bottomLeft: Radius.circular(19),
                topRight: Radius.circular(3.8),
                bottomRight: Radius.circular(3.8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons
                      .group_outlined, // Ícono de personas en lugar del SVG equivocado
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.currentRole.dropdownText,
                  style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 2,
          ), // Separación visual ínfima o ninguna, probemos sin espacio pero la curvatura ya lo separa si lo requiere. Pero lo uniremos pegado
          /* Parte derecha (Flecha) interactiva */
          GestureDetector(
            onTap: _toggleDropdown,
            child: Container(
              width: 46,
              height: 38,
              decoration: BoxDecoration(
                color: widget.currentRole.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3.8),
                  bottomLeft: Radius.circular(3.8),
                  topRight: Radius.circular(19),
                  bottomRight: Radius.circular(19),
                ),
              ),
              child: Center(
                child: Transform.rotate(
                  angle: (() {
                    double arrowAngle = 0;
                    if (_isOpen) {
                      arrowAngle = math.pi;
                    }
                    return arrowAngle;
                  })(),
                  child: SvgPicture.asset(
                    AppIcons.unicoPacienteArrowUp,
                    width: 12,
                    height: 12,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
