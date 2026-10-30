// Sandbox visual de TriageTabs: flutter run -t test/shared/widgets/triage_tabs_visual_test.dart
import 'package:flutter/material.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: TriageColors.surface,
        body: SafeArea(child: _TabsSandbox()),
      ),
    ),
  );
}

class _TabsSandbox extends StatefulWidget {
  const _TabsSandbox();

  @override
  State<_TabsSandbox> createState() => _TabsSandboxState();
}

class _TabsSandboxState extends State<_TabsSandbox> {
  static const _labels = ['Pacientes', 'Mapa', 'Detalles', 'Resumen'];
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Ancho completo', style: TriageTextStyles.labelSmall),
        const SizedBox(height: 8),
        TriageTabs(
          labels: _labels,
          selectedIndex: _index,
          onChanged: (i) => setState(() => _index = i),
        ),
        const SizedBox(height: 8),
        Text(
          'Seleccionada: ${_labels[_index]}',
          style: TriageTextStyles.bodySmall,
        ),
        const SizedBox(height: 24),
        const Text(
          'Pantalla angosta (220 px)',
          style: TriageTextStyles.labelSmall,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 220,
            child: TriageTabs(
              labels: _labels,
              selectedIndex: _index,
              onChanged: (i) => setState(() => _index = i),
            ),
          ),
        ),
      ],
    );
  }
}
