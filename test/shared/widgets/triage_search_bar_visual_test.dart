// Sandbox visual de TriageSearchBar: flutter run -t test/shared/widgets/triage_search_bar_visual_test.dart
import 'package:flutter/material.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: TriageColors.canvas,
        body: SafeArea(child: _SearchSandbox()),
      ),
    ),
  );
}

class _SearchSandbox extends StatefulWidget {
  const _SearchSandbox();

  @override
  State<_SearchSandbox> createState() => _SearchSandboxState();
}

class _SearchSandboxState extends State<_SearchSandbox> {
  static const _patients = [
    'Bruce Cervantes',
    'Paciente sin identificar',
    'Alexander Odabachea',
    'Alan Torres',
    'Lucía Medina',
  ];
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = _patients
        .where((p) => p.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TriageSearchBar(
          hint: 'Buscar paciente',
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        for (final p in results)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(p, style: TriageTextStyles.bodyMedium),
          ),
      ],
    );
  }
}
