// Sandbox visual de TriageHomeHeader y TriageDetailHeader: flutter run -t test/shared/widgets/triage_header_visual_test.dart
import 'package:flutter/material.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

void main() => runApp(const _HeaderSandbox());

class _HeaderSandbox extends StatefulWidget {
  const _HeaderSandbox();

  @override
  State<_HeaderSandbox> createState() => _HeaderSandboxState();
}

class _HeaderSandboxState extends State<_HeaderSandbox> {
  bool _hospital = false;
  bool _bigText = false;

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
        body: ListView(
          children: [
            TriageHomeHeader(
              eyebrow: _hospital ? 'Médico receptor' : 'Paramédico en turno',
              title: 'Carlos Huerta',
              onProfileTap: () {},
              onNotificationsTap: () {},
              hasNotifications: true,
            ),
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
            const _Label('Inicio con contenido extra (C01)'),
            TriageHomeHeader(
              title: 'Dra. Mariana Ruiz',
              subtitle: 'Hospital General de Tijuana · Urgencias',
              onProfileTap: () {},
              onNotificationsTap: () {},
              bottom: const Row(
                children: [
                  _Metric(value: '2', label: 'En camino'),
                  SizedBox(width: 10),
                  _Metric(value: '2', label: 'Críticos'),
                  SizedBox(width: 10),
                  _Metric(value: '7', label: 'En sala'),
                ],
              ),
            ),
            const _Label('Inicio sin avatar (C05)'),
            TriageHomeHeader(
              eyebrow: 'SALA HOSPITALARIA',
              title: '7 pacientes en atención',
              onNotificationsTap: () {},
            ),
            const _Label('Detalle'),
            TriageDetailHeader(
              title: 'Título de pantalla',
              onBack: () {},
              onMore: () {},
            ),
            const _Label('Detalle con subtítulo (B13)'),
            TriageDetailHeader(
              title: 'PAC-2031',
              subtitle: 'Bruce Cervantes · INC-729',
              onBack: () {},
              onMore: () {},
            ),
            const SizedBox(height: 24),
          ],
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
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Text(text, style: TriageTextStyles.labelSmall),
  );
}

/// Solo para el sandbox; la métrica real será su propio componente
class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: TriageColors.textInverse.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TriageTextStyles.dataLarge.copyWith(
              color: TriageColors.textInverse,
            ),
          ),
          Text(
            label,
            style: TriageTextStyles.labelSmall.copyWith(
              color: TriageColors.textInverse,
            ),
          ),
        ],
      ),
    ),
  );
}
