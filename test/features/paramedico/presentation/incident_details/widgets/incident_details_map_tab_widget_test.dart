import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/map/map_patient_pin.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_details_map_tab_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

const _lat = 32.5149;
const _lng = -117.0382;

final _pins = [
  for (final (i, color) in const ['rojo', 'rojo', 'amarillo', 'negro'].indexed)
    MapPatientPin(
      id: 'p$i',
      incidentId: 'i',
      latitude: _lat + i * 0.00005,
      longitude: _lng,
      triageColor: color,
    ),
];

Widget _tab({
  double? latitude = _lat,
  double? longitude = _lng,
  List<MapPatientPin>? patients,
  ValueChanged<String>? onPatientTap,
  double textScale = 1,
}) => MaterialApp(
  builder: (context, navigator) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: navigator!,
  ),
  home: Scaffold(
    body: IncidentDetailsMapTab(
      latitude: latitude,
      longitude: longitude,
      patients: patients ?? _pins,
      onPatientTap: onPatientTap,
    ),
  ),
);

void _screen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

MapCamera _camera(WidgetTester tester) =>
    MapCamera.of(tester.element(find.byType(MarkerLayer)));

void main() {
  testWidgets('el mapa acepta gestos, salvo la rotación', (tester) async {
    await tester.pumpWidget(_tab());
    final flags = tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .options
        .interactionOptions
        .flags;
    expect(flags & InteractiveFlag.drag, isNonZero);
    expect(flags & InteractiveFlag.pinchZoom, isNonZero);
    expect(flags & InteractiveFlag.rotate, isZero);
  });

  testWidgets('arrastrar mueve el mapa', (tester) async {
    await tester.pumpWidget(_tab());
    await tester.pump();
    final before = _camera(tester).center;
    await tester.drag(find.byType(FlutterMap), const Offset(-120, 80));
    await tester.pumpAndSettle();
    expect(_camera(tester).center, isNot(before));
  });

  testWidgets('un marcador por paciente, que abre su ficha', (tester) async {
    String? opened;
    await tester.pumpWidget(_tab(onPatientTap: (id) => opened = id));
    await tester.pump();
    expect(find.byType(TriagePatientMarker), findsNWidgets(4));
    expect(
      tester
          .widgetList<TriagePatientMarker>(find.byType(TriagePatientMarker))
          .first
          .level,
      TriageLevel.red,
    );
    await tester.tap(
      find.byType(TriagePatientMarker).last,
      warnIfMissed: false,
    );
    expect(opened, 'p3');
  });

  testWidgets('la leyenda cuenta por nivel y no bloquea el mapa', (
    tester,
  ) async {
    await tester.pumpWidget(_tab());
    expect(
      find.bySemanticsLabel('Rojo: 2, Amarillo: 1, Verde: 0, Negro: 1'),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: find.text('2'), matching: find.byType(IgnorePointer)),
      findsWidgets,
    );
  });

  testWidgets('acercar, alejar y centrar mueven la cámara', (tester) async {
    await tester.pumpWidget(_tab());
    await tester.pump();
    final initial = _camera(tester).zoom;

    await tester.tap(find.byTooltip('Alejar'));
    await tester.pump();
    expect(_camera(tester).zoom, initial - 1);

    await tester.tap(find.byTooltip('Alejar'));
    await tester.tap(find.byTooltip('Acercar'));
    await tester.pump();
    expect(_camera(tester).zoom, initial - 1);

    await tester.tap(find.byTooltip('Centrar en el incidente'));
    await tester.pump();
    expect(_camera(tester).zoom, closeTo(initial, 0.01));
  });

  testWidgets('los controles tienen zona táctil de 48', (tester) async {
    await tester.pumpWidget(_tab());
    for (final tip in ['Centrar en el incidente', 'Acercar', 'Alejar']) {
      expect(tester.getSize(find.byTooltip(tip)), const Size(48, 48));
    }
  });

  testWidgets('el fondo lleva filtro y atribución', (tester) async {
    await tester.pumpWidget(_tab());
    expect(
      find.descendant(
        of: find.byType(ColorFiltered),
        matching: find.byType(TileLayer),
      ),
      findsOneWidget,
    );
    expect(find.text('© OpenStreetMap'), findsOneWidget);
  });

  testWidgets('sin pacientes marca el punto del incidente', (tester) async {
    await tester.pumpWidget(_tab(patients: const []));
    await tester.pump();
    expect(find.byType(TriagePatientMarker), findsNothing);
    expect(
      find.descendant(
        of: find.byType(MarkerLayer),
        matching: find.byType(TriageIcon),
      ),
      findsOneWidget,
    );
  });

  testWidgets('sin coordenadas explica el motivo y no pinta mapa', (
    tester,
  ) async {
    await tester.pumpWidget(_tab(latitude: null));
    expect(find.byType(FlutterMap), findsNothing);
    expect(find.textContaining('no tiene coordenadas'), findsOneWidget);
  });

  for (final (width, height, scale) in const [
    (280.0, 220.0, 2.0),
    (280.0, 500.0, 2.0),
    (393.0, 400.0, 1.0),
    (800.0, 400.0, 2.0),
  ]) {
    testWidgets('sin desbordes en $width×$height al ${scale * 100} %', (
      tester,
    ) async {
      _screen(tester, Size(width, height));
      await tester.pumpWidget(_tab(textScale: scale));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
