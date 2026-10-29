import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/shared/widgets/app_sticky_action_bar.dart';

// Contenedor de botones de acción principales flotantes
class IncidentActionButtons extends StatelessWidget {
  final VoidCallback? onStartTap;
  final VoidCallback? onRegisterTap;

  const IncidentActionButtons({super.key, this.onStartTap, this.onRegisterTap});

  void _showRegisterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _RegisterPatientModal(
        onStartRegister: () {
          Navigator.pop(modalContext);
          onStartTap?.call();
        },
        onNormalRegister: () {
          Navigator.pop(modalContext);
          onRegisterTap?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppStickyActionBar(
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: _ActionButton(
          label: 'REGISTRAR PACIENTE',
          onTap: () => _showRegisterModal(context),
          backgroundColor: AppColors.primaryParamedico,
          textColor: Colors.white,
          fontSize: 15,
          hasShadow: true,
        ),
      ),
    );
  }
}

// Widget interno animado para la respuesta táctil de los botones
class _ActionButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final bool hasShadow;

  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
    required this.fontSize,
    this.hasShadow = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isDisabled
                ? widget.backgroundColor.withValues(alpha: 0.5)
                : widget.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.hasShadow && !isDisabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF111827).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.label,
              style: AppTextStyles.ESC_ExtraBold_titleLarge.copyWith(
                fontSize: widget.fontSize,
                color: widget.textColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Modal desplegable inferior para seleccionar el método de registro
class _RegisterPatientModal extends StatelessWidget {
  final VoidCallback onNormalRegister;
  final VoidCallback onStartRegister;

  const _RegisterPatientModal({
    required this.onNormalRegister,
    required this.onStartRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tirador superior del modal
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'Registrar paciente',
            style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
              fontSize: 18,
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Selecciona el método de evaluación para ingresar al paciente.',
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 20),

          // Opción 1: Método START
          _buildOptionCard(
            title: 'Triage Método START',
            subtitle: 'Evaluación guiada mediante el algoritmo sistemático.',
            icon: Icons.checklist_rtl_rounded,
            isPrimary: true,
            onTap: onStartRegister,
          ),

          const SizedBox(height: 12),

          // Opción 2: Registro Directo
          _buildOptionCard(
            title: 'Registro Directo / Manual',
            subtitle: 'Ingreso rápido de datos y asignación manual de estado.',
            icon: Icons.assignment_outlined,
            isPrimary: false,
            onTap: onNormalRegister,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
    String? badgeText,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFFF9FAFB) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary
                  ? AppColors.primaryParamedico
                  : const Color(0xFFE5E7EB),
              width: isPrimary ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? AppColors.primaryParamedico.withValues(alpha: 0.7)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? Colors.white : const Color(0xFF374151),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                            fontSize: 14,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111827),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
