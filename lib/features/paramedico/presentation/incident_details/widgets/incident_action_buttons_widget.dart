import 'package:flutter/material.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

// Contenedor de botones de acción principales flotantes
class IncidentActionButtons extends StatelessWidget {
  final bool isStatsTab;
  final VoidCallback? onStartTap;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onCloseIncidentTap;

  const IncidentActionButtons({
    super.key,
    this.isStatsTab = false,
    this.onStartTap,
    this.onRegisterTap,
    this.onCloseIncidentTap,
  });

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: TriageColors.surface,
        boxShadow: TriageShadows.bar,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: isStatsTab
              ? TriageButton(
                  label: 'CERRAR INCIDENTE',
                  variant: TriageButtonVariant.secondary,
                  size: TriageButtonSize.large,
                  onPressed: onCloseIncidentTap,
                )
              : TriageButton(
                  label: 'REGISTRAR PACIENTE',
                  variant: TriageButtonVariant.primary,
                  size: TriageButtonSize.large,
                  onPressed: () => _showRegisterModal(context),
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
        color: TriageColors.surface,
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
                color: TriageColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'Registrar paciente',
            style: TriageTextStyles.titleMedium.copyWith(
              color: TriageColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Selecciona el método de evaluación para ingresar al paciente.',
            style: TriageTextStyles.bodyMedium.copyWith(
              color: TriageColors.textSecondary,
            ),
          ),

          const SizedBox(height: 20),

          // Opción 1: Método START
          _buildOptionCard(
            title: 'Triage Método START',
            subtitle: 'Evaluación guiada mediante el algoritmo sistemático.',
            icon: TriageIcons.pulse,
            isPrimary: true,
            onTap: onStartRegister,
          ),

          const SizedBox(height: 12),

          // Opción 2: Registro Directo
          _buildOptionCard(
            title: 'Registro Directo / Manual',
            subtitle: 'Ingreso rápido de datos y asignación manual de estado.',
            icon: TriageIcons.clipboard,
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
    required String icon,
    required VoidCallback onTap,
    bool isPrimary = false,
    String? badgeText,
  }) {
    final accentColor = isPrimary
        ? TriageColors.paramedicAccent
        : TriageColors.borderSubtle;
    final backgroundColor = isPrimary
        ? TriageColors.paramedicSoft
        : TriageColors.surface;
    final iconBackgroundColor = isPrimary
        ? TriageColors.paramedicAccent
        : TriageColors.canvas;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor,
              width: isPrimary ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TriageIcon(
                  icon,
                  color: isPrimary
                      ? TriageColors.surface
                      : TriageColors.textPrimary,
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
                          style: TriageTextStyles.labelLarge.copyWith(
                            color: TriageColors.textPrimary,
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
                              color: TriageColors.paramedicAccent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: TriageTextStyles.labelSmall.copyWith(
                                color: TriageColors.surface,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TriageTextStyles.bodySmall.copyWith(
                        color: TriageColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const TriageIcon(
                TriageIcons.chevronRight,
                color: TriageColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
