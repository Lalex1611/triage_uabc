import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_vital_signs_data.dart';

class MedicoRegisterVitalSignsWidget extends StatelessWidget {
  final MedicoRegisterVitalSignsData data;

  const MedicoRegisterVitalSignsWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSectionHeader('Signos vitales'),
          const SizedBox(height: 14),
          _buildBloodPressure(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildLabeledNumberField(
                  label: 'Frecuencia cardiaca',
                  hint: 'Ej: 78',
                  unit: 'lpm',
                  value: data.heartRate,
                  onChanged: data.onHeartRateChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLabeledNumberField(
                  label: 'Frecuencia Respiratoria',
                  hint: 'Ej: 18',
                  unit: 'rpm',
                  value: data.respiratoryRate,
                  onChanged: data.onRespiratoryRateChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildLabeledNumberField(
                  label: 'Temperatura',
                  hint: 'Ej: 37.2',
                  unit: '°C',
                  value: data.temperature,
                  onChanged: data.onTemperatureChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLabeledNumberField(
                  label: 'Oximetría (Saturación O2)',
                  hint: 'Ej: 95',
                  unit: '%',
                  value: data.oxygenSaturation,
                  onChanged: data.onOxygenSaturationChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLabeledNumberField(
            label: 'Glucosa',
            hint: 'Ej: 110',
            unit: 'mg/dL',
            value: data.glucose,
            onChanged: data.onGlucoseChanged,
            fixedFieldWidth: 150,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: AppTextStyles.ESC_SemiBold_titleMedium.copyWith(
            fontSize: 15,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Container(height: 1, color: AppColors.inputBorder),
      ],
    );
  }

  Widget _buildBloodPressure() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Presión arterial'),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 75,
              height: 32,
              child: _buildNumberInput(
                hint: 'Ej: 120',
                value: data.systolicPressure,
                onChanged: data.onSystolicPressureChanged,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 75,
              height: 32,
              child: _buildNumberInput(
                hint: 'Ej: 80',
                value: data.diastolicPressure,
                onChanged: data.onDiastolicPressureChanged,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'mmHg',
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                fontSize: 13,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabeledNumberField({
    required String label,
    required String hint,
    required String unit,
    required String? value,
    required ValueChanged<String> onChanged,
    double? fixedFieldWidth,
  }) {
    Widget field;
    if (fixedFieldWidth != null) {
      field = SizedBox(
        width: fixedFieldWidth,
        height: 32,
        child: _buildNumberInput(
          hint: hint,
          value: value,
          onChanged: onChanged,
        ),
      );
    } else {
      field = Expanded(
        child: SizedBox(
          height: 32,
          child: _buildNumberInput(
            hint: hint,
            value: value,
            onChanged: onChanged,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 6),
        Row(
          children: [
            field,
            const SizedBox(width: 8),
            Text(
              unit,
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                fontSize: 13,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
        fontSize: 13,
        color: Colors.black,
      ),
    );
  }

  Widget _buildNumberInput({
    required String hint,
    required String? value,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      enabled: !data.isReadOnly,
      controller: TextEditingController(text: value ?? ''),
      onChanged: onChanged,
      style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.ESC_Light_bodyMedium.copyWith(
          fontSize: 13,
          color: AppColors.inputHint,
        ),
        isDense: true,
        filled: data.isReadOnly,
        fillColor: AppColors.inputDisabledFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.primaryMedico),
        ),
      ),
    );
  }
}
