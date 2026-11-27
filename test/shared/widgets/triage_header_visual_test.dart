// Sandbox visual de TriageDetailHeader: flutter run -t test/shared/widgets/triage_header_visual_test.dart
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
