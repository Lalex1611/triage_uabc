import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_photo_data.dart';

class MedicoRegisterPhotoWidget extends StatelessWidget {
  final MedicoRegisterPhotoData data;

  const MedicoRegisterPhotoWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              'Capture la fotografía del paciente',
              style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildPhotoArea(),
        ],
      ),
    );
  }

  Widget _buildPhotoArea() {
    Widget leftBox = _buildCameraBox();
    if (data.photos.isNotEmpty) {
      leftBox = _buildFirstPhoto(data.photos.first, 0);
    }

    Widget rightBox = _buildAddImageBox();
    if (data.isReadOnly && data.photos.isEmpty) {
      rightBox = _buildReadOnlyEmptyBox();
    }

    return Row(
      children: [
        Expanded(child: leftBox),
        const SizedBox(width: 18),
        Expanded(child: rightBox),
      ],
    );
  }

  Widget _buildCameraBox() {
    VoidCallback? handler = data.onCameraTap;
    if (data.isReadOnly) {
      handler = null;
    }
    return GestureDetector(
      onTap: handler,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder, width: 1.2),
        ),
        child: Center(
          child: SvgPicture.asset(
            AppIcons.unicoPacienteCamera,
            width: 56,
            height: 56,
          ),
        ),
      ),
    );
  }

  Widget _buildFirstPhoto(String path, int index) {
    return Stack(
      children: [
        Container(
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder, width: 1.2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImage(path),
          ),
        ),
        if (!data.isReadOnly)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => data.onRemovePhotoTap(index),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.requiredAsterisk,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('asset:')) {
      return Image.asset(
        path.substring('asset:'.length),
        fit: BoxFit.cover,
        height: 130,
        width: double.infinity,
      );
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }

  Widget _buildAddImageBox() {
    return GestureDetector(
      onTap: data.onAddImageTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 44, color: Colors.black),
            const SizedBox(height: 6),
            Text(
              'Añadir\nimagen',
              textAlign: TextAlign.center,
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                color: Colors.black,
                fontSize: 13,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyEmptyBox() {
    return Container(
      height: 130,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.inputDisabledFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder, width: 1.2),
      ),
      child: Text(
        'Sin foto',
        style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
          color: AppColors.inactive,
          fontSize: 13,
        ),
      ),
    );
  }
}
