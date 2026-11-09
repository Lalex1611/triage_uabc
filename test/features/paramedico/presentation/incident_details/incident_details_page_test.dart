import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/emergency_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_triage_filter.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_tab_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_card_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_triage_filters_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/incident_details_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/incident_details_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/incident_details_view_mapper.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_details_list_tab_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_more_actions_sheet_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

IncidentHeaderData _header({bool isClosed = false}) => IncidentHeaderData(
  id: 'INC-A1B2C3',
  title: 'Accidente vehicular',
  gpsCoordinates: '32.53000, -117.02000',
  authorLine: 'Carlos Vera · hace 18 minutos · 14:32',
  isClosed: isClosed,
  redCount: 3,
  yellowCount: 2,
  greenCount: 3,
  blackCount: 0,
  totalPatients: 8,
);

List<PatientCardData> _patients(int count) => [
  for (var i = 0; i < count; i++)
    PatientCardData(
      id: 'PAC-20$i',
      number: i + 1,
      triageLevel: TriageLevel.red,
      name: 'Paciente $i',
      dateStr: '14:34',
      note: 'hemorragia',
      status: PatientLifecycleStatus.transferring,
    ),
];

Widget _page({
  IncidentHeaderData? header,
  IncidentTabType activeTab = IncidentTabType.lista,
  ValueChanged<IncidentTabType>? onTabChanged,
  VoidCallback? onMoreTap,
  VoidCallback? onBack,
  ValueChanged<PatientTriageFilter>? onFilterChanged,
  List<PatientCardData>? patients,
  double textScale = 1,
}) => MaterialApp(
  builder: (context, navigator) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: navigator!,
  ),
  home: IncidentDetailsPage(
    shellMode: IncidentDetailsShellMode.ready,
    headerData: header ?? _header(),
    onBack: onBack ?? () {},
    onMoreTap: onMoreTap,
    tabSelectorData: IncidentTabSelectorData(
      activeTab: activeTab,
      availableTabs: IncidentTabType.values,
      onTabChanged: onTabChanged ?? (_) {},
    ),
    tabBody: IncidentDetailsListTab(
      onRefresh: () async {},
      triageFiltersData: PatientTriageFiltersData(
        activeFilter: PatientTriageFilter.todos,
        onFilterChanged: onFilterChanged ?? (_) {},
      ),
      emptyMessage: '',
      patientCards: patients ?? _patients(4),
    ),
  ),
);

void _screen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader(TriageTextStyles.fontFamily);
    for (final weight in ['Regular', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Inter/Inter-$weight.ttf'));
    }
    await loader.load();
  });

  group('armazón', () {
    testWidgets('muestra encabezado, datos, pestañas y acción', (tester) async {
      _screen(tester, const Size(393, 852));
      await tester.pumpWidget(_page());
      expect(find.text('INC-A1B2C3'), findsOneWidget);
      expect(find.text('ACTIVO'), findsOneWidget);
      expect(find.text('Accidente vehicular'), findsOneWidget);
      expect(find.text('32.53000, -117.02000'), findsOneWidget);
      expect(find.text('8 pacientes'), findsOneWidget);
      for (final label in ['Pacientes', 'Mapa', 'Detalles', 'Resumen']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Registrar paciente'), findsOneWidget);
    });

    testWidgets('incidente cerrado muestra su insignia', (tester) async {
      _screen(tester, const Size(393, 852));
      await tester.pumpWidget(_page(header: _header(isClosed: true)));
      expect(find.text('CERRADO'), findsOneWidget);
      expect(find.text('ACTIVO'), findsNothing);
    });

    testWidgets('el contenido llega hasta la barra de acciones', (
      tester,
    ) async {
      _screen(tester, const Size(393, 852));
      await tester.pumpWidget(_page());
      expect(
        tester.getBottomLeft(find.byType(IncidentDetailsListTab)).dy,
        tester.getTopLeft(find.byType(TriageActionBar)).dy,
      );
    });

    testWidgets('los datos se limitan y la lista conserva su espacio', (
      tester,
    ) async {
      _screen(tester, const Size(320, 568));
      await tester.pumpWidget(_page(textScale: 2));
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(IncidentDetailsListTab)).height,
        greaterThan(0),
      );
    });

    for (final width in [280.0, 320.0, 393.0, 800.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('sin desbordes en $width con texto al ${scale * 100} %', (
          tester,
        ) async {
          _screen(tester, Size(width, 700));
          await tester.pumpWidget(_page(textScale: scale, onMoreTap: () {}));
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('interacción', () {
    testWidgets('las pestañas avisan cuál se eligió', (tester) async {
      _screen(tester, const Size(393, 852));
      IncidentTabType? chosen;
      await tester.pumpWidget(_page(onTabChanged: (tab) => chosen = tab));
      await tester.tap(find.text('Resumen'));
      expect(chosen, IncidentTabType.estadisticas);
    });

    testWidgets('los filtros usan chips y responden', (tester) async {
      _screen(tester, const Size(393, 852));
      PatientTriageFilter? chosen;
      await tester.pumpWidget(_page(onFilterChanged: (f) => chosen = f));
      expect(find.byType(TriageChip), findsNWidgets(5));
      expect(
        tester.getTopLeft(find.text('Rojo')).dx,
        lessThan(tester.getTopLeft(find.text('Amarillo')).dx),
      );
      await tester.tap(find.text('Rojo'));
      expect(chosen, PatientTriageFilter.rojo);
    });

    testWidgets('regresar y más opciones llaman a su acción', (tester) async {
      _screen(tester, const Size(393, 852));
      final calls = <String>[];
      await tester.pumpWidget(
        _page(
          onBack: () => calls.add('atrás'),
          onMoreTap: () => calls.add('más'),
        ),
      );
      await tester.tap(find.byTooltip('Regresar'));
      await tester.tap(find.byTooltip('Más opciones'));
      expect(calls, ['atrás', 'más']);
    });

    testWidgets('sin onMoreTap no aparece más opciones', (tester) async {
      _screen(tester, const Size(393, 852));
      await tester.pumpWidget(_page());
      expect(find.byTooltip('Más opciones'), findsNothing);
    });

    testWidgets('la tarjeta une código, hora y nota', (tester) async {
      _screen(tester, const Size(393, 852));
      await tester.pumpWidget(_page());
      expect(find.text('PAC-200 · 14:34 · hemorragia'), findsOneWidget);
    });
  });

  group('más opciones', () {
    Widget opener(List<String> calls) => MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showIncidentMoreActions(
              context,
              title: 'INC-A1B2C3 · Accidente vehicular',
              onEditTitle: () => calls.add('título'),
              onEditLocation: () => calls.add('ubicación'),
              onAddPhotos: () => calls.add('fotos'),
              onCloseIncident: () => calls.add('cerrar'),
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );

    for (final (label, expected) in const [
      ('Editar título', 'título'),
      ('Editar ubicación', 'ubicación'),
      ('Añadir fotografías', 'fotos'),
      ('Cerrar incidente', 'cerrar'),
    ]) {
      testWidgets('$label cierra la hoja y ejecuta la acción', (tester) async {
        final calls = <String>[];
        await tester.pumpWidget(opener(calls));
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(calls, [expected]);
        expect(find.byType(TriageSheet), findsNothing);
      });
    }

    testWidgets('el botón Cerrar solo cierra la hoja', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(opener(calls));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      expect(find.byType(TriageSheet), findsNothing);
    });
  });

  group('datos', () {
    ParamedicoIncidentSummary incident({
      String type = 'accidente_vehicular',
      String status = 'activo',
    }) => ParamedicoIncidentSummary(
      id: 'a1b2c3d4-0000',
      generatedTitle: '18-marzo-2026 14:32-Blvd. 2000',
      emergencyType: type,
      createdAt: DateTime(2026, 3, 18, 14, 32),
      createdBy: 'u1',
      status: status,
      latitude: 32.53,
      longitude: -117.02,
    );

    test('el título es el tipo de emergencia, no el título generado', () {
      final data = IncidentDetailsViewMapper.headerData(
        incident: incident(),
        patients: const [],
        creatorName: 'Carlos Vera',
      );
      expect(data.title, 'Accidente vehicular');
      expect(data.id, 'INC-A1B2C3');
      expect(data.authorLine, startsWith('Carlos Vera · hace'));
      expect(data.authorLine, endsWith('· 14:32'));
      expect(data.isClosed, isFalse);
    });

    test('sin autor, la línea no empieza con separador', () {
      final data = IncidentDetailsViewMapper.headerData(
        incident: incident(),
        patients: const [],
        creatorName: null,
      );
      expect(data.authorLine, startsWith('hace'));
    });

    test('detecta el incidente cerrado desde su estado', () {
      final closed = ParamedicoIncidentSummary.fromJson({
        'id': 'x',
        'status': 'cerrado',
        'emergency_type': 'otro',
      });
      expect(
        IncidentDetailsViewMapper.headerData(
          incident: closed,
          patients: const [],
          creatorName: null,
        ).isClosed,
        isTrue,
      );
    });

    test('sin coincidencias, el mensaje solo habla del filtro', () {
      expect(
        IncidentDetailsViewMapper.listEmptyMessage(
          allPatients: [
            ParamedicoPatientRow.fromJson({'id': 'abcdef'}),
          ],
          filtered: const [],
        ),
        'No hay pacientes con ese filtro.',
      );
    });

    test('nameFor da nombre también a tipos fuera del catálogo', () {
      expect(EmergencyCatalog.nameFor('derrumbe'), 'Derrumbe');
      expect(EmergencyCatalog.nameFor('violencia'), 'Violencia');
      expect(EmergencyCatalog.nameFor('caso_nuevo'), 'Caso nuevo');
      expect(EmergencyCatalog.nameFor(''), 'Otro');
    });

    test('la nota es la primera línea, salvo si ya es el nombre', () {
      Map<String, dynamic> row(String? name, String? notes) => {
        'id': 'abcdef',
        'display_name': name,
        'descriptive_notes': notes,
      };
      expect(
        ParamedicoPatientRow.fromJson(row('Ana', 'hemorragia\nleve')).note,
        'hemorragia',
      );
      expect(ParamedicoPatientRow.fromJson(row('Ana', '  ')).note, isNull);
      final namedByNote = ParamedicoPatientRow.fromJson(row(null, 'contusión'));
      expect(namedByNote.displayName, 'contusión');
      expect(namedByNote.note, isNull);
    });
  });
}
