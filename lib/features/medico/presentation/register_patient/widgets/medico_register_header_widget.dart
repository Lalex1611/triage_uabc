import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_header_data.dart';

class MedicoRegisterHeaderWidget extends StatefulWidget {
  final MedicoRegisterHeaderData data;

  const MedicoRegisterHeaderWidget({super.key, required this.data});

  @override
  State<MedicoRegisterHeaderWidget> createState() =>
      _MedicoRegisterHeaderWidgetState();
}

class _MedicoRegisterHeaderWidgetState
    extends State<MedicoRegisterHeaderWidget> {
  late TextEditingController _nameController;

  MedicoRegisterHeaderData get data => widget.data;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: data.patientName);
  }

  @override
  void didUpdateWidget(covariant MedicoRegisterHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (data.patientName != oldWidget.data.patientName &&
        data.patientName != _nameController.text) {
      _nameController.text = data.patientName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryMedico,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatientId(),
          const SizedBox(height: 4),
          _buildNameRow(),
          const SizedBox(height: 14),
          _buildBottomRow(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPatientId() {
    return Text(
      data.patientId,
      style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
        fontSize: 11,
        color: Colors.white,
      ),
    );
  }

  Widget _buildNameRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _buildNameField()),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: data.onEditNameTap,
          child: SvgPicture.asset(
            AppIcons.unicoPacienteEdit,
            width: 24,
            height: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    if (data.isReadOnly) {
      return Text(
        data.patientName,
        style: AppTextStyles.ESC_Light_displayLarge.copyWith(
          color: Colors.white,
          fontSize: 30,
          height: 1.1,
        ),
      );
    }

    Widget asteriskWidget = const SizedBox.shrink();
    if (data.showAsterisk) {
      asteriskWidget = Padding(
        padding: const EdgeInsets.only(top: 4, left: 4),
        child: Text(
          '*',
          style: AppTextStyles.ESC_Bold_titleLarge.copyWith(
            color: AppColors.requiredAsterisk,
            fontSize: 22,
            height: 1,
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: TextField(
            style: AppTextStyles.ESC_Light_displayLarge.copyWith(
              color: Colors.white,
              fontSize: 30,
              height: 1.1,
            ),
            decoration: InputDecoration(
              hintText: 'Nombre...',
              hintStyle: AppTextStyles.ESC_Light_displayLarge.copyWith(
                color: Colors.white,
                fontSize: 30,
                height: 1.1,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            controller: _nameController,
            onChanged: data.onNameChanged,
          ),
        ),
        asteriskWidget,
      ],
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [_buildRegistrationDate(), _buildQrCard()],
    );
  }

  Widget _buildRegistrationDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha de registro:',
          style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SvgPicture.asset(
              AppIcons.medicoRegisterPatientClock,
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              data.registrationDateTime,
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: data.onEditDateTap,
              child: Text(
                'Editar',
                style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQrCard() {
    final contentColor = data.isQrEnabled
        ? Colors.black
        : const Color(0xFF6F747A);
    return GestureDetector(
      onTap: data.onGenerateQrTap,
      child: Container(
        width: 78,
        height: 56,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: data.isQrEnabled
              ? Colors.white
              : Colors.white.withValues(alpha: 0.62),
          border: data.isQrEnabled
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.48)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              data.qrButtonLabel,
              textAlign: TextAlign.center,
              style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                color: contentColor,
                fontSize: 7,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 2),
            SvgPicture.asset(
              AppIcons.unicoPacienteQr,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(contentColor, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }
}
