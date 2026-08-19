// Test visual aislado del chip de categoría Triage seleccionada.
//
// Run:
// flutter run -t test/features/paramedico/presentation/start_triage/widgets/selected_triage_pill_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/selected_triage_pill_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/selected_triage_pill_widget.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _Demo(),
  ));
}

class _Demo extends StatelessWidget {
  const _Demo();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Fondo oscuro para resaltar la píldora
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: TriageCategory.values.map((cat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: SelectedTriagePillWidget(
                  data: SelectedTriagePillData(
                    category: cat,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
