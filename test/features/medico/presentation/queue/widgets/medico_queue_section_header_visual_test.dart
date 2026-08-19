// Test visual aislado del header de sección "En cola (N) / RECIENTES".
//
// Run:
// flutter run -t test/features/medico/presentation/queue/widgets/medico_queue_section_header_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_sorting_options.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_section_header_data.dart';
import 'package:sistema_triage/features/medico/presentation/queue/widgets/medico_queue_section_header_widget.dart';

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
  MedicoPatientSortOption _sort = MedicoPatientSortOption.recent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: MedicoQueueSectionHeaderWidget(
            data: MedicoQueueSectionHeaderData(
              total: 5,
              currentSort: _sort,
              onSortTap: (newSort) {
                setState(() {
                  _sort = newSort;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
