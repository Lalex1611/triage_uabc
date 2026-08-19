// Test visual aislado de la clasificación START hospitalaria (5 niveles).
//
// Run:
// flutter run -t test/features/medico/presentation/register_patient/widgets/medico_register_triage_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_category.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_triage_data.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_triage_widget.dart';

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
  MedicoTriageCategory? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: MedicoRegisterTriageWidget(
            data: MedicoRegisterTriageData(
              selectedCategory: _selected,
              onCategorySelected: (c) => setState(() => _selected = c),
            ),
          ),
        ),
      ),
    );
  }
}
