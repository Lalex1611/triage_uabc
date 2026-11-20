import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Piezas visuales compartidas por los pasos del registro sin traslado
/// (mockups 07 y 08): colores, tarjeta, etiqueta, campo de texto y selector.
abstract final class MedicoWalkInColors {
  static const background = Color(0xFFEEF2F6);
  static const card = Colors.white;
  static const cardBorder = Color(0xFFE1E7ED);
  static const primary = Color(0xFF1C69AA);
  static const progressInactive = Color(0xFFC9D4DF);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF5C6670);
  static const placeholder = Color(0xFFA3ADB8);
  static const fieldBorder = Color(0xFFD3DBE3);
  static const fieldFill = Color(0xFFF8FAFC);
}

class MedicoWalkInCard extends StatelessWidget {
  const MedicoWalkInCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.fromLTRB(14, 16, 14, 18),
      decoration: BoxDecoration(
        color: MedicoWalkInColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MedicoWalkInColors.cardBorder),
      ),
      child: child,
    );
  }
}

class MedicoWalkInCardTitle extends StatelessWidget {
  const MedicoWalkInCardTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: MedicoWalkInColors.textPrimary,
      ),
    );
  }
}

class MedicoWalkInLabel extends StatelessWidget {
  const MedicoWalkInLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: MedicoWalkInColors.textPrimary,
        ),
      ),
    );
  }
}

InputDecoration medicoWalkInInputDecoration(String hint) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: c, width: w),
  );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: MedicoWalkInColors.placeholder,
      fontSize: 14,
    ),
    isDense: true,
    filled: true,
    fillColor: MedicoWalkInColors.fieldFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: border(MedicoWalkInColors.fieldBorder),
    enabledBorder: border(MedicoWalkInColors.fieldBorder),
    focusedBorder: border(MedicoWalkInColors.primary, 1.4),
  );
}

class MedicoWalkInTextField extends StatelessWidget {
  const MedicoWalkInTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLength,
    this.maxLines = 1,
    this.digitsOnly = false,
    this.decimal = false,
    this.textAlign = TextAlign.start,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters = const [],
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int maxLines;
  final bool digitsOnly;
  final bool decimal;
  final TextAlign textAlign;
  final TextCapitalization textCapitalization;

  /// Formateadores extra (se aplican después de los de [digitsOnly]/[decimal])
  final List<TextInputFormatter> inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType:
          keyboardType ??
          (decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : digitsOnly
              ? TextInputType.number
              : null),
      maxLines: maxLines,
      minLines: maxLines > 1 ? maxLines : null,
      textAlign: textAlign,
      textCapitalization: textCapitalization,
      inputFormatters: [
        if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
        if (decimal) FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ...inputFormatters,
      ],
      style: const TextStyle(
        fontSize: 14,
        color: MedicoWalkInColors.textPrimary,
      ),
      decoration: medicoWalkInInputDecoration(hint),
    );
  }
}

class MedicoWalkInDropdown<T> extends StatelessWidget {
  const MedicoWalkInDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.hint = 'Selecciona',
  });

  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: MedicoWalkInColors.textSecondary,
      ),
      decoration: medicoWalkInInputDecoration(hint),
      hint: Text(
        hint,
        style: const TextStyle(
          color: MedicoWalkInColors.placeholder,
          fontSize: 14,
        ),
      ),
      borderRadius: BorderRadius.circular(10),
      dropdownColor: Colors.white,
      style: const TextStyle(
        fontSize: 14,
        color: MedicoWalkInColors.textPrimary,
      ),
      items: [
        for (final item in items)
          DropdownMenuItem<T>(value: item, child: Text(labelOf(item))),
      ],
      onChanged: onChanged,
    );
  }
}

/// Impide escribir un número mayor que [max] (p. ej. día 32 o mes 13) y,
/// con [length] dígitos completos, un valor 0 (p. ej. "00").
class MedicoWalkInMaxValueFormatter extends TextInputFormatter {
  MedicoWalkInMaxValueFormatter({required this.max, required this.length});

  final int max;
  final int length;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    final value = int.tryParse(text);
    if (value == null || value > max) return oldValue;
    if (text.length >= length && value == 0) return oldValue;
    return newValue;
  }
}

/// Teléfono de México o EE. UU.: 10 dígitos, o hasta [maxDigits] con la lada
/// del país (+52 / +1). Acepta espacios, guiones, paréntesis y "+".
///
/// Solo revisa lo que se agrega: borrar siempre se permite, y un valor ya
/// guardado con otros caracteres (p. ej. "664 123 4567 (esposa)") se puede
/// seguir editando.
class MedicoWalkInPhoneFormatter extends TextInputFormatter {
  MedicoWalkInPhoneFormatter({this.maxDigits = 12});

  final int maxDigits;

  static final _notAllowed = RegExp(r'[^0-9 ()+\-]');
  static final _nonDigit = RegExp(r'[^0-9]');

  static int _digits(String s) => s.replaceAll(_nonDigit, '').length;
  static int _invalid(String s) => _notAllowed.allMatches(s).length;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final text = newValue.text;
    if (text.length <= oldText.length) return newValue;
    if (_invalid(text) > _invalid(oldText)) return oldValue;
    if (_digits(text) > maxDigits && _digits(text) > _digits(oldText)) {
      return oldValue;
    }
    return newValue;
  }
}
