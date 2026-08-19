import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/gps_location_picker_widget.dart';

/*
  COMANDO PARA PROBAR: 
  flutter run -t test/features/paramedico/presentation/create_incident/widgets/gps_location_picker_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GpsLocationPickerVisualTest(),
    ),
  );
}

class GpsLocationPickerVisualTest extends StatelessWidget {
  const GpsLocationPickerVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: GpsLocationPicker(
            latitude: 19.4326,
            longitude: -99.1332,
            onShowMap: () {},
            onEditManual: () {},
          ),
        ),
      ),
    );
  }
}
