// Test visual aislado de los chips de filtro de la cola del médico.
//
// Run:
// flutter run -t test/features/medico/presentation/queue/widgets/medico_queue_filter_chips_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_queue_filter.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_filter_chips_data.dart';
import 'package:sistema_triage/features/medico/presentation/queue/widgets/medico_queue_filter_chips_widget.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _Demo(),
  ));
}

class _Demo extends StatefulWidget {
  const _Demo();

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  MedicoQueueFilter _filter = MedicoQueueFilter.enCamino;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: MedicoQueueFilterChipsWidget(
            data: MedicoQueueFilterChipsData(
              selectedFilter: _filter,
              onFilterSelected: (f) => setState(() => _filter = f),
            ),
          ),
        ),
      ),
    );
  }
}
