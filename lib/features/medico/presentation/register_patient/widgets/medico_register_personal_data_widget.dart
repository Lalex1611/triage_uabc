import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_insurance_option.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_gender.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_personal_data.dart';

class MedicoRegisterPersonalDataWidget extends StatelessWidget {
  final MedicoRegisterPersonalData data;

  const MedicoRegisterPersonalDataWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBirthDateField(),
              _buildGenderColumn(),
              _buildEditIcon(),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildPhoneField(), _buildInsuranceDropdown()],
          ),
        ],
      ),
    );
  }

  Widget _buildEditIcon() {
    if (data.onEditTap == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: GestureDetector(
        onTap: data.onEditTap,
        child: SvgPicture.asset(
          AppIcons.unicoPacienteEdit,
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
        fontSize: 13,
        color: Colors.black,
      ),
    );
  }

  OutlineInputBorder _border() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.inputBorder),
    );
  }

  OutlineInputBorder _focusedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.primaryMedico),
    );
  }

  Widget _buildReadOnlyBox(String? value, double width) {
    String display = 'N/A';
    if (value != null && value.isNotEmpty) {
      display = value;
    }
    return Container(
      width: width,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.inputDisabledFill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Text(
        display,
        style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
          fontSize: 13,
          color: AppColors.inactive,
        ),
      ),
    );
  }

  Widget _buildBirthDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Fecha de nacimiento (opcional):'),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildDateBox('DD', 2, data.onDayChanged, data.birthDay),
            const SizedBox(width: 6),
            _buildDateBox('MM', 2, data.onMonthChanged, data.birthMonth),
            const SizedBox(width: 6),
            _buildDateBox(
              'YYYY',
              4,
              data.onYearChanged,
              data.birthYear,
              width: 60,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateBox(
    String hint,
    int maxLen,
    ValueChanged<String> onChanged,
    String? value, {
    double width = 44,
  }) {
    if (data.isReadOnly) {
      return _buildReadOnlyBox(value, width);
    }

    return SizedBox(
      width: width,
      height: 32,
      child: TextField(
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: maxLen,
        controller: TextEditingController(text: value ?? ''),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.ESC_Light_bodyMedium.copyWith(
            fontSize: 13,
            color: AppColors.inputHint,
          ),
          counterText: '',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          border: _border(),
          enabledBorder: _border(),
          focusedBorder: _focusedBorder(),
        ),
      ),
    );
  }

  Widget _buildGenderColumn() {
    Widget field;
    if (data.isReadOnly) {
      field = _buildReadOnlyBox(data.gender?.label, 60);
    } else {
      field = Container(
        width: 60,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inputBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<MedicoPatientGender>(
            value: data.gender,
            isExpanded: true,
            hint: Text(
              'M/F',
              style: AppTextStyles.ESC_Light_bodyMedium.copyWith(
                fontSize: 13,
                color: AppColors.inputHint,
              ),
            ),
            icon: Transform.rotate(
              angle: math.pi,
              child: SvgPicture.asset(
                AppIcons.unicoPacienteArrowUp,
                width: 12,
                height: 12,
              ),
            ),
            items: MedicoPatientGender.values.map((g) {
              return DropdownMenuItem<MedicoPatientGender>(
                value: g,
                child: Text(
                  g.label,
                  style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
            onChanged: data.onGenderChanged,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Sexo (opcional):'),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  Widget _buildPhoneField() {
    Widget field;
    if (data.isReadOnly) {
      field = _buildReadOnlyBox(data.contactNumber, 175);
      /* Override alignment for phone (left) */
      field = Container(
        width: 175,
        height: 32,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.inputDisabledFill,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Text(
          (data.contactNumber == null || data.contactNumber!.isEmpty)
              ? 'N/A'
              : data.contactNumber!,
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            fontSize: 13,
            color: AppColors.inactive,
          ),
        ),
      );
    } else {
      field = SizedBox(
        width: 175,
        height: 32,
        child: TextField(
          keyboardType: TextInputType.phone,
          controller: TextEditingController(text: data.contactNumber ?? ''),
          onChanged: data.onContactNumberChanged,
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Ej: 664 123 4567',
            hintStyle: AppTextStyles.ESC_Light_bodyMedium.copyWith(
              fontSize: 13,
              color: AppColors.inputHint,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            border: _border(),
            enabledBorder: _border(),
            focusedBorder: _focusedBorder(),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Teléfono de contacto:'),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  Widget _buildInsuranceDropdown() {
    Widget field;
    if (data.isReadOnly) {
      field = _buildReadOnlyBox(data.insurance?.label, 90);
    } else {
      field = Container(
        width: 90,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inputBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<MedicoInsuranceOption>(
            value: data.insurance,
            isExpanded: true,
            hint: Text(
              'Si/No',
              style: AppTextStyles.ESC_Light_bodyMedium.copyWith(
                fontSize: 13,
                color: AppColors.inputHint,
              ),
            ),
            icon: Transform.rotate(
              angle: math.pi,
              child: SvgPicture.asset(
                AppIcons.unicoPacienteArrowUp,
                width: 12,
                height: 12,
              ),
            ),
            items: MedicoInsuranceOption.values.map((opt) {
              return DropdownMenuItem<MedicoInsuranceOption>(
                value: opt,
                child: Text(
                  opt.label,
                  style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
            onChanged: data.onInsuranceChanged,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('¿Seguro médico?'),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}
