import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_actions_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_actions_widget.dart';

/*
  flutter run -t test/features/paramedico/presentation/patient_registration/widgets/patient_actions_widget_test.dart
*/

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _PatientActionsWidgetTest(),
  ));
}

class _PatientActionsWidgetTest extends StatelessWidget {
  const _PatientActionsWidgetTest();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Test: PatientActionsWidget'),
          backgroundColor: const Color(0xFFCE1125),
        ),
        // Verificar que el widget se asienta como bottomNavigationBar y no dentro del scroll
        bottomNavigationBar: PatientActionsWidget(
          data: PatientActionsData(
            onCancelTap: () => debugPrint('CANCELAR presionado'),
            onConfirmTap: () => debugPrint('CONFIRMAR presionado'),
          ),
        ),
        body: const Center(
          child: Text(
            'Los botones CANCELAR/CONFIRMAR\ndeben aparecer fijos en la parte inferior.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
