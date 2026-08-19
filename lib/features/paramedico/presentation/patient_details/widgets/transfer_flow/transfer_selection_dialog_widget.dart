import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

// Dialogo de seleccion para pasos del traslado
class TransferSelectionDialog extends StatelessWidget {
  final String title;
  final List<String> options;
  final Function(String) onOptionSelected;
  final VoidCallback onBackTap;
  final String? editOption; // Si hay una opción con lapicito (ej. "Otra")
  final VoidCallback? onEditOptionTapped;

  const TransferSelectionDialog({
    super.key,
    required this.title,
    required this.options,
    required this.onOptionSelected,
    required this.onBackTap,
    this.editOption,
    this.onEditOptionTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Rojo
            Container(
              color: const Color(0xFFCE1125),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onBackTap,
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24), // Para balancear el back button
                ],
              ),
            ),
            // Lista de Opciones
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Color(0xFFE0E0E0)),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isEditOption = editOption == option;
                  return InkWell(
                    onTap: () => onOptionSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            option,
                            style:
                                AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                          ),
                          if (isEditOption) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: onEditOptionTapped,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: SvgPicture.asset(
                                  AppIcons.paramedicoIncidenteEdit,
                                  width: 16,
                                  height: 16,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFFCE1125),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
