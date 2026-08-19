import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_blood_type.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_gender.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_personal_data.dart';

class PatientPersonalDataWidget extends StatelessWidget {
  final PatientPersonalData data;

  const PatientPersonalDataWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildBirthDateField(), _buildGenderDropdown()],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildBloodTypeDropdown(), _buildContactField()],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
        fontSize: 13,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildBirthDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Fecha de nacimiento (opcional):'),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildDateBox(
              'DD',
              2,
              data.onDayChanged,
              data.birthDay?.toString(),
            ),
            const SizedBox(width: 6),
            _buildDateBox(
              'MM',
              2,
              data.onMonthChanged,
              data.birthMonth?.toString(),
            ),
            const SizedBox(width: 6),
            _buildDateBox(
              'YYYY',
              4,
              data.onYearChanged,
              data.birthYear?.toString(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateBox(
    String hint,
    int maxLen,
    void Function(String) onChanged,
    String? value,
  ) {
    if (data.isReadOnly) {
      final displayValue = (value == null || value.isEmpty) ? 'N/A' : value;
      return Container(
        width: 54,
        height: 29,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFFD9D9D9)),
        ),
        child: Text(
          displayValue,
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            fontSize: 13,
            color: const Color(0xFF999A9D),
          ),
        ),
      );
    }

    return SizedBox(
      width: 54,
      height: 29,
      child: TextField(
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: maxLen,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.ESC_Light_bodyMedium.copyWith(
            fontSize: 13,
            color: const Color(0xFFCCCCCC),
          ),
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Color(0xFFCE1125)),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    if (data.isReadOnly) {
      final displayValue = data.gender != null ? data.gender!.label : 'N/A';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Sexo (opcional):'),
          const SizedBox(height: 6),
          Container(
            width: 77,
            height: 29,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFD9D9D9)),
            ),
            child: Text(
              displayValue,
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                fontSize: 13,
                color: const Color(0xFF999A9D),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Sexo (opcional):'),
        const SizedBox(height: 6),
        Container(
          width: 77,
          height: 29,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD9D9D9)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PatientGender>(
              value: data.gender,
              hint: Text(
                'M/F',
                style: AppTextStyles.ESC_Light_bodyMedium.copyWith(
                  fontSize: 13,
                  color: const Color(0xFFCCCCCC),
                ),
              ),
              icon: Transform.rotate(
                angle: math.pi, // Rotate arrow up to point down
                child: SvgPicture.asset(
                  AppIcons.unicoPacienteArrowUp,
                  width: 12,
                  height: 12,
                ),
              ),
              isExpanded: true,
              items: PatientGender.values.map((g) {
                return DropdownMenuItem<PatientGender>(
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
        ),
      ],
    );
  }

  Widget _buildBloodTypeDropdown() {
    if (data.isReadOnly) {
      final displayValue = data.bloodType != null
          ? data.bloodType!.label
          : 'N/A';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Tipo de Sangre (opcional):'),
          const SizedBox(height: 6),
          Container(
            width: 126,
            height: 29,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFD9D9D9)),
            ),
            child: Text(
              displayValue,
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                fontSize: 13,
                color: const Color(0xFF999A9D),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Tipo de Sangre (opcional):'),
        const SizedBox(height: 6),
        Container(
          width: 126,
          height: 29,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD9D9D9)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PatientBloodType>(
              value: data.bloodType,
              hint: Text(
                'AB+',
                style: AppTextStyles.ESC_Light_bodyMedium.copyWith(
                  fontSize: 13,
                  color: const Color(0xFFCCCCCC),
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
              isExpanded: true,
              items: PatientBloodType.values.map((b) {
                return DropdownMenuItem<PatientBloodType>(
                  value: b,
                  child: Text(
                    b.label,
                    style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
              onChanged: data.onBloodTypeChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactField() {
    if (data.isReadOnly) {
      final displayValue =
          (data.contactNumber == null || data.contactNumber!.isEmpty)
          ? 'N/A'
          : data.contactNumber!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Número de contacto (opcional):'),
          const SizedBox(height: 6),
          Container(
            width: 152,
            height: 29,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFD9D9D9)),
            ),
            child: Text(
              displayValue,
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                fontSize: 13,
                color: const Color(0xFF999A9D),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Número de contacto (opcional):'),
        const SizedBox(height: 6),
        SizedBox(
          width: 152,
          height: 29,
          child: TextField(
            keyboardType: TextInputType.phone,
            onChanged: data.onContactNumberChanged,
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(fontSize: 13),
            decoration: InputDecoration(
              hintText: '664-123-4567',
              hintStyle: AppTextStyles.ESC_Light_bodyMedium.copyWith(
                fontSize: 13,
                color: const Color(0xFFCCCCCC),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Color(0xFFCE1125)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
