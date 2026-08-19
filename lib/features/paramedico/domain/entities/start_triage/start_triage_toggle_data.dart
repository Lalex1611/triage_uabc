import 'package:sistema_triage/features/paramedico/domain/constants/start_triage_tab_options.dart';

class StartTriageToggleData {
  final StartTriageTabOption activeTab;
  final Function(StartTriageTabOption) onTabChanged;

  StartTriageToggleData({required this.activeTab, required this.onTabChanged});
}
