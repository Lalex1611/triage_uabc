import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/session/auth_gate.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';

/// Acciones de sesión compartidas para el perfil de paramédico
class ParamedicoSessionActions {
  ParamedicoSessionActions._();

  static Future<void> openProfileSheet(BuildContext context) async {
    final parentContext = context;
    final repo = ParamedicoIncidentsRepository();
    final unitCodeFuture = repo.currentAmbulanceUnitCode();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FutureBuilder<String?>(
              future: unitCodeFuture,
              builder: (_, snapshot) {
                final code = snapshot.data;
                final subtitle = snapshot.hasError
                    ? 'No se pudo consultar la unidad'
                    : snapshot.connectionState == ConnectionState.waiting
                    ? 'Consultando unidad...'
                    : code == null
                    ? 'Sin unidad registrada'
                    : 'Unidad actual: $code';

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Text(
                      'Perfil paramédico',
                      style: AppTextStyles.ESC_Bold_titleLarge.copyWith(
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AuthGate.instance.fullName ?? 'Cuenta activa',
                      style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ProfileActionTile(
                      icon: Icons.local_shipping_outlined,
                      title: 'Código de unidad',
                      subtitle: subtitle,
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        if (!parentContext.mounted) return;
                        await _openUnitCodeDialog(parentContext, repo, code);
                      },
                    ),
                    const SizedBox(height: 10),
                    _ProfileActionTile(
                      icon: Icons.logout_rounded,
                      title: 'Cerrar sesión',
                      subtitle: 'Salir de esta cuenta',
                      destructive: true,
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        if (!parentContext.mounted) return;
                        await confirmSignOut(parentContext);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  static Future<void> _openUnitCodeDialog(
    BuildContext context,
    ParamedicoIncidentsRepository repo,
    String? initialCode,
  ) async {
    final parentContext = context;
    final controller = TextEditingController(text: initialCode ?? '');
    var saving = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text('Código de unidad'),
              content: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Ej. AMB-12',
                  labelText: 'Número económico',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setState(() => saving = true);
                          try {
                            final code = await repo.setCurrentAmbulanceUnitCode(
                              controller.text,
                            );
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            if (parentContext.mounted) {
                              showAppSnackBar(
                                parentContext,
                                'Unidad registrada: $code',
                              );
                            }
                          } catch (e) {
                            if (parentContext.mounted) {
                              showAppSnackBar(
                                parentContext,
                                '$e',
                                isError: true,
                              );
                            }
                            setState(() => saving = false);
                          }
                        },
                  child: Text(saving ? 'Guardando...' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }

  static Future<void> confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Salir de la cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await AuthGate.instance.signOut();
      if (context.mounted) context.go('/auth');
    }
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFB42318)
        : AppColors.primaryParamedico;
    return Material(
      color: destructive ? const Color(0xFFFFF1F1) : const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                        fontSize: 13,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                        fontSize: 11,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: Colors.black.withValues(alpha: 0.32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
