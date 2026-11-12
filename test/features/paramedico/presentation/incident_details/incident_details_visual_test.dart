import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_tab_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_card_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/map/map_patient_pin.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_triage_filter.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_triage_filters_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/incident_details_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/incident_details_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_details_list_tab_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_details_map_tab_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_details_photos_tab_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_details_stats_tab_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/patient_intake_flow.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/patient_intake_session.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

import '../patient_intake/fake_intake_repository.dart';

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
    final patients = [
      PatientCardData(
        id: 'PAC-28320',
        number: 1,
        triageLevel: TriageLevel.red,
        name: 'Paciente Numero 1 - 12-Mar-2026 14:32 - Blvd. 2000',
        dateStr: '12/03/206 14:32:54',
        status: PatientLifecycleStatus.waiting,
        onEditTap: () => _showEditMock(context, 'Paciente Numero 1'),
      ),
      PatientCardData(
        id: 'PAC-28321',
        number: 2,
        triageLevel: TriageLevel.yellow,
        name: 'Ramiro Hernández',
        dateStr: '12/03/206 14:32:54',
        status: PatientLifecycleStatus.waiting,
        onEditTap: () => _showEditMock(context, 'Ramiro Hernández'),
      ),
    ];

    final listTab = switch (_activeTab) {
      IncidentTabType.lista => IncidentDetailsListTab(
        onRefresh: () async {},
        triageFiltersData: PatientTriageFiltersData(
          activeFilter: _activeFilter,
          onFilterChanged: (filter) => setState(() => _activeFilter = filter),
        ),
        emptyMessage: '',
        patientCards: patients,
      ),
      IncidentTabType.mapa => IncidentDetailsMapTab(
        latitude: 32.5149,
        longitude: -117.0382,
        patients: [
          for (final (i, color) in const [
            'rojo',
            'rojo',
            'amarillo',
            'verde',
            'negro',
          ].indexed)
            MapPatientPin(
              id: 'p$i',
              incidentId: 'i',
              latitude: 32.5149 + i * 0.0001,
              longitude: -117.0382 + (i.isEven ? 0.0002 : -0.0002),
              triageColor: color,
            ),
        ],
      ),
      IncidentTabType.fotos => IncidentDetailsPhotosTab(
        description: 'Accidente en el libramiento Rosas Magallón.',
        photos: [
          for (var i = 0; i < 3; i++)
            NetworkImage('https://picsum.photos/seed/$i/900'),
        ],
        isEditable: true,
        onAddPhotoTap: () {},
        onRemovePhoto: (_) async => true,
        onSaveDescription: (_) async {},
      ),
      _ => IncidentDetailsStatsTab(
        patients: [
          for (final (i, status) in const [
            'en_espera',
            'trasladando',
            'recibido',
            'alta_medica',
          ].indexed)
            ParamedicoPatientRow(
              id: 'p$i',
              displayName: 'Paciente $i',
              triageColor: i.isEven ? 'rojo' : 'verde',
              status: status,
              createdAt: null,
              hospitalName: i == 0 ? null : 'Hospital General de Tijuana',
              wasRejected: i == 0,
            ),
        ],
      ),
    };

    return Theme(
      data: appTheme,
      child: IncidentDetailsPage(
        shellMode: IncidentDetailsShellMode.ready,
        headerData: IncidentHeaderData(
          id: 'INC-A1B2C3',
          title: 'Accidente vehicular',
          gpsCoordinates: '19.43260, -99.13320',
          authorLine: 'Carlos Huerta · hace 28 minutos · 14:32',
          redCount: 1,
          yellowCount: 1,
          greenCount: 0,
          blackCount: 0,
          totalPatients: patients.length,
        ),
        onBack: () {},
        onMoreTap: () {},
        onCloseIncidentTap: () {},
        // Registro con datos simulados: no guarda nada en Supabase
        onRegisterTap: () => startPatientIntake(
          context,
          incidentId: 'a1b2c3d4',
          subtitle: 'INC-A1B2C3 · Accidente vehicular',
          onPatientsChanged: () {},
          openGuidedStart: () async {},
          openExtendedRegistration: () async {},
          session: PatientIntakeSession(
            incidentId: 'a1b2c3d4',
            repository: FakeIntakeRepository(),
            currentPosition: () async => null,
            placeLabel: (_, _) async => 'Blvd. 2000',
          ),
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
