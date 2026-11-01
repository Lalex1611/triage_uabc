import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

/// Campo de texto del rediseño (Figma "TRIAGE/Campo", tipos Texto y Área)
///
/// Etiqueta siempre visible encima de la caja (no desaparece al escribir) y
/// asociada al campo para el lector de pantalla. Es un [TextFormField]: dentro
/// de un `Form` valida con [validator]; fuera de él, [errorText] muestra el
/// error. Al enfocarse, el borde toma el color del rol activo.
/// [TriageField.area] es la versión de varias líneas: arranca en tres y crece
/// con el texto. Para el tipo Selección, ver [TriageSelectField].
class TriageField extends StatelessWidget {
  const TriageField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
  }) : _area = false;

  const TriageField.area({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.errorText,
    this.textInputAction,
    this.enabled = true,
  }) : keyboardType = TextInputType.multiline,
       obscureText = false,
       _area = true;

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool _area;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        onChanged: onChanged,
        validator: validator,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        enabled: enabled,
        minLines: _area ? 3 : null,
        maxLines: _area ? null : 1,
        style: _valueStyle,
        decoration: _decoration(
          context,
          hint: hint,
          errorText: errorText,
          enabled: enabled,
        ),
      ),
    );
  }
}

/// Campo de selección del rediseño (Figma "TRIAGE/Campo", tipo Selección)
///
/// Mismo aspecto que [TriageField] con un chevron; al tocarlo despliega
/// [options], mostradas con [optionLabel]. Es un `FormField`: valida con
/// [validator] dentro de un `Form`.
class TriageSelectField<T> extends StatelessWidget {
  const TriageSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.optionLabel,
    this.value,
    this.onChanged,
    this.hint,
    this.validator,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final List<T> options;
  final String Function(T option) optionLabel;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final FormFieldValidator<T>? validator;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: [
          for (final option in options)
            DropdownMenuItem(value: option, child: Text(optionLabel(option))),
        ],
        onChanged: enabled ? onChanged : null,
        validator: validator,
        isExpanded: true,
        style: _valueStyle,
        dropdownColor: TriageColors.surface,
        borderRadius: BorderRadius.circular(TriageRadii.md),
        icon: const TriageIcon(
          TriageIcons.chevronDown,
          size: TriageSizes.icon,
          color: TriageColors.textTertiary,
        ),
        decoration: _decoration(
          context,
          hint: hint,
          errorText: errorText,
          enabled: enabled,
        ),
      ),
    );
  }
}

final _valueStyle = TriageTextStyles.bodyMedium.copyWith(
  color: TriageColors.textPrimary,
);

/// Caja común de [TriageField] y [TriageSelectField]
InputDecoration _decoration(
  BuildContext context, {
  required String? hint,
  required String? errorText,
  required bool enabled,
}) {
  OutlineInputBorder border(Color color, [double width = TriageSizes.stroke]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(TriageRadii.md),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    // Figma usa texto terciario (3.05:1); el secundario llega a 4.5:1
    hintStyle: TriageTextStyles.bodyMedium.copyWith(
      color: TriageColors.textSecondary,
    ),
    errorText: errorText,
    errorMaxLines: 3,
    errorStyle: TriageTextStyles.bodySmall.copyWith(color: TriageColors.danger),
    filled: true,
    fillColor: enabled ? TriageColors.surface : TriageColors.sunken,
    // Sin alto fijo: el contenido y el padding dan ≥ 48 y crece con el texto
    contentPadding: const EdgeInsets.symmetric(
      horizontal: TriageSpacing.lg,
      vertical: TriageSpacing.md,
    ),
    enabledBorder: border(TriageColors.borderMedium),
    disabledBorder: border(TriageColors.borderSubtle),
    focusedBorder: border(context.triageRole.accent, TriageSizes.strokeStrong),
    errorBorder: border(TriageColors.danger),
    focusedErrorBorder: border(TriageColors.danger, TriageSizes.strokeStrong),
  );
}

/// Etiqueta visible sobre el campo, unida a él en un solo nodo semántico
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TriageTextStyles.labelMedium.copyWith(
              color: TriageColors.textSecondary,
            ),
          ),
          const SizedBox(height: TriageSpacing.sm),
          child,
        ],
      ),
    );
  }
}
