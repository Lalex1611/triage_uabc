import 'package:sistema_triage/core/constants/app_icons.dart';

enum AuthRoleType {
  none,
  paramedico,
  medico;

  String get logoAsset {
    switch (this) {
      case AuthRoleType.paramedico:
        return AppIcons.logoParamedico;
      case AuthRoleType.medico:
        return AppIcons.logoMedico;
      case AuthRoleType.none:
        return AppIcons.logoBase;
    }
  }
}
