// Sandbox visual de tarjetas y datos (TriagePatientCard, TriageIncidentCard,
// TriageMetric, TriageLevelCount, TriageLevelPill):
// flutter run -t test/shared/widgets/triage_cards_visual_test.dart
import 'package:flutter/material.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

void main() => runApp(const _CardsSandbox());

class _CardsSandbox extends StatefulWidget {
  const _CardsSandbox();

  @override
  State<_CardsSandbox> createState() => _CardsSandboxState();
}

class _CardsSandboxState extends State<_CardsSandbox> {
  bool _hospital = false;
  bool _bigText = false;
  int _selectedIncident = 0;

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
          child: ListView(
            padding: const EdgeInsets.all(16),
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
              const _Label('Pastilla de color'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final level in TriageLevel.values)
                    TriageLevelPill(level),
                ],
              ),
              const _Label('Conteo'),
              const TriageLevelCount(
                counts: {
                  TriageLevel.red: 3,
                  TriageLevel.yellow: 2,
                  TriageLevel.green: 12,
                },
              ),
              const _Label('Métricas (neutra, niveles, rol)'),
              const Row(
                children: [
                  Expanded(
                    child: TriageMetric(value: '8', label: 'Pacientes'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TriageMetric.level(
                      TriageLevel.red,
                      value: '3',
                      label: 'Rojos',
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TriageMetric.role(value: '2', label: 'En camino'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Expanded(
                    child: TriageMetric.level(
                      TriageLevel.yellow,
                      value: '2',
                      label: 'Amarillos',
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TriageMetric.level(
                      TriageLevel.green,
                      value: '3',
                      label: 'Verdes',
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TriageMetric.level(
                      TriageLevel.black,
                      value: '0',
                      label: 'Negros',
                    ),
                  ),
                ],
              ),
              const _Label('Tarjeta de incidente (toca para seleccionar)'),
              for (final (i, (folio, title, place, count)) in const [
                ('INC-729', 'Accidente vehicular', 'Blvd. Díaz Ordaz', 8),
                ('INC-731', 'Atropellamiento', 'Av. Revolución 1250', 1),
              ].indexed) ...[
                TriageIncidentCard(
                  folio: folio,
                  timeAgo: 'hace ${18 + i * 16} min',
                  title: title,
                  location:
                      '$place · a ${(1.4 + i * 1.7).toStringAsFixed(1)} km',
                  counts: const {
                    TriageLevel.red: 3,
                    TriageLevel.yellow: 2,
                    TriageLevel.green: 3,
                  },
                  patientCount: count,
                  selected: _selectedIncident == i,
                  onTap: () => setState(() => _selectedIncident = i),
                ),
                const SizedBox(height: 12),
              ],
              const _Label('Tarjeta de paciente (B07)'),
              for (final (name, detail, level, status) in const [
                (
                  'Bruce Cervantes',
                  'PAC-2031 · 14:34 · hemorragia',
                  TriageLevel.red,
                  PatientLifecycleStatus.transferring,
                ),
                (
                  'Paciente sin identificar',
                  'PAC-2032 · 14:36 · inconsciente',
                  TriageLevel.red,
                  PatientLifecycleStatus.waiting,
                ),
                (
                  'Alexander Odabachea',
                  'PAC-2033 · 14:38 · fractura expuesta',
                  TriageLevel.yellow,
                  PatientLifecycleStatus.waiting,
                ),
              ]) ...[
                TriagePatientCard(
                  name: name,
                  detail: detail,
                  level: level,
                  badge: TriageStatusBadge.patient(status),
                  onTap: () {},
                ),
                const SizedBox(height: 12),
              ],
              const _Label('Tarjeta de sala (C05)'),
              for (final (name, detail, level, status) in const [
                (
                  'Alberto Pérez',
                  'Hace 4 min · del incidente INC-729',
                  TriageLevel.red,
                  PatientLifecycleStatus.received,
                ),
                (
                  'Lourdes Carrillo',
                  'Hace 22 min · llegó por su cuenta',
                  TriageLevel.orange,
                  PatientLifecycleStatus.waiting,
                ),
                (
                  'Sofía Ibarra',
                  'Hace 51 min · llegó por su cuenta',
                  TriageLevel.green,
                  PatientLifecycleStatus.waiting,
                ),
              ]) ...[
                TriagePatientCard.room(
                  name: name,
                  detail: detail,
                  level: level,
                  badge: TriageStatusBadge.patient(status),
                  onTap: () {},
                ),
                const SizedBox(height: 12),
              ],
            ],
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
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(text, style: TriageTextStyles.labelSmall),
  );
}
