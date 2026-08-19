/// Matches `public.user_role` in Postgres
enum AppUserRole {
  paramedico,
  medico,
  consultaExterna;

  static AppUserRole? fromDb(String? raw) {
    switch (raw) {
      case 'paramedico':
        return AppUserRole.paramedico;
      case 'medico':
        return AppUserRole.medico;
      case 'consulta_externa':
        return AppUserRole.consultaExterna;
      default:
        return null;
    }
  }

  String get dbValue {
    switch (this) {
      case AppUserRole.paramedico:
        return 'paramedico';
      case AppUserRole.medico:
        return 'medico';
      case AppUserRole.consultaExterna:
        return 'consulta_externa';
    }
  }

  /// Ruta principal tras login de personal. [consultaExterna] no usa sesión con correo
  /// (la consulta por código es pública en `/consulta-externa` sin `auth`)
  String get homePath {
    switch (this) {
      case AppUserRole.paramedico:
        return '/paramedico/home';
      case AppUserRole.medico:
        return '/medico';
      case AppUserRole.consultaExterna:
        return '/consulta-externa';
    }
  }
}
