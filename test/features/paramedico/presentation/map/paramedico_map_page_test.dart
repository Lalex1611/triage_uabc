import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/incident_for_cards.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/paramedico_map_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/paramedico_map_page.dart';

final _card = IncidentForCards(
  id: 'INC-729',
  name_card: 'Accidente vehicular',
  dateTime: DateTime.now().subtract(const Duration(minutes: 18)),
  latitude: 32.53,
  longitude: -117.02,
  red: 3,
  yellow: 2,
  green: 3,
  black: 0,
  totalVictims: 8,
  isMine: true,
);

/// El mapa se queda cargando (sin teselas de red): se prueba el panel B03
Widget _page({
  double textScale = 1,
  List<String>? taps,
  bool fromPatient = false,
  double? distance = 1400,
}) {
  void tap(String name) => taps?.add(name);
  return MaterialApp(
    theme: ThemeData(extensions: const [TriageRoleTheme.paramedic]),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: ParamedicoMapPage(
        searchController: TextEditingController(),
        onSearchSubmitted: (_) {},
        mapController: MapController(),
        errorMessage: null,
        isLoading: true,
        mappableIncidents: const [],
        selectedIncidentId: 'a',
        userPosition: null,
        selectedCard: _card,
        selectedDistanceMeters: distance,
        onMapBackgroundTap: () {},
        onMapPositionChanged: (_, _) {},
        onPinTap: (_) {},
        onClearSelection: () => tap('cerrar'),
        onDirections: () => tap('google maps'),
        onReturnToPatient: fromPatient ? () => tap('paciente') : null,
        onLocateMe: () {},
        onOpenLayers: () {},
        onOpenIncidentDetail: () => tap('incidente'),
        filter: MapIncidentFilter.all,
        onFilterChanged: (_) {},
      ),
    ),
  );
}

void _screen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() async {
    final loader = FontLoader(TriageTextStyles.fontFamily);
    for (final weight in ['Regular', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Inter/Inter-$weight.ttf'));
    }
    await loader.load();
  });

  testWidgets('B03: el incidente elegido con "Cómo llegar" y "Abrir"', (
    tester,
  ) async {
    final taps = <String>[];
    await tester.pumpWidget(_page(taps: taps));

    expect(find.text('Accidente vehicular'), findsOneWidget);
    expect(find.text('32.5300, -117.0200 · a 1.4 km'), findsOneWidget);
    expect(find.text('Volver al paciente'), findsNothing);
    await tester.tap(find.text('Cómo llegar'));
    await tester.tap(find.text('Abrir incidente'));
    expect(taps, ['google maps', 'incidente']);
  });

  testWidgets('cerca se da en metros y sin GPS no se da distancia', (
    tester,
  ) async {
    await tester.pumpWidget(_page(distance: 850));
    expect(find.text('32.5300, -117.0200 · a 850 m'), findsOneWidget);

    await tester.pumpWidget(_page(distance: null));
    expect(find.text('32.5300, -117.0200'), findsOneWidget);
  });

  testWidgets('B03 desde la ficha de un paciente permite volver a ella', (
    tester,
  ) async {
    final taps = <String>[];
    await tester.pumpWidget(_page(taps: taps, fromPatient: true));
    await tester.tap(find.text('Volver al paciente'));
    expect(taps, ['paciente']);
  });

  testWidgets('arrastrar el panel hacia abajo suelta el incidente', (
    tester,
  ) async {
    final taps = <String>[];
    await tester.pumpWidget(_page(taps: taps));

    await tester.drag(find.text('Accidente vehicular'), const Offset(0, 400));
    // El cargador del mapa no para: se avanza el reloj en vez de esperar
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(taps, ['cerrar']);
  });

  testWidgets('un arrastre corto devuelve el panel a su sitio', (tester) async {
    final taps = <String>[];
    await tester.pumpWidget(_page(taps: taps));
    final top = tester.getTopLeft(find.text('Accidente vehicular')).dy;

    await tester.timedDrag(
      find.text('Accidente vehicular'),
      const Offset(0, 40),
      const Duration(seconds: 1),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(taps, isEmpty);
    expect(tester.getTopLeft(find.text('Accidente vehicular')).dy, top);
  });

  testWidgets('el lector de pantalla puede descartar el panel', (tester) async {
    final taps = <String>[];
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_page(taps: taps));

    tester.semantics.performAction(
      find.semantics.byAction(SemanticsAction.dismiss),
      SemanticsAction.dismiss,
    );
    expect(taps, ['cerrar']);
    semantics.dispose();
  });

  for (final width in [280.0, 393.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('B03 sin desbordes en $width con texto al ${scale * 100} %', (
        tester,
      ) async {
        _screen(tester, Size(width, 800));
        await tester.pumpWidget(_page(textScale: scale, fromPatient: true));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
