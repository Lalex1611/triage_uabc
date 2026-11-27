import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/create_incident_sheet.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/incident_location_map_dialog_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// GPS de mentira: desactivado, o con permiso y una posición fija
void _gps({required bool on}) {
  const channel = MethodChannel('flutter.baseflow.com/geolocator');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, (call) async {
    switch (call.method) {
      case 'isLocationServiceEnabled':
        return on;
      case 'checkPermission':
        return 2; // Mientras se usa la app
      case 'getCurrentPosition':
        return {'latitude': 32.4836, 'longitude': -116.9330, 'timestamp': 0};
    }
    return null;
  });
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [TriageRoleTheme.paramedic]),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showCreateIncidentSheet(context),
            child: const Text('nuevo'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('nuevo'));
  await tester.pumpAndSettle();
}

Future<void> _tapMiniMap(WidgetTester tester) async {
  final miniMap = find.byKey(miniMapKey);
  await tester.ensureVisible(miniMap);
  await tester.pumpAndSettle();
  await tester.tap(miniMap);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('con la ubicación confirmada, tocar el mini-mapa abre el '
      'ajuste', (tester) async {
    _gps(on: true);
    await _openSheet(tester);
    expect(find.text('Ajustar'), findsOneWidget);
    expect(find.byType(IncidentLocationMapDialog), findsNothing);

    await _tapMiniMap(tester);
    expect(find.byType(IncidentLocationMapDialog), findsOneWidget);
    expect(find.text('Mueve el mapa para ajustar'), findsOneWidget);
  });

  testWidgets('sin GPS, tocar el recuadro del mapa abre el mapa para '
      'elegir el punto', (tester) async {
    _gps(on: false);
    await _openSheet(tester);
    expect(find.text('Elegir en el mapa'), findsOneWidget);

    await _tapMiniMap(tester);
    expect(find.byType(IncidentLocationMapDialog), findsOneWidget);
  });

  testWidgets('el lector de pantalla no oye el atajo del mapa además del '
      'botón', (tester) async {
    _gps(on: false);
    await _openSheet(tester);
    expect(find.bySemanticsLabel('Elegir en el mapa'), findsOneWidget);
  });
}
