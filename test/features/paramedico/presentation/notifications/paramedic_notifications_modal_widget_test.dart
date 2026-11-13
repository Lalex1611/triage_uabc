import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/notifications/paramedic_notification.dart';
import 'package:sistema_triage/features/paramedico/presentation/notifications/widgets/paramedic_notifications_modal_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

ParamedicNotification _notification(String id, {bool read = false}) =>
    ParamedicNotification(
      id: id,
      title: 'Traslado cancelado',
      body: 'Sin camas de choque',
      kind: 'transfer_cancelled',
      patientDisplayName: 'Alberto Pérez',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      readAt: read ? DateTime.now() : null,
    );

/// Abre el modal con `showDialog`, como en la app, en un móvil de 393 × 852
Future<void> _open(
  WidgetTester tester,
  List<ParamedicNotification> items, [
  Future<void> Function(ParamedicNotification)? onTap,
]) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [TriageRoleTheme.paramedic]),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => ParamedicNotificationsModal(
                notifications: items,
                onNotificationTap: onTap ?? (_) async {},
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

// La caja blanca del modal: el Material más cercano al título
final _modal = find
    .ancestor(of: find.text('Notificaciones'), matching: find.byType(Material))
    .first;

void main() {
  testWidgets('cuenta las sin leer y muestra paciente y motivo', (
    tester,
  ) async {
    await _open(tester, [_notification('a'), _notification('b', read: true)]);
    expect(find.text('1 sin leer'), findsOneWidget);
    expect(find.byType(TriageNotificationCard), findsNWidgets(2));
    expect(find.text('Alberto Pérez: Sin camas de choque'), findsNWidgets(2));
    expect(find.text('hace 5 min'), findsNWidgets(2));
  });

  testWidgets('sale centrado en la pantalla', (tester) async {
    await _open(tester, [_notification('a')]);
    final center = tester.getCenter(_modal);
    expect(center.dx, closeTo(393 / 2, 1));
    expect(center.dy, closeTo(852 / 2, 1));
  });

  testWidgets('con muchas, la lista se desplaza dentro del modal', (
    tester,
  ) async {
    await _open(tester, [for (var i = 0; i < 12; i++) _notification('$i')]);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(_modal).height, lessThanOrEqualTo(517));
    expect(find.text('Notificaciones'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    // La cabecera sigue fija mientras la lista baja
    expect(find.text('Notificaciones'), findsOneWidget);
    expect(find.byType(TriageNotificationCard).last, findsOneWidget);
  });

  testWidgets('al tocarla se pinta leída', (tester) async {
    final tapped = <String>[];
    await _open(tester, [_notification('a')], (n) async => tapped.add(n.id));
    await tester.tap(find.byType(TriageNotificationCard));
    await tester.pump();
    expect(tapped, ['a']);
    expect(find.text('Todas leídas'), findsOneWidget);
  });

  testWidgets('si no se pudo marcar, sigue sin leer', (tester) async {
    await _open(tester, [_notification('a')], (_) async => throw Exception());
    await tester.tap(find.byType(TriageNotificationCard));
    await tester.pump();
    expect(find.text('1 sin leer'), findsOneWidget);
  });

  testWidgets('la X lo cierra', (tester) async {
    await _open(tester, [_notification('a')]);
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.byType(ParamedicNotificationsModal), findsNothing);
  });

  testWidgets('sin notificaciones muestra el aviso', (tester) async {
    await _open(tester, const []);
    expect(find.text('No tienes notificaciones por ahora.'), findsOneWidget);
    expect(find.text('Todas leídas'), findsOneWidget);
  });
}
