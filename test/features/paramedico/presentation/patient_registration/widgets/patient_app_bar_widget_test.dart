import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_app_bar_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_app_bar_widget.dart';

/*
  flutter run -t test/features/paramedico/presentation/patient_registration/widgets/patient_app_bar_widget_test.dart
*/

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _PatientAppBarWidgetTest(),
  ));
}

class _PatientAppBarWidgetTest extends StatefulWidget {
  const _PatientAppBarWidgetTest();

  @override
  State<_PatientAppBarWidgetTest> createState() => _PatientAppBarWidgetTestState();
}

class _PatientAppBarWidgetTestState extends State<_PatientAppBarWidgetTest> {
  TriageCategory _category = TriageCategory.rojo;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        appBar: PatientAppBarWidget(
          data: PatientAppBarData(
            triageCategory: _category,
            onBackTap: () => debugPrint('Regresar'),
            onCloseIncidentTap: () => debugPrint('Cerrar Incidente'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Cambia el color del AppBar:'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: TriageCategory.values
                    .where((c) => c != TriageCategory.todos)
                    .map((c) {
                  return GestureDetector(
                    onTap: () => setState(() => _category = c),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.color == Colors.black ? const Color(0xFF1A1A1A) : c.color,
                        shape: BoxShape.circle,
                        border: _category == c
                            ? Border.all(color: Colors.blue, width: 3)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
