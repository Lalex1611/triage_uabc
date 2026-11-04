// Sandbox visual de hoja inferior, pasos, opción grande y foto (showTriageSheet,
// TriageSteps, TriageLargeOption, TriagePhoto):
// flutter run -t test/shared/widgets/triage_sheet_visual_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

void main() => runApp(const _SheetSandbox());

final _samplePhoto = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  ),
);

class _SheetSandbox extends StatefulWidget {
  const _SheetSandbox();

  @override
  State<_SheetSandbox> createState() => _SheetSandboxState();
}

class _SheetSandboxState extends State<_SheetSandbox> {
  bool _hospital = false;
  bool _bigText = false;
  int _step = 1;

  List<Widget> _options() => [
    TriageLargeOption(
      icon: TriageIcons.clipboard,
      title: 'START guiado',
      detail: 'Responde 4 o 5 preguntas cortas y el sistema propone el color.',
      highlighted: true,
      onTap: () {},
    ),
    const SizedBox(height: TriageSpacing.md),
    TriageLargeOption(
      icon: TriageIcons.pulse,
      title: 'Asignar color directo',
      detail: 'Ya sabes la prioridad. Un toque y queda registrado.',
      neutral: true,
      onTap: () {},
    ),
  ];

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
                const _Label('Hoja inferior'),
                Wrap(
                  spacing: TriageSpacing.sm,
                  runSpacing: TriageSpacing.sm,
                  children: [
                    TriageButton(
                      label: 'Con opciones',
                      onPressed: () => showTriageSheet<void>(
                        context,
                        title: 'Registrar paciente',
                        subtitle: 'INC-729 · Accidente vehicular',
                        builder: (_) => Padding(
                          padding: const EdgeInsets.all(TriageSpacing.xl),
                          child: Column(children: _options()),
                        ),
                      ),
                    ),
                    TriageButton(
                      label: 'Con pasos',
                      onPressed: () => showTriageSheet<void>(
                        context,
                        title: 'Asignar traslado',
                        subtitle: 'Paso 2 de 3 · hospital destino',
                        steps: const TriageSteps(current: 2, total: 3),
                        builder: (_) => const Padding(
                          padding: EdgeInsets.all(TriageSpacing.xl),
                          child: TriageField(
                            label: 'Institución',
                            hint: 'Abre el teclado: la hoja sube',
                          ),
                        ),
                      ),
                    ),
                    TriageButton(
                      label: 'Sin X, muy larga',
                      onPressed: () => showTriageSheet<void>(
                        context,
                        title: 'Ordenar incidentes',
                        showClose: false,
                        builder: (_) => Column(
                          children: [
                            for (var i = 1; i <= 30; i++)
                              TriageDataRow(label: 'Fila $i', onTap: () {}),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                _Label('Pasos (paso $_step de 5)'),
                TriageSteps(current: _step, total: 5),
                Slider(
                  value: _step.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (v) => setState(() => _step = v.round()),
                ),
                const _Label('Opción grande (rol, neutra, resaltada)'),
                TriageLargeOption(
                  icon: TriageIcons.clipboard,
                  title: 'Título de la acción',
                  detail: 'Una línea que explica cuándo usarla.',
                  onTap: () {},
                ),
                const SizedBox(height: TriageSpacing.md),
                ..._options(),
                const _Label('Foto (vacía, con imagen y sin toque)'),
                Row(
                  spacing: TriageSpacing.sm,
                  children: [
                    Expanded(child: TriagePhoto(onTap: () {})),
                    Expanded(
                      child: TriagePhoto(image: _samplePhoto, onTap: () {}),
                    ),
                    Expanded(child: TriagePhoto(image: _samplePhoto)),
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
