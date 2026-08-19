// Test visual aislado de la sección de Signos vitales (médico).
//
// Run:
// flutter run -t test/features/medico/presentation/register_patient/widgets/medico_register_vital_signs_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_vital_signs_data.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_vital_signs_widget.dart';

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: MedicoRegisterVitalSignsWidget(
            data: MedicoRegisterVitalSignsData(
              onSystolicPressureChanged: (v) => debugPrint('sys: $v'),
              onDiastolicPressureChanged: (v) => debugPrint('dia: $v'),
              onHeartRateChanged: (v) => debugPrint('hr: $v'),
              onRespiratoryRateChanged: (v) => debugPrint('rr: $v'),
              onTemperatureChanged: (v) => debugPrint('temp: $v'),
              onOxygenSaturationChanged: (v) => debugPrint('o2: $v'),
              onGlucoseChanged: (v) => debugPrint('glu: $v'),
            ),
          ),
        ),
      ),
    );
  }
}
