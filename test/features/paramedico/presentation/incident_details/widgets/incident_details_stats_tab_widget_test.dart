import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/incident_details_view_mapper.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_action_buttons_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_details_stats_tab_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_more_actions_sheet_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

ParamedicoPatientRow _row({
  String color = 'rojo',
  String status = 'en_espera',
  String? hospital,
  int rejections = 0,
}) => ParamedicoPatientRow.fromJson({
  'id': 'abcdef',
  'triage_color': color,
  'status': status,
  'hospitals': hospital == null ? null : {'name': hospital},
  'medico_rejected_transfers': [
    for (var i = 0; i < rejections; i++) {'id': 'r$i'},
  ],
});

Widget _tab(List<ParamedicoPatientRow> patients, {double textScale = 1}) =>
    MaterialApp(
      builder: (context, navigator) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: navigator!,
      ),
      home: Scaffold(body: IncidentDetailsStatsTab(patients: patients)),
    );

String? _value(WidgetTester tester, String label) => tester
    .widget<TriageDataRow>(find.widgetWithText(TriageDataRow, label))
    .value;

void main() {
  testWidgets('métricas con los nombres de Figma', (tester) async {
    await tester.pumpWidget(
      _tab([_row(), _row(), _row(color: 'amarillo'), _row(color: 'negro')]),
    );
    for (final label in [
      'Inmediatos: 2',
      'Urgentes: 1',
      'Leves: 0',
      'Fallecidos: 1',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
  });

  testWidgets('naranja y azul cuentan igual que en el encabezado', (
    tester,
  ) async {
    await tester.pumpWidget(
      _tab([_row(color: 'naranja'), _row(color: 'azul')]),
    );
    expect(find.bySemanticsLabel('Urgentes: 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Leves: 1'), findsOneWidget);
  });

  testWidgets('el avance cuenta cada estado e incluye alta médica', (
    tester,
  ) async {
    await tester.pumpWidget(
      _tab([
        _row(),
        _row(status: 'trasladando'),
        _row(status: 'recibido'),
        _row(status: 'alta_medica'),
      ]),
    );
    expect(_value(tester, 'Registrados'), '4');
    expect(_value(tester, 'En espera'), '1');
    expect(_value(tester, 'Trasladando'), '1');
    expect(_value(tester, 'Recibidos en hospital'), '1');
    expect(_value(tester, 'Alta médica'), '1');
  });

  testWidgets('rechazados cuenta pacientes, no rechazos', (tester) async {
    await tester.pumpWidget(
      _tab([_row(rejections: 2), _row(rejections: 1), _row()]),
    );
    expect(_value(tester, 'Rechazados'), '2');
  });

  testWidgets('agrupa los hospitales destino con su cantidad', (tester) async {
    await tester.pumpWidget(
      _tab([
        _row(status: 'trasladando', hospital: 'General'),
        _row(status: 'recibido', hospital: 'General'),
        _row(status: 'trasladando', hospital: 'Cruz Roja'),
        _row(),
      ]),
    );
    expect(find.text('Hospitales destino'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('2 pacientes'), findsOneWidget);
    expect(find.text('1 paciente'), findsOneWidget);
  });

  testWidgets('sin hospitales oculta esa tarjeta', (tester) async {
    await tester.pumpWidget(_tab([_row()]));
    expect(find.text('Hospitales destino'), findsNothing);
  });

  testWidgets('sin pacientes muestra todo en cero', (tester) async {
    await tester.pumpWidget(_tab(const []));
    expect(_value(tester, 'Registrados'), '0');
    expect(tester.takeException(), isNull);
  });

  for (final (width, scale) in const [
    (280.0, 2.0),
    (393.0, 1.0),
    (800.0, 2.0),
  ]) {
    testWidgets('sin desbordes en $width al ${scale * 100} %', (tester) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _tab([
          _row(hospital: 'Cruz Roja Mexicana Delegación Tijuana'),
        ], textScale: scale),
      );
      expect(tester.takeException(), isNull);
    });
  }

  group('barra de acciones', () {
    Widget bar({required bool stats, VoidCallback? onClose}) => MaterialApp(
      home: Scaffold(
        body: IncidentActionButtons(
          isStatsTab: stats,
          onCloseIncidentTap: onClose,
        ),
      ),
    );

    testWidgets('en Resumen, quien puede cerrar ve el botón rojo', (
      tester,
    ) async {
      var closed = 0;
      await tester.pumpWidget(bar(stats: true, onClose: () => closed++));
      final button = tester.widget<TriageButton>(find.byType(TriageButton));
      expect(button.label, 'Cerrar incidente');
      expect(button.variant, TriageButtonVariant.danger);
      await tester.tap(find.byType(TriageButton));
      expect(closed, 1);
    });

    testWidgets('en Resumen, quien no puede cerrar ve Registrar', (
      tester,
    ) async {
      await tester.pumpWidget(bar(stats: true));
      expect(find.text('Registrar paciente'), findsOneWidget);
      expect(find.text('Cerrar incidente'), findsNothing);
    });

    testWidgets('en otras pestañas siempre es Registrar', (tester) async {
      await tester.pumpWidget(bar(stats: false, onClose: () {}));
      expect(find.text('Registrar paciente'), findsOneWidget);
    });
  });

  testWidgets('Más opciones omite Cerrar si no se puede', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showIncidentMoreActions(
                context,
                title: 'INC',
                onEditTitle: () {},
                onEditLocation: () {},
                onAddPhotos: () {},
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Editar título'), findsOneWidget);
    expect(find.text('Cerrar incidente'), findsNothing);
  });

  group('mensaje de cierre', () {
    String message(int count) => IncidentDetailsViewMapper.closeIncidentMessage(
      incidentId: 'a1b2c3d4',
      patientCount: count,
    );

    test('usa folio y número de pacientes', () {
      expect(
        message(8),
        'INC-A1B2C3 saldrá de la lista de activos. '
        'Los 8 pacientes conservan su historial y sus traslados en curso.',
      );
    });

    test('concuerda en singular y omite la frase sin pacientes', () {
      expect(message(1), contains('El paciente conserva su historial'));
      expect(message(0), 'INC-A1B2C3 saldrá de la lista de activos.');
    });
  });

  test('sin datos anidados, la fila no tiene hospital ni rechazos', () {
    final row = ParamedicoPatientRow.fromJson({'id': 'abcdef'});
    expect(row.hospitalName, isNull);
    expect(row.wasRejected, isFalse);
  });
}
