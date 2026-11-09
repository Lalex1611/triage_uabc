// Sandbox visual de tarjeta de sección, barra de acciones y botón de ícono
// (TriageSectionCard, TriageSectionAction, TriageActionBar, TriageIconButton):
// flutter run -t test/shared/widgets/triage_section_visual_test.dart
import 'package:flutter/material.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

void main() => runApp(const _SectionSandbox());

class _SectionSandbox extends StatefulWidget {
  const _SectionSandbox();

  @override
  State<_SectionSandbox> createState() => _SectionSandboxState();
}

class _SectionSandboxState extends State<_SectionSandbox> {
  bool _hospital = false;
  bool _bigText = false;
  int _barKind = 0;

  Widget _bar() => switch (_barKind) {
    0 => TriageActionBar(
      primary: TriageButton(label: 'Registrar paciente', onPressed: () {}),
    ),
    1 => TriageActionBar(
      secondary: TriageButton(
        label: 'Cancelar',
        variant: TriageButtonVariant.secondary,
        onPressed: () {},
      ),
      primary: TriageButton(label: 'Guardar paciente', onPressed: () {}),
    ),
    _ => TriageActionBar(
      leading: TriageIconButton(
        icon: TriageIcons.qr,
        tooltip: 'Código de consulta',
        size: TriageIconButtonSize.large,
        onPressed: () {},
      ),
      primary: TriageButton(label: 'Reasignar hospital', onPressed: () {}),
    ),
  };

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
        body: Column(
          children: [
            TriageDetailHeader(
              title: 'PAC-2031',
              subtitle: 'Bruce Cervantes · INC-729',
              useCloseIcon: _barKind == 1,
              onBack: () {},
              onMore: () {},
            ),
            Expanded(
              child: ListView(
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
                  Wrap(
                    spacing: TriageSpacing.sm,
                    children: [
                      for (final (i, label) in const [
                        'Una acción',
                        'Dos acciones',
                        'Con ícono',
                      ].indexed)
                        TriageChip(
                          label: label,
                          selected: _barKind == i,
                          onTap: () => setState(() => _barKind = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: TriageSpacing.lg),
                  TriageSectionCard(
                    title: 'Estado actual',
                    trailing: TriageStatusBadge.patient(
                      PatientLifecycleStatus.transferring,
                    ),
                    child: const Text('Contenido de la sección'),
                  ),
                  const SizedBox(height: TriageSpacing.lg),
                  TriageSectionCard(
                    title: 'Datos del paciente',
                    trailing: TriageSectionAction(
                      label: 'Editar',
                      icon: TriageIcons.pencil,
                      onTap: () {},
                    ),
                    child: const Column(
                      children: [
                        TriageDataRow(label: 'Edad', value: '34 años'),
                        TriageDataRow(label: 'Sexo', value: 'Masculino'),
                      ],
                    ),
                  ),
                  const SizedBox(height: TriageSpacing.lg),
                  const TriageSectionCard(
                    child: TriageDataRow(
                      label: 'Sin título',
                      value: 'Solo contenido',
                    ),
                  ),
                  const SizedBox(height: TriageSpacing.lg),
                  Wrap(
                    spacing: TriageSpacing.sm,
                    children: [
                      TriageIconButton(
                        icon: TriageIcons.sort,
                        tooltip: 'Ordenar',
                        onPressed: () {},
                      ),
                      TriageIconButton(
                        icon: TriageIcons.layers,
                        tooltip: 'Capas',
                        variant: TriageIconButtonVariant.surface,
                        onPressed: () {},
                      ),
                      const TriageIconButton(
                        icon: TriageIcons.filter,
                        tooltip: 'Filtrar',
                        onPressed: null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _bar(),
          ],
        ),
      ),
    );
  }
}
