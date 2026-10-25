/// Formato compartido por la entrada manual y la consulta por codigo.
class ConsultaCode {
  ConsultaCode._();

  static const int length = 6;
  static final _separators = RegExp(r'[\s-]');
  static final _characters = RegExp(r'^[A-Z0-9]*$');

  static String normalize(String value) =>
      value.toUpperCase().replaceAll(_separators, '');

  static bool hasValidCharacters(String value) => _characters.hasMatch(value);

  static bool isValid(String value) =>
      value.length == length && hasValidCharacters(value);
}
