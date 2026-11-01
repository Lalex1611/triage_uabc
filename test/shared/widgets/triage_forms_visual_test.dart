// Sandbox visual de formularios y avisos (TriageDataRow, TriageField,
// TriageSelectField, TriageAlert, showTriageToast):
// flutter run -t test/shared/widgets/triage_forms_visual_test.dart
import 'package:flutter/material.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

void main() => runApp(const _FormsSandbox());

class _FormsSandbox extends StatefulWidget {
  const _FormsSandbox();

  @override
  State<_FormsSandbox> createState() => _FormsSandboxState();
}

class _FormsSandboxState extends State<_FormsSandbox> {
  final _form = GlobalKey<FormState>();
  bool _hospital = false;
  bool _bigText = false;
  String? _sex;

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
                const _Label('Fila de dato (valor, flecha, nada)'),
                const TriageDataRow(label: 'Edad', value: '34 años'),
                TriageDataRow(
                  label: 'Hospital destino',
                  value: 'Hospital General',
                  onTap: () {},
                ),
                const TriageDataRow(label: 'Alergias'),
                const _Label('Campo (texto, selección, área; Validar)'),
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      TriageField(
                        label: 'Nombre',
                        hint: 'Nombre y apellidos',
                        validator: (v) => v!.isEmpty
                            ? 'Escribe el nombre del paciente'
                            : null,
                      ),
                      const SizedBox(height: TriageSpacing.lg),
                      TriageSelectField<String>(
                        label: 'Sexo',
                        hint: 'Selecciona',
                        value: _sex,
                        options: const ['Femenino', 'Masculino', 'Otro'],
                        optionLabel: (o) => o,
                        onChanged: (v) => setState(() => _sex = v),
                        validator: (v) => v == null ? 'Elige una opción' : null,
                      ),
                      const SizedBox(height: TriageSpacing.lg),
                      const TriageField.area(
                        label: 'Descripción',
                        hint: 'Qué pasó y cómo se encuentra',
                      ),
                      const SizedBox(height: TriageSpacing.lg),
                      const TriageField(
                        label: 'Folio',
                        initialValue: 'INC-729',
                        enabled: false,
                      ),
                      const SizedBox(height: TriageSpacing.lg),
                      TriageButton(
                        label: 'Validar',
                        onPressed: () => _form.currentState!.validate(),
                      ),
                    ],
                  ),
                ),
                const _Label('Aviso'),
                for (final tone in TriageTone.values) ...[
                  TriageAlert(
                    tone: tone,
                    title: 'Aviso ${tone.name}',
                    message: 'Explicación breve del aviso.',
                  ),
                  const SizedBox(height: TriageSpacing.md),
                ],
                const _Label('Aviso breve (toca para mostrar)'),
                Wrap(
                  spacing: TriageSpacing.sm,
                  runSpacing: TriageSpacing.sm,
                  children: [
                    for (final tone in TriageTone.values)
                      TriageButton(
                        label: tone.name,
                        onPressed: () => showTriageToast(
                          context,
                          'Gracias, confirmaste que sigue ocurriendo',
                          tone: tone,
                          actionLabel: 'Deshacer',
                          onAction: () {},
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
