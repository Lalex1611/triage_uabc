import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_injury_type.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_description_data.dart';

// Sección de descripción del paciente: chips de tipo de lesión + área de texto libre
class PatientDescriptionWidget extends StatefulWidget {
  final PatientDescriptionData data;
  final TextEditingController? controller;

  const PatientDescriptionWidget({
    super.key,
    required this.data,
    this.controller,
  });

  @override
  State<PatientDescriptionWidget> createState() =>
      _PatientDescriptionWidgetState();
}

class _PatientDescriptionWidgetState extends State<PatientDescriptionWidget> {
  late final TextEditingController _internalController;

  TextEditingController get _effectiveController =>
      widget.controller ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = TextEditingController(
      text: widget.data.descriptionText,
    );
  }

  @override
  void didUpdateWidget(covariant PatientDescriptionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null) return;

    final nextText = widget.data.descriptionText;
    if (_internalController.text == nextText) return;

    _internalController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );
  }

  @override
  void dispose() {
    _internalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Descripción (opcional) :',
            style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
              fontSize: 15,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          /* Chips de lesiones en scroll horizontal */
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PatientInjuryType.values.map((injury) {
                final isSelected = widget.data.selectedInjuries.contains(
                  injury,
                );

                /* Si es solo lectura y no está seleccionada, no la mostramos */
                if (widget.data.isReadOnly && !isSelected) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: widget.data.isReadOnly
                        ? null
                        : () => widget.data.onInjuryToggled(injury),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFCE1125)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFCE1125)
                              : const Color(0xFFD9D9D9),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            injury.label,
                            style:
                                AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                                  fontSize: 13,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black,
                                ),
                          ),
                          const SizedBox(width: 4),
                          Builder(
                            builder: (context) {
                              IconData tagIcon = Icons.add;
                              Color tagIconColor = Colors.black;
                              if (isSelected) {
                                tagIcon = Icons.check;
                                tagIconColor = Colors.white;
                              }
                              return Icon(
                                tagIcon,
                                size: 14,
                                color: tagIconColor,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          /* Área de texto — igual a create_incident: h139, r15, D9D9D9 */
          if (widget.data.isReadOnly && widget.data.descriptionText.isEmpty)
            Container(
              height: 139,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFD9D9D9)),
              ),
              child: Text(
                'N/A',
                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF999A9D),
                ),
              ),
            )
          else
            Container(
              height: 139,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFD9D9D9)),
              ),
              child: TextField(
                controller: _effectiveController,
                maxLines: null,
                enabled: !widget.data.isReadOnly,
                keyboardType: TextInputType.multiline,
                onChanged: widget.data.onDescriptionChanged,
                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                  fontSize: 14,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                  isDense: true,
                  hintText: (() {
                    String? hintValue;
                    if (widget.data.isReadOnly) {
                      hintValue = widget.data.descriptionText;
                    }
                    return hintValue;
                  })(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
