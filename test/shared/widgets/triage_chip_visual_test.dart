// Sandbox visual de TriageChip: flutter run -t test/shared/widgets/triage_chip_visual_test.dart
import 'package:flutter/material.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: TriageColors.canvas,
        body: SafeArea(child: _ChipSandbox()),
      ),
    ),
  );
}

class _ChipSandbox extends StatefulWidget {
  const _ChipSandbox();

  @override
  State<_ChipSandbox> createState() => _ChipSandboxState();
}

class _ChipSandboxState extends State<_ChipSandbox> {
  static const _filters = ['Todos', 'Rojo', 'Amarillo', 'Verde', 'Negro'];
  String _active = 'Todos';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Fila con scroll horizontal (como en Figma B07)',
            style: TriageTextStyles.labelSmall,
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => TriageChip(
              label: _filters[i],
              selected: _active == _filters[i],
              onTap: () => setState(() => _active = _filters[i]),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('En Wrap', style: TriageTextStyles.labelSmall),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: [
              for (final f in ['Mis incidentes', 'Todos', 'Cerca de mí'])
                TriageChip(
                  label: f,
                  selected: f == 'Mis incidentes',
                  onTap: () {},
                ),
            ],
          ),
        ),
      ],
    );
  }
}
