import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_extra_data_data.dart';

class MedicoRegisterExtraDataWidget extends StatelessWidget {
  final MedicoRegisterExtraDataData data;

  const MedicoRegisterExtraDataWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSectionHeader('Datos extra'),
          const SizedBox(height: 14),
          _buildField(
            label: 'Alergias conocidas',
            hint: 'Ej: Penicilina....',
            value: data.allergies,
            onChanged: data.onAllergiesChanged,
          ),
          const SizedBox(height: 12),
          _buildField(
            label: 'Medicamentos en uso',
            hint: 'Ej: Losartán....',
            value: data.medications,
            onChanged: data.onMedicationsChanged,
          ),
          const SizedBox(height: 12),
          _buildField(
            label: 'Padecimientos previos',
            hint: 'Ej: EPOC....',
            value: data.medicalHistory,
            onChanged: data.onMedicalHistoryChanged,
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

  Widget _buildField({
    required String label,
    required String hint,
    required String? value,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
            fontSize: 13,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 32,
          child: TextField(
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
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
          ),
        ),
      ],
    );
  }
}
