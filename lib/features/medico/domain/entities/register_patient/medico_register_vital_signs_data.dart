import 'package:flutter/foundation.dart';

@immutable
class MedicoRegisterVitalSignsData {
  final String? systolicPressure;
  final String? diastolicPressure;
  final String? heartRate;
  final String? respiratoryRate;
  final String? temperature;
  final String? oxygenSaturation;
  final String? glucose;
  final bool isReadOnly;

  final ValueChanged<String> onSystolicPressureChanged;
  final ValueChanged<String> onDiastolicPressureChanged;
  final ValueChanged<String> onHeartRateChanged;
  final ValueChanged<String> onRespiratoryRateChanged;
  final ValueChanged<String> onTemperatureChanged;
  final ValueChanged<String> onOxygenSaturationChanged;
  final ValueChanged<String> onGlucoseChanged;

  const MedicoRegisterVitalSignsData({
    required this.onSystolicPressureChanged,
    required this.onDiastolicPressureChanged,
    required this.onHeartRateChanged,
    required this.onRespiratoryRateChanged,
    required this.onTemperatureChanged,
    required this.onOxygenSaturationChanged,
    required this.onGlucoseChanged,
    this.systolicPressure,
    this.diastolicPressure,
    this.heartRate,
    this.respiratoryRate,
    this.temperature,
    this.oxygenSaturation,
    this.glucose,
    this.isReadOnly = false,
  });
}
