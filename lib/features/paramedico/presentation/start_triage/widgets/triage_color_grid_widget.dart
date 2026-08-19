import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/triage_color_grid_data.dart';

class TriageColorGridWidget extends StatelessWidget {
  final TriageColorGridData data;

  const TriageColorGridWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final hPad = context.horizontalPadding;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Clasifica al paciente:',
            style: AppTextStyles.ESC_SemiBold_titleMedium.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Asigna el color del TRIAGE directamente.',
            style: AppTextStyles.ESC_Thin_bodyLarge.copyWith(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final gap = context.isCompactWidth ? 12.0 : 20.0;
              final squareW = ((constraints.maxWidth - gap) / 2)
                  .clamp(100.0, 143.16);
              final squareH = squareW * (137.7 / 143.16);

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildColorSquare(
                        context,
                        data.categories[0],
                        data.onColorSelected,
                        squareW,
                        squareH,
                      ),
                      SizedBox(width: gap),
                      _buildColorSquare(
                        context,
                        data.categories[1],
                        data.onColorSelected,
                        squareW,
                        squareH,
                      ),
                    ],
                  ),
                  SizedBox(height: gap),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildColorSquare(
                        context,
                        data.categories[2],
                        data.onColorSelected,
                        squareW,
                        squareH,
                      ),
                      SizedBox(width: gap),
                      _buildColorSquare(
                        context,
                        data.categories[3],
                        data.onColorSelected,
                        squareW,
                        squareH,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorSquare(
    BuildContext context,
    TriageCategory category,
    void Function(TriageCategory) onSelected,
    double width,
    double height,
  ) {
    final isBlack = category == TriageCategory.negro;
    return GestureDetector(
      onTap: () => onSelected(category),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: category.color,
          borderRadius: BorderRadius.circular(19.44),
          border: isBlack
              ? Border.all(color: Colors.white, width: 0.6)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          category.label.capitalize(),
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            color: Colors.white,
            fontSize: 20.4 * (width / 143.16),
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
