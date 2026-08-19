import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_map_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_map_widget.dart';

/*
  flutter run -t test/features/paramedico/presentation/patient_registration/widgets/patient_map_widget_test.dart
*/

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _PatientMapWidgetTest(),
  ));
}

class _PatientMapWidgetTest extends StatelessWidget {
  const _PatientMapWidgetTest();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Test: PatientMapWidget'),
          backgroundColor: const Color(0xFFCE1125),
        ),
        body: Center(
          child: PatientMapWidget(
            data: PatientMapData(
              latitude: 19.4326,
              longitude: -99.1332,
            ),
          ),
        ),
      ),
    );
  }
}
