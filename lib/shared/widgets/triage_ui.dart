/// Sistema de diseño del rediseño en un solo import:
/// `import 'package:sistema_triage/shared/widgets/triage_ui.dart';`
///
/// Al crear un componente o token nuevo, exportarlo aquí
/// (lo verifica `test/shared/widgets/triage_ui_test.dart`).
library;

// Tokens, tema e íconos
export 'package:sistema_triage/core/constants/triage_icons.dart';
export 'package:sistema_triage/core/theme/triage_role_theme.dart';
export 'package:sistema_triage/core/theme/triage_tokens.dart';

// Dominio compartido y su apariencia
export 'package:sistema_triage/core/theme/patient_lifecycle_status_style.dart';
export 'package:sistema_triage/core/theme/triage_level_style.dart';
export 'package:sistema_triage/shared/domain/patient_lifecycle_status.dart';
export 'package:sistema_triage/shared/domain/triage_level.dart';

// Componentes
export 'package:sistema_triage/shared/widgets/triage_button_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_chip_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_search_bar_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_status_badge_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_tabs_widget.dart';
