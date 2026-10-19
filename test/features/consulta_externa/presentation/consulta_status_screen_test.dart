import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/consulta_externa/domain/constants/consulta_status.dart';
import 'package:sistema_triage/features/consulta_externa/domain/consulta_lookup_result.dart';
import 'package:sistema_triage/features/consulta_externa/presentation/screens/consulta_status_screen.dart';

void main() {
  const transfer = ConsultaLookupResult(
    status: ConsultaStatus.trasladando,
    code: 'AB3K7X',
    hospitalName: 'Hospital de prueba',
    hospitalAddress: 'Dirección de prueba 123',
    hospitalPhone: '664-123-4567',
  );

  Future<void> pumpScreen(
    WidgetTester tester,
    ConsultaLookupResult result, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: ConsultaStatusScreen(result: result),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Traslado muestra el código consultado y los datos recibidos sin inventar fecha',
    (tester) async {
      await pumpScreen(tester, transfer);
      expect(find.text('Estado del paciente'), findsOneWidget);
      expect(find.text(ConsultaStatus.trasladando.title), findsOneWidget);
      expect(find.text(ConsultaStatus.trasladando.subtitle), findsOneWidget);
      expect(find.text(transfer.hospitalName!), findsOneWidget);
      expect(find.text(transfer.hospitalAddress!), findsOneWidget);
      expect(find.text(transfer.hospitalPhone!), findsOneWidget);
      expect(find.textContaining('Actualizado hace'), findsNothing);
      expect(find.text('Código AB3K7X'), findsOneWidget);
      expect(find.text('Consulta externa'), findsNothing);
      expect(find.textContaining('ya fue avisado'), findsNothing);
      expect(find.text('Registro'), findsNothing);
      final active = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((widget) => widget.properties.selected == true);
      expect(active, hasLength(1));
      expect(
        find.descendant(
          of: find.byWidget(active.single),
          matching: find.text('Trasladando'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final hospitalName in <String?>[null, '', '   ']) {
    testWidgets('Conserva hospital no asignado para "$hospitalName"', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        ConsultaLookupResult(
          status: ConsultaStatus.trasladando,
          hospitalName: hospitalName,
          hospitalAddress: 'No debe mostrarse',
          hospitalPhone: 'No debe mostrarse',
        ),
      );
      expect(find.text('Aún no asignado'), findsOneWidget);
      expect(find.text('No debe mostrarse'), findsNothing);
      expect(find.text('Consulta externa'), findsOneWidget);
      expect(find.textContaining('Código '), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Hospital sin dirección ni teléfono conserva campos opcionales', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const ConsultaLookupResult(
        status: ConsultaStatus.trasladando,
        hospitalName: 'Solo nombre',
      ),
    );
    expect(find.text('Solo nombre'), findsOneWidget);
    expect(find.byIcon(Icons.phone_outlined), findsNothing);
    expect(find.text('Aún no asignado'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  const stepLabels = ['En espera', 'Trasladando', 'Recibido', 'Alta médica'];
  for (final status in ConsultaStatus.values) {
    testWidgets(
      'A06 refleja el estado ${status.name} y conserva la asignación',
      (tester) async {
        await pumpScreen(
          tester,
          ConsultaLookupResult(
            status: status,
            code: 'AB3K7X',
            hospitalName: 'Hospital de prueba',
            hospitalAddress: 'Dirección de prueba',
            hospitalPhone: '664-000-0000',
          ),
        );
        expect(find.text('Estado del paciente'), findsOneWidget);
        expect(find.text('Código AB3K7X'), findsOneWidget);
        expect(find.text(status.title), findsWidgets);
        expect(find.text(status.subtitle), findsOneWidget);
        expect(find.text('Esta consulta es limitada'), findsOneWidget);
        final active = tester
            .widgetList<Semantics>(find.byType(Semantics))
            .where((widget) => widget.properties.selected == true);
        expect(active, hasLength(1));
        expect(
          find.descendant(
            of: find.byWidget(active.single),
            matching: find.text(stepLabels[status.index]),
          ),
          findsOneWidget,
        );
        if (status == ConsultaStatus.enEspera) {
          expect(find.text('Aún no asignado'), findsOneWidget);
          expect(find.text('Hospital de prueba'), findsNothing);
          expect(find.text('Dirección de prueba'), findsNothing);
          expect(find.text('664-000-0000'), findsNothing);
        } else {
          expect(find.text('Hospital de prueba'), findsOneWidget);
          expect(find.text('Dirección de prueba'), findsOneWidget);
          expect(find.text('664-000-0000'), findsOneWidget);
          expect(find.text('Aún no asignado'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final status in ConsultaStatus.values) {
    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(800, 600),
    ]) {
      testWidgets('${status.name} permite texto largo y ampliado a $size', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          ConsultaLookupResult(
            status: status,
            code: 'AB3K7X',
            hospitalName:
                'Hospital con un nombre particularmente largo de prueba',
            hospitalAddress:
                'Avenida con dirección larga, número 12345, zona de prueba',
            hospitalPhone: '+52 664 123 4567 extensión 12345678',
          ),
          size: size,
          textScale: 2,
        );
        await tester.ensureVisible(find.text('Esta consulta es limitada'));
        await tester.pumpAndSettle();
        expect(
          find.text('Esta consulta es limitada').hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Al recibir otro estado actualiza texto e indicador', (
    tester,
  ) async {
    await pumpScreen(tester, transfer);
    await pumpScreen(
      tester,
      const ConsultaLookupResult(
        status: ConsultaStatus.recibido,
        hospitalName: 'Hospital actualizado',
      ),
    );
    expect(find.text(ConsultaStatus.trasladando.title), findsNothing);
    expect(find.text(ConsultaStatus.recibido.title), findsOneWidget);
    expect(find.text('Hospital actualizado'), findsOneWidget);
    final active = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((widget) => widget.properties.selected == true);
    expect(active, hasLength(1));
    expect(
      find.descendant(
        of: find.byWidget(active.single),
        matching: find.text('Recibido'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Regresar vuelve a la pantalla anterior', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ConsultaStatusScreen(result: transfer),
                ),
              ),
              child: const Text('Anterior'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Anterior'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Regresar'));
    await tester.pumpAndSettle();
    expect(find.text('Anterior'), findsOneWidget);
    expect(find.byType(ConsultaStatusScreen), findsNothing);
  });
}
