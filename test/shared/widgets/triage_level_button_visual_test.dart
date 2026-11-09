// Sandbox visual del botón de color y los marcadores de mapa (TriageLevelButton,
// TriageIncidentMarker, TriagePatientMarker, TriageHospitalMarker,
// TriageUnitMarker, TriageUserMarker):
// flutter run -t test/shared/widgets/triage_level_button_visual_test.dart
import 'package:flutter/material.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

void main() => runApp(const _LevelSandbox());

class _LevelSandbox extends StatefulWidget {
  const _LevelSandbox();

  @override
  State<_LevelSandbox> createState() => _LevelSandboxState();
}

class _LevelSandboxState extends State<_LevelSandbox> {
  bool _hospital = false;
  bool _bigText = false;
  TriageLevel? _selected;
  bool _incidentSelected = false;

  @override
  Widget build(BuildContext context) {
    final levels = _hospital
        ? TriageLevel.hospitalLevels
        : TriageLevel.startLevels;

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
          child: ListView(
            padding: const EdgeInsets.all(TriageSpacing.lg),
            children: [
              SwitchListTile(
                title: const Text('Rol y niveles de hospital'),
                value: _hospital,
                onChanged: (v) => setState(() {
                  _hospital = v;
                  _selected = null;
                }),
              ),
              SwitchListTile(
                title: const Text('Texto al 200 %'),
                value: _bigText,
                onChanged: (v) => setState(() => _bigText = v),
              ),
              const _Label('Botón de color (toca para seleccionar)'),
              for (var i = 0; i < levels.length; i += 2) ...[
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: TriageSpacing.md,
                    children: [
                      for (final level in levels.skip(i).take(2))
                        Expanded(child: _button(level)),
                      if (i + 1 == levels.length) const Spacer(),
                    ],
                  ),
                ),
                const SizedBox(height: TriageSpacing.md),
              ],
              const _Label('Marcador de incidente (toca para seleccionar)'),
              SizedBox(
                width: 88,
                height: TriageSizes.touchTarget,
                child: TriageIncidentMarker(
                  patientCount: 8,
                  selected: _incidentSelected,
                  onTap: () =>
                      setState(() => _incidentSelected = !_incidentSelected),
                ),
              ),
              const _Label('Marcadores de paciente (el último, resaltado)'),
              Wrap(
                spacing: TriageSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final level in TriageLevel.values)
                    TriagePatientMarker(level, onTap: () {}),
                  TriagePatientMarker(
                    TriageLevel.red,
                    highlighted: true,
                    onTap: () {},
                  ),
                ],
              ),
              const _Label('Hospital, unidad y usuario'),
              const Wrap(
                spacing: TriageSpacing.md,
                children: [
                  TriageHospitalMarker(),
                  TriageUnitMarker(),
                  TriageUserMarker(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(TriageLevel level) {
    void onTap() => setState(() => _selected = level);
    final selected = _selected == level;
    return _hospital
        ? TriageLevelButton.hospital(level, selected: selected, onTap: onTap)
        : TriageLevelButton.start(level, selected: selected, onTap: onTap);
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
