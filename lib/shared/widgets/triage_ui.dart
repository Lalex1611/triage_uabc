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
export 'package:sistema_triage/core/theme/triage_tone.dart';

// Dominio compartido y su apariencia
export 'package:sistema_triage/core/theme/patient_lifecycle_status_style.dart';
export 'package:sistema_triage/core/theme/triage_level_style.dart';
export 'package:sistema_triage/shared/domain/patient_lifecycle_status.dart';
export 'package:sistema_triage/shared/domain/triage_level.dart';

// Componentes
export 'package:sistema_triage/shared/widgets/triage_alert_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_button_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_chip_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_data_row_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_field_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_header_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_incident_card_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_large_option_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_level_button_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_level_count_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_level_pill_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_map_markers_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_metric_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_patient_card_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_photo_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_search_bar_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_sheet_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_status_badge_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_steps_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_tabs_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_toast_widget.dart';
export 'package:sistema_triage/shared/widgets/triage_incident_marker_widget.dart';
