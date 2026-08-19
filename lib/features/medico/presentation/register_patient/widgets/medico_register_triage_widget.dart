import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_category.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_triage_data.dart';

class MedicoRegisterTriageWidget extends StatelessWidget {
  final MedicoRegisterTriageData data;

  const MedicoRegisterTriageWidget({super.key, required this.data});

  static const List<MedicoTriageCategory> _categories = [
    MedicoTriageCategory.rojo,
    MedicoTriageCategory.naranja,
    MedicoTriageCategory.amarillo,
    MedicoTriageCategory.verde,
    MedicoTriageCategory.azul,
  ];

  @override
  Widget build(BuildContext context) {
    final hPad = context.isCompactWidth ? 16.0 : 30.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTitleRow(hPad),
        const SizedBox(height: 14),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.requiredAsterisk,
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: _categories
                  .map((category) => _buildCategoryButton(category))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleRow(double hPad) {
    Widget editIcon = const SizedBox.shrink();
    if (data.onEditTap != null) {
      editIcon = Padding(
        padding: const EdgeInsets.only(left: 8),
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Row(
        children: [
          Expanded(
            child: Text(
              data.title,
              style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
                fontSize: 16,
                color: Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          editIcon,
        ],
      ),
    );
  }

  Widget _buildCategoryButton(MedicoTriageCategory category) {
    final isFirst = category == MedicoTriageCategory.rojo;
    final isLast = category == MedicoTriageCategory.azul;

    BorderRadius radius = BorderRadius.circular(5);
    if (isFirst) {
      radius = const BorderRadius.only(
        topLeft: Radius.circular(15),
        bottomLeft: Radius.circular(15),
        topRight: Radius.circular(5),
        bottomRight: Radius.circular(5),
      );
    }
    if (isLast) {
      radius = const BorderRadius.only(
        topLeft: Radius.circular(5),
        bottomLeft: Radius.circular(5),
        topRight: Radius.circular(15),
        bottomRight: Radius.circular(15),
      );
    }

    final isSelected = data.selectedCategory == category;
    final hasSelection = data.selectedCategory != null;

    var opacity = 1.0;
    if (hasSelection && !isSelected) {
      opacity = 0.45;
    }

    Border? selectedBorder;
    if (isSelected) {
      selectedBorder = Border.all(color: Colors.white, width: 2.5);
    }

    VoidCallback? handler = () => data.onCategorySelected(category);
    if (!data.isEditingEnabled) {
      handler = null;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: AspectRatio(
          aspectRatio: 1,
          child: GestureDetector(
            onTap: handler,
            child: AnimatedOpacity(
              opacity: opacity,
              duration: const Duration(milliseconds: 180),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: category.color,
                  borderRadius: radius,
                  border: selectedBorder,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
