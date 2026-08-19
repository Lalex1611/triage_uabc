import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_header_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_header_widget.dart';

/*
  flutter run -t test/features/paramedico/presentation/patient_registration/widgets/patient_header_widget_test.dart
*/

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _PatientHeaderWidgetTest(),
  ));
}

class _PatientHeaderWidgetTest extends StatefulWidget {
  const _PatientHeaderWidgetTest();

  @override
  State<_PatientHeaderWidgetTest> createState() => _PatientHeaderWidgetTestState();
}

class _PatientHeaderWidgetTestState extends State<_PatientHeaderWidgetTest> {
  TriageCategory _category = TriageCategory.rojo;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        body: Column(
          children: [
            PatientHeaderWidget(
              data: PatientHeaderData(
                patientId: 'PAC-28321',
                gpsCoordinates: '19.4326, -99.1332',
                isGpsCaptured: true,
                triageCategory: _category,
                onShowMapTap: () => debugPrint('Mostrar'),
                onEditLocationTap: () => debugPrint('Ajustar'),
                onGenerateQrTap: () => debugPrint('QR'),
                onNameChanged: (v) => debugPrint('Nombre: $v'),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Selecciona la categoría para ver el cambio de color:'),
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
                    width: 44,
                    height: 44,
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
    );
  }
}
