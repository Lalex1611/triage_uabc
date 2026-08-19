import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/emergency_type_selector_widget.dart';

import 'package:sistema_triage/features/paramedico/domain/entities/create_incident/emergency_type.dart';

/*
  COMANDO PARA PROBAR: 
  flutter run -t test/features/paramedico/presentation/create_incident/widgets/emergency_type_selector_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EmergencyTypeSelectorVisualTest(),
    ),
  );
}

class EmergencyTypeSelectorVisualTest extends StatelessWidget {
  const EmergencyTypeSelectorVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: EmergencyTypeSelector(
            availableTypes: [
              EmergencyType(id: '1', name: 'Accidente'),
              EmergencyType(id: '2', name: 'Accidente vehicular'),
              EmergencyType(id: '3', name: 'Derrumbe'),
              EmergencyType(id: '4', name: 'Incidente'),
              EmergencyType(id: '5', name: 'Incidente masivo'),
            ],
          ),
        ),
      ),
    );
  }
}
