// Sandbox visual de diálogos y mensajes de resultado (showTriageConfirm,
// TriageDialog, TriageResultMessage):
// flutter run -t test/shared/widgets/triage_message_visual_test.dart
import 'package:flutter/material.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

void main() => runApp(const _MessageSandbox());

class _MessageSandbox extends StatefulWidget {
  const _MessageSandbox();

  @override
  State<_MessageSandbox> createState() => _MessageSandboxState();
}

class _MessageSandboxState extends State<_MessageSandbox> {
  bool _hospital = false;
  bool _bigText = false;

  Future<void> _confirm(
    BuildContext context, {
    required TriageMessageIcon icon,
    required String title,
    required String confirmLabel,
    TriageButtonVariant variant = TriageButtonVariant.primary,
  }) async {
    final confirmed = await showTriageConfirm(
      context,
      icon: icon,
      title: title,
      message: 'Texto de apoyo que explica qué va a pasar si continúas.',
      confirmLabel: confirmLabel,
      confirmVariant: variant,
    );
    if (context.mounted) {
      showTriageToast(context, confirmed ? 'Confirmado' : 'Cancelado');
    }
  }

  void _showRegistered(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => TriageDialog(
        icon: const TriageMessageIcon.level(
          TriageIcons.check,
          TriageLevel.yellow,
        ),
        title: 'PAC-2036 quedó registrado',
        message: 'Van 6 pacientes clasificados en este incidente.',
        content: const Center(child: TriageLevelPill(TriageLevel.yellow)),
        actions: [
          TriageButton(
            label: 'Registrar siguiente paciente',
            onPressed: () => Navigator.pop(dialogContext),
          ),
          TriageButton(
            label: 'Ver la ficha del paciente',
            variant: TriageButtonVariant.secondary,
            onPressed: () => Navigator.pop(dialogContext),
          ),
          TriageButton(
            label: 'Volver al incidente',
            variant: TriageButtonVariant.subtle,
            size: TriageButtonSize.medium,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  void _showResult(
    BuildContext context, {
    required TriageMessageIcon icon,
    required String title,
    bool prominentTitle = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (pageContext) => Scaffold(
          backgroundColor: TriageColors.surface,
          body: Column(
            children: [
              const TriageDetailHeader(
                title: 'Confirmar recepción',
                subtitle: 'PAC-2031 · Alberto Pérez',
              ),
              Expanded(
                child: TriageResultMessage(
                  icon: icon,
                  title: title,
                  prominentTitle: prominentTitle,
                  message:
                      'Al aceptar, el paciente pasa a "Recibido", se avisa al '
                      'paramédico y entra a la sala hospitalaria.',
                  content: const Column(
                    children: [
                      TriageDataRow(label: 'Paciente', value: 'Alberto Pérez'),
                      TriageDataRow(
                        label: 'Clasificación',
                        value: 'Rojo · inmediato',
                      ),
                      TriageDataRow(
                        label: 'Llegada estimada',
                        value: '6 min · Unidad A-12',
                      ),
                    ],
                  ),
                  actions: [
                    TriageButton(
                      label: 'Sí, lo recibimos',
                      onPressed: () => Navigator.pop(pageContext),
                    ),
                    TriageButton(
                      label: 'Cancelar',
                      variant: TriageButtonVariant.subtle,
                      size: TriageButtonSize.medium,
                      onPressed: () => Navigator.pop(pageContext),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        extensions: [
          _hospital ? TriageRoleTheme.hospital : TriageRoleTheme.paramedic,
        ],
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(_bigText ? 2 : 1)),
        child: child!,
      ),
      home: Scaffold(
        backgroundColor: TriageColors.canvas,
        body: SafeArea(
          child: Builder(
            builder: (context) => ListView(
              padding: const EdgeInsets.all(TriageSpacing.lg),
              children: [
                SwitchListTile(
                  title: const Text('Rol hospital'),
                  value: _hospital,
                  onChanged: (v) => setState(() => _hospital = v),
                ),
                SwitchListTile(
                  title: const Text('Texto al 200 %'),
                  value: _bigText,
                  onChanged: (v) => setState(() => _bigText = v),
                ),
                const _Label('Diálogos'),
                Wrap(
                  spacing: TriageSpacing.sm,
                  runSpacing: TriageSpacing.sm,
                  children: [
                    TriageButton(
                      label: 'Eliminar',
                      variant: TriageButtonVariant.danger,
                      onPressed: () => _confirm(
                        context,
                        icon: const TriageMessageIcon(
                          TriageIcons.trash,
                          tone: TriageTone.danger,
                        ),
                        title: '¿Eliminar esta fotografía?',
                        confirmLabel: 'Eliminar',
                        variant: TriageButtonVariant.danger,
                      ),
                    ),
                    TriageButton(
                      label: 'Permiso',
                      onPressed: () => _confirm(
                        context,
                        icon: const TriageMessageIcon(
                          TriageIcons.location,
                          tone: TriageTone.info,
                        ),
                        title: 'Permite usar tu ubicación',
                        confirmLabel: 'Permitir ubicación',
                      ),
                    ),
                    TriageButton(
                      label: 'Advertencia',
                      variant: TriageButtonVariant.secondary,
                      onPressed: () => _confirm(
                        context,
                        icon: const TriageMessageIcon(
                          TriageIcons.alert,
                          tone: TriageTone.warning,
                        ),
                        title: '¿Salir sin registrar?',
                        confirmLabel: 'Seguir registrando',
                      ),
                    ),
                    TriageButton(
                      label: 'Con contenido',
                      variant: TriageButtonVariant.secondary,
                      onPressed: () => _showRegistered(context),
                    ),
                  ],
                ),
                const _Label('Mensaje de resultado'),
                Wrap(
                  spacing: TriageSpacing.sm,
                  runSpacing: TriageSpacing.sm,
                  children: [
                    TriageButton(
                      label: 'Éxito',
                      variant: TriageButtonVariant.success,
                      onPressed: () => _showResult(
                        context,
                        icon: const TriageMessageIcon(
                          TriageIcons.check,
                          tone: TriageTone.success,
                        ),
                        title: 'Recepción confirmada',
                      ),
                    ),
                    TriageButton(
                      label: 'Pregunta (C03)',
                      onPressed: () => _showResult(
                        context,
                        icon: const TriageMessageIcon.role(
                          TriageIcons.checkCircle,
                        ),
                        title: '¿Aceptas a este paciente?',
                        prominentTitle: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: TriageSpacing.xxl,
      bottom: TriageSpacing.sm,
    ),
    child: Text(text, style: TriageTextStyles.labelSmall),
  );
}
