/// Validaciones compartidas por los formularios de paciente del médico
/// (registro sin traslado y edición del paciente)
abstract final class MedicoPatientFormValidators {
  /// Mensaje de error o null si la fecha es válida / está vacía. La fecha es
  /// opcional y puede ir incompleta (p. ej. solo el año), pero lo que se
  /// escriba debe estar en rango y no puede quedar en el futuro.
  static String? birthDateError(
    String dayText,
    String monthText,
    String yearText, {
    DateTime? now,
  }) {
    final d = dayText.trim();
    final m = monthText.trim();
    final y = yearText.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) return null;

    final day = int.tryParse(d);
    final month = int.tryParse(m);
    final year = int.tryParse(y);
    final today = now ?? DateTime.now();

    if (d.isNotEmpty && (day == null || day < 1 || day > 31)) {
      return 'El día debe estar entre 1 y 31.';
    }
    if (m.isNotEmpty && (month == null || month < 1 || month > 12)) {
      return 'El mes debe estar entre 1 y 12.';
    }
    if (y.isNotEmpty) {
      if (y.length != 4 || year == null) {
        return 'Escribe el año con 4 dígitos.';
      }
      if (year < 1900 || year > today.year) {
        return 'El año debe estar entre 1900 y ${today.year}.';
      }
    }

    // El día debe existir en ese mes (29 de febrero solo en año bisiesto;
    // sin año se acepta)
    if (day != null && month != null) {
      final refYear = year ?? 2000;
      final daysInMonth = DateTime(refYear, month + 1, 0).day;
      if (day > daysInMonth) {
        return year == null
            ? 'Ese mes no tiene $day días.'
            : 'La fecha de nacimiento no existe.';
      }
    }

    // No puede ser posterior a hoy
    if (year != null && year == today.year) {
      if (month != null && month > today.month) {
        return 'La fecha de nacimiento no puede ser posterior a hoy.';
      }
      if (month != null &&
          day != null &&
          DateTime(year, month, day).isAfter(today)) {
        return 'La fecha de nacimiento no puede ser posterior a hoy.';
      }
    }
    return null;
  }

  /// Teléfono opcional: 10 dígitos (México / EE. UU.), u 11–12 con la lada
  /// del país (+1 / +52)
  /// Un signo vital escrito debe ser un número ("36,5" vale; "36..5" no).
  /// Los vacíos son opcionales.
  static bool isValidVital(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    return t.isEmpty || double.tryParse(t) != null;
  }

  static String? phoneError(String phone) {
    if (phone.trim().isEmpty) return null;
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final valid =
        digits.length == 10 ||
        (digits.length == 11 && digits.startsWith('1')) ||
        (digits.length == 12 && digits.startsWith('52'));
    if (!valid) {
      return 'El teléfono debe tener 10 dígitos (o la lada +52 / +1 antes).';
    }
    return null;
  }
}
