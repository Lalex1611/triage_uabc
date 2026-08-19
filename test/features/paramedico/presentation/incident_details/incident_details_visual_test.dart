import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_sorting_options.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_metadata_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_tab_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_card_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_list_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_triage_filter.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_triage_filters_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/incident_details_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/incident_details_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_details_list_tab_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_details_stats_tab_widget.dart';

/*
  COMANDO PARA PROBAR EL ENSAMBLE COMPLETO (SANDBOX):
  flutter run -t test/features/paramedico/presentation/incident_details/incident_details_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IncidentDetailsVisualTest(),
    ),
  );
}

class IncidentDetailsVisualTest extends StatefulWidget {
  const IncidentDetailsVisualTest({super.key});

  @override
  State<IncidentDetailsVisualTest> createState() =>
      _IncidentDetailsVisualTestState();
}

class _IncidentDetailsVisualTestState extends State<IncidentDetailsVisualTest> {
  IncidentTabType _activeTab = IncidentTabType.lista;
  PatientTriageFilter _activeFilter = PatientTriageFilter.todos;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showEditMock(BuildContext context, String currentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Editar Paciente',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Nombre o Alias'),
          controller: TextEditingController(text: currentName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listTab = _activeTab == IncidentTabType.lista
        ? IncidentDetailsListTab(
            searchController: _searchCtrl,
            onSearchChanged: (_) {},
            onRefresh: () async {},
            listHeaderData: PatientListHeaderData(
              patientCount: 8,
              sortOption: PatientSortOption.recent,
              onSortChanged: (_) {},
            ),
            triageFiltersData: PatientTriageFiltersData(
              activeFilter: _activeFilter,
              onFilterChanged: (filter) =>
                  setState(() => _activeFilter = filter),
            ),
            emptyMessage: '',
            patientCards: [
              PatientCardData(
                id: 'PAC-28320',
                number: 1,
                triageCategory: TriageCategory.rojo,
                name: 'Paciente Numero 1 - 12-Mar-2026 14:32 - Blvd. 2000',
                dateStr: '12/03/206 14:32:54',
                coordinates: '19.4326, -99.1332',
                status: PatientStatus.registrado,
                onEditTap: () => _showEditMock(context, 'Paciente Numero 1'),
              ),
              PatientCardData(
                id: 'PAC-28321',
                number: 2,
                triageCategory: TriageCategory.amarillo,
                name: 'Ramiro Hernández',
                dateStr: '12/03/206 14:32:54',
                coordinates: '19.4326, -99.1332',
                status: PatientStatus.enEspera,
                onEditTap: () => _showEditMock(context, 'Ramiro Hernández'),
              ),
            ],
          )
        : const IncidentDetailsStatsTab();

    return Theme(
      data: appTheme,
      child: IncidentDetailsPage(
        shellMode: IncidentDetailsShellMode.ready,
        headerData: IncidentHeaderData(
          id: 'INC-2026-001',
          createdAtLabel: '12-marzo-2026 14:32',
          title: '12-Mar-2026 14:32 - Blvd. 2000',
          latitude: 19.4326,
          longitude: -99.1332,
          gpsCoordinates: '19.43260, -99.13320',
          hasGps: true,
          isEditable: true,
          redCount: 1,
          yellowCount: 2,
          greenCount: 50,
          blackCount: 0,
          totalPatients: 8,
        ),
        metadataData: IncidentMetadataData(
          creatorName: 'Carlos Huerta',
          timeElapsedLabel: '28 minutos',
        ),
        tabSelectorData: IncidentTabSelectorData(
          activeTab: _activeTab,
          availableTabs: IncidentTabType.values,
          onTabChanged: (tab) => setState(() => _activeTab = tab),
        ),
        tabBody: listTab,
      ),
    );
  }
}
