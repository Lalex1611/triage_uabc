import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/incident_location_map_dialog_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

const _start = LatLng(32.4836, -116.9330);

/// Búsquedas de dirección que el test responde cuando quiere
class _Lookups {
  final calls = <({double lat, double lng, Completer<String?> answer})>[];

  Future<String?> call(double lat, double lng) {
    final answer = Completer<String?>();
    calls.add((lat: lat, lng: lng, answer: answer));
    return answer.future;
  }
}

/// Abre el modal con un botón y pasa lo que devuelve a [onResult]
Widget _app(
  Widget dialog, {
  void Function(LatLng?)? onResult,
  double textScale = 1,
  Size size = const Size(390, 844),
}) {
  return MaterialApp(
    theme: ThemeData(extensions: const [TriageRoleTheme.paramedic]),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(size: size, textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            final result = await showDialog<LatLng>(
              context: context,
              builder: (_) => dialog,
            );
            onResult?.call(result);
          },
          child: const Text('abrir'),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra la B06 con la dirección conocida, sin volver a '
      'buscarla', (tester) async {
    final lookups = _Lookups();
    await tester.pumpWidget(
      _app(
        IncidentLocationMapDialog(
          initial: _start,
          placeLabel: 'Blvd. Díaz Ordaz 1540',
          placeLookup: lookups.call,
        ),
      ),
    );
    await _open(tester);

    expect(find.text('Mueve el mapa para ajustar'), findsOneWidget);
    expect(find.text('El pin marca el punto del incidente'), findsOneWidget);
    expect(find.text('Blvd. Díaz Ordaz 1540'), findsOneWidget);
    expect(find.text('32.4836, -116.9330'), findsOneWidget);
    expect(find.byType(TriagePlacePin), findsOneWidget);
    expect(find.byTooltip('Centrar en mi ubicación'), findsOneWidget);
    expect(find.text('Confirmar esta ubicación'), findsOneWidget);
    expect(lookups.calls, isEmpty);
  });

  testWidgets('sin dirección conocida la busca al abrir', (tester) async {
    final lookups = _Lookups();
    await tester.pumpWidget(
      _app(
        IncidentLocationMapDialog(initial: _start, placeLookup: lookups.call),
      ),
    );
    await _open(tester);

    expect(find.text('Buscando dirección…'), findsOneWidget);
    expect(lookups.calls.single.lat, _start.latitude);

    lookups.calls.single.answer.complete('Blvd. Díaz Ordaz 1540');
    await tester.pumpAndSettle();
    expect(find.text('Blvd. Díaz Ordaz 1540'), findsOneWidget);
  });

  testWidgets('confirmar devuelve el punto bajo el pin', (tester) async {
    LatLng? result;
    await tester.pumpWidget(
      _app(
        IncidentLocationMapDialog(
          initial: _start,
          placeLabel: 'Blvd. Díaz Ordaz 1540',
          placeLookup: (_, _) async => null,
        ),
        onResult: (r) => result = r,
      ),
    );
    await _open(tester);

    await tester.tap(find.text('Confirmar esta ubicación'));
    await tester.pumpAndSettle();
    expect(result!.latitude, closeTo(_start.latitude, 1e-6));
    expect(result!.longitude, closeTo(_start.longitude, 1e-6));
  });

  testWidgets('al mover el mapa busca la dirección del punto nuevo cuando se '
      'suelta, y la respuesta del punto anterior no la pisa', (tester) async {
    final lookups = _Lookups();
    LatLng? result;
    await tester.pumpWidget(
      _app(
        IncidentLocationMapDialog(initial: _start, placeLookup: lookups.call),
        onResult: (r) => result = r,
      ),
    );
    await _open(tester);
    final first = lookups.calls.single;

    await tester.drag(find.byType(FlutterMap), const Offset(-120, 80));
    await tester.pump();
    expect(find.text('Buscando dirección…'), findsOneWidget);
    expect(find.text('32.4836, -116.9330'), findsNothing);
    // La inercia del arrastre sigue moviendo el mapa: aún no se busca
    await tester.pumpAndSettle();
    expect(lookups.calls, hasLength(1), reason: 'espera a que se suelte');

    await tester.pump(const Duration(seconds: 1));
    expect(lookups.calls, hasLength(2));
    final moved = lookups.calls.last;
    expect(moved.lat, isNot(closeTo(_start.latitude, 1e-6)));

    moved.answer.complete('Vía Rápida Oriente');
    first.answer.complete('Blvd. Díaz Ordaz 1540');
    await tester.pumpAndSettle();
    expect(find.text('Vía Rápida Oriente'), findsOneWidget);
    expect(find.text('Blvd. Díaz Ordaz 1540'), findsNothing);

    await tester.tap(find.text('Confirmar esta ubicación'));
    await tester.pumpAndSettle();
    expect(result!.latitude, closeTo(moved.lat, 1e-9));
    expect(result!.longitude, closeTo(moved.lng, 1e-9));
  });

  testWidgets('una cámara con centro no válido no cambia el punto elegido', (
    tester,
  ) async {
    final lookups = _Lookups();
    LatLng? result;
    await tester.pumpWidget(
      _app(
        IncidentLocationMapDialog(
          initial: _start,
          placeLabel: 'Blvd. Díaz Ordaz 1540',
          placeLookup: lookups.call,
        ),
        onResult: (r) => result = r,
      ),
    );
    await _open(tester);

    final options = tester.widget<FlutterMap>(find.byType(FlutterMap)).options;
    options.onPositionChanged!(
      MapCamera(
        crs: const Epsg3857(),
        center: const LatLng(double.nan, double.nan),
        zoom: 16,
        rotation: 0,
        nonRotatedSize: const Size(300, 300),
      ),
      true,
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('NaN, NaN'), findsNothing);
    expect(find.text('32.4836, -116.9330'), findsOneWidget);
    expect(lookups.calls, isEmpty);

    await tester.tap(find.text('Confirmar esta ubicación'));
    await tester.pumpAndSettle();
    expect(result!.latitude, closeTo(_start.latitude, 1e-6));
  });

  testWidgets('volver cierra sin devolver punto', (tester) async {
    var closed = false;
    LatLng? result = _start;
    await tester.pumpWidget(
      _app(
        IncidentLocationMapDialog(
          initial: _start,
          placeLabel: 'Blvd. Díaz Ordaz 1540',
          placeLookup: (_, _) async => null,
        ),
        onResult: (r) {
          closed = true;
          result = r;
        },
      ),
    );
    await _open(tester);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('solo ver: su título, mapa fijo, sin «Centrar» ni confirmar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        IncidentLocationMapDialog(
          initial: _start,
          readOnly: true,
          title: 'Ubicación del paciente',
          placeLookup: (_, _) async => 'Blvd. Díaz Ordaz 1540',
        ),
      ),
    );
    await _open(tester);

    expect(find.text('Ubicación del paciente'), findsOneWidget);
    expect(
      tester.widget<TriagePlacePin>(find.byType(TriagePlacePin)).semanticLabel,
      'Ubicación del paciente',
    );
    expect(find.text('Mueve el mapa para ajustar'), findsNothing);
    expect(find.text('Blvd. Díaz Ordaz 1540'), findsOneWidget);
    expect(find.byTooltip('Centrar en mi ubicación'), findsNothing);
    expect(find.text('Confirmar esta ubicación'), findsNothing);
    expect(
      tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .options
          .interactionOptions
          .flags,
      InteractiveFlag.none,
    );
  });

  for (final (width, scale) in [(320.0, 2.0), (390.0, 2.0), (800.0, 1.0)]) {
    testWidgets('a $width de ancho y texto al ${(scale * 100).round()} % no '
        'se desborda', (tester) async {
      tester.view.physicalSize =
          Size(width, 844) * tester.view.devicePixelRatio;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        _app(
          IncidentLocationMapDialog(
            initial: _start,
            placeLabel: 'Boulevard Gustavo Díaz Ordaz 1540, La Mesa',
            placeLookup: (_, _) async => null,
          ),
          textScale: scale,
          size: Size(width, 844),
        ),
      );
      await _open(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Confirmar esta ubicación'), findsOneWidget);
    });
  }
}
