import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_description_data.dart';

class MedicoRegisterDescriptionWidget extends StatelessWidget {
  final MedicoRegisterDescriptionData data;

  const MedicoRegisterDescriptionWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [_buildLabel(), const SizedBox(height: 6), _buildBox()],
      ),
    );
  }

  Widget _buildLabel() {
    return Row(
      children: [
        Text(
          'Especifique los síntomas/Motivo de consulta ',
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            fontSize: 13,
            color: Colors.black,
          ),
        ),
        Text(
          '*:',
          style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
            fontSize: 13,
            color: AppColors.requiredAsterisk,
          ),
        ),
      ],
    );
  }

  Widget _buildBox() {
    if (data.isReadOnly && data.descriptionText.isEmpty) {
      return Container(
        height: 110,
        width: double.infinity,
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.inputDisabledFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Text(
          'N/A',
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            fontSize: 13,
            color: AppColors.inactive,
          ),
        ),
      );
    }

    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: TextField(
        maxLines: null,
        expands: true,
        enabled: !data.isReadOnly,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
        controller: TextEditingController(text: data.descriptionText),
        onChanged: data.onDescriptionChanged,
        style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
          fontSize: 13,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Síntomas...',
          hintStyle: AppTextStyles.ESC_Light_bodyMedium.copyWith(
            fontSize: 13,
            color: AppColors.inputHint,
          ),
          contentPadding: const EdgeInsets.all(12),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}
