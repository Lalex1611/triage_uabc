import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(
  Widget child, {
  double width = 342,
  double textScale = 1,
  TriageRoleTheme? role,
}) => MaterialApp(
  theme: ThemeData(extensions: [?role]),
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  ),
);

BoxDecoration _card(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(TriageSectionCard),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  group('TriageSectionCard', () {
    testWidgets('superficie blanca con borde sutil y esquinas de tarjeta', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const TriageSectionCard(title: 'Historial', child: Text('x'))),
      );
      final card = _card(tester);
      expect(card.color, TriageColors.surface);
      expect((card.border! as Border).top.color, TriageColors.borderSubtle);
      expect(card.borderRadius, BorderRadius.circular(TriageRadii.xl));
    });

    testWidgets('el título se anuncia como encabezado', (tester) async {
      await tester.pumpWidget(
        _wrap(const TriageSectionCard(title: 'Historial', child: Text('x'))),
      );
      expect(
        tester.getSemantics(find.text('Historial')),
        isSemantics(label: 'Historial', isHeader: true),
      );
    });

    testWidgets('sin título ni trailing solo muestra el contenido', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const TriageSectionCard(child: Text('Solo contenido'))),
      );
      expect(find.text('Solo contenido'), findsOneWidget);
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('trailing queda a la derecha del título', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TriageSectionCard(
            title: 'Fotografías',
            trailing: TriageSectionAction(label: 'Añadir', onTap: () {}),
            child: const Text('x'),
          ),
        ),
      );
      final card = tester.getTopRight(find.byType(TriageSectionCard));
      expect(
        tester.getTopRight(find.byType(TriageSectionAction)).dx,
        card.dx - TriageSpacing.lg,
      );
      expect(
        tester.getCenter(find.text('Fotografías')).dy,
        closeTo(tester.getCenter(find.text('Añadir')).dy, 1),
      );
    });

    testWidgets('si no caben en una línea, trailing baja sin desbordarse', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TriageSectionCard(
            title: 'Datos del paciente con un título bastante largo',
            trailing: TriagePatientStatusSample.badge,
            child: const Text('x'),
          ),
          width: 200,
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(find.text('TRASLADANDO')).dy,
        greaterThan(
          tester.getBottomLeft(find.textContaining('Datos del')).dy - 1,
        ),
      );
    });
  });

  group('TriageSectionAction', () {
    for (final (name, role) in [
      ('campo', TriageRoleTheme.paramedic),
      ('hospital', TriageRoleTheme.hospital),
    ]) {
      testWidgets('toma el color del rol $name', (tester) async {
        await tester.pumpWidget(
          _wrap(
            TriageSectionAction(
              label: 'Editar',
              icon: TriageIcons.pencil,
              onTap: () {},
            ),
            role: role,
          ),
        );
        expect(
          tester.widget<Text>(find.text('Editar')).style!.color,
          role.accent,
        );
        expect(
          tester.widget<TriageIcon>(find.byType(TriageIcon)).color,
          role.accent,
        );
      });
    }

    testWidgets('zona táctil de 44 y responde al toque', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          Align(
            child: TriageSectionAction(label: 'A', onTap: () => taps++),
          ),
        ),
      );
      final size = tester.getSize(find.byType(TriageSectionAction));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
      await tester.tap(find.byType(TriageSectionAction));
      expect(taps, 1);
    });

    testWidgets('se anuncia como botón', (tester) async {
      await tester.pumpWidget(
        _wrap(TriageSectionAction(label: 'Añadir', onTap: () {})),
      );
      expect(
        tester.getSemantics(find.text('Añadir')),
        isSemantics(label: 'Añadir', isButton: true, hasTapAction: true),
      );
    });

    test('contraste ≥ 4.5 en ambos roles', () {
      for (final role in [
        TriageRoleTheme.paramedic,
        TriageRoleTheme.hospital,
      ]) {
        expect(
          _contrast(role.accent, TriageColors.surface),
          greaterThanOrEqualTo(4.5),
        );
      }
    });
  });
}

abstract final class TriagePatientStatusSample {
  static final badge = TriageStatusBadge.patient(
    PatientLifecycleStatus.transferring,
  );
}
