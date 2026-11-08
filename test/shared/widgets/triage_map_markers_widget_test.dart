import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(Widget child, {TriageRoleTheme? role}) => MaterialApp(
  theme: ThemeData(extensions: [?role]),
  home: Scaffold(body: Center(child: child)),
);

BoxDecoration _decorationAt(WidgetTester tester, int index) =>
    tester.widget<DecoratedBox>(find.byType(DecoratedBox).at(index)).decoration
        as BoxDecoration;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  group('TriagePatientMarker', () {
    testWidgets('punto de 26 con el color del nivel y aro blanco', (
      tester,
    ) async {
      for (final level in TriageLevel.values) {
        await tester.pumpWidget(_wrap(TriagePatientMarker(level)));
        final dot = _decorationAt(tester, 0);
        expect(dot.color, level.color, reason: level.label);
        expect(dot.boxShadow, TriageShadows.marker);
        final side = (dot.border! as Border).top;
        expect(side.color, TriageColors.surface);
        expect(side.width, 3);
        expect(tester.getSize(find.byType(DecoratedBox)), const Size(26, 26));
      }
    });

    testWidgets('resaltado: aro del color del rol', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TriagePatientMarker(TriageLevel.red, highlighted: true),
          role: TriageRoleTheme.hospital,
        ),
      );
      final ring = _decorationAt(tester, 0).border! as Border;
      expect(ring.top.color, TriageRoleTheme.hospital.accent);
      expect(ring.top.width, TriageSizes.strokeStrong);
    });

    testWidgets('con toque: responde en toda la zona de 48', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(TriagePatientMarker(TriageLevel.green, onTap: () => taps++)),
      );
      final marker = find.byType(TriagePatientMarker);
      expect(tester.getSize(marker), const Size(48, 48));
      await tester.tapAt(tester.getTopLeft(marker) + const Offset(2, 2));
      expect(taps, 1);
    });

    testWidgets('se anuncia con su nivel y su estado', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TriagePatientMarker(
            TriageLevel.yellow,
            highlighted: true,
            onTap: () {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(TriagePatientMarker)),
        isSemantics(
          label: 'Paciente en amarillo',
          isButton: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('admite un texto propio para el lector', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TriagePatientMarker(
            TriageLevel.red,
            semanticLabel: 'Bruce Cervantes',
          ),
        ),
      );
      expect(find.bySemanticsLabel('Bruce Cervantes'), findsOneWidget);
    });
  });

  group('TriageHospitalMarker y TriageUnitMarker', () {
    testWidgets('recuadro de 38 con el ícono de cada uno', (tester) async {
      final markers = {
        const TriageHospitalMarker(): (
          TriageIcons.hospital,
          TriageColors.hospitalAccent,
        ),
        const TriageUnitMarker(): (
          TriageIcons.ambulance,
          TriageColors.textPrimary,
        ),
      };
      for (final MapEntry(key: marker, value: expected) in markers.entries) {
        await tester.pumpWidget(_wrap(marker));
        final box = _decorationAt(tester, 0);
        expect(box.color, TriageColors.surface);
        expect((box.border! as Border).top.color, TriageColors.borderMedium);
        expect(box.borderRadius, BorderRadius.circular(TriageRadii.md));
        expect(box.boxShadow, TriageShadows.marker);
        expect(tester.getSize(find.byType(DecoratedBox)), const Size(38, 38));

        final icon = tester.widget<TriageIcon>(find.byType(TriageIcon));
        expect(icon.asset, expected.$1);
        expect(icon.color, expected.$2);
      }
    });

    testWidgets('el nombre del hospital llega al lector', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          TriageHospitalMarker(
            semanticLabel: 'Hospital General de Tijuana',
            onTap: () => taps++,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(TriageHospitalMarker)),
        isSemantics(
          label: 'Hospital General de Tijuana',
          isButton: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.byType(TriageHospitalMarker));
      expect(taps, 1);
    });

    testWidgets('sin toque no se anuncia como botón', (tester) async {
      await tester.pumpWidget(_wrap(const TriageUnitMarker()));
      expect(
        tester.getSemantics(find.byType(TriageUnitMarker)),
        isSemantics(label: 'Unidad de ambulancia', isButton: false),
      );
    });
  });

  group('TriageUserMarker', () {
    testWidgets('círculo azul de 38 con la flecha en blanco en ambos roles', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const TriageUserMarker(), role: TriageRoleTheme.paramedic),
      );
      final circle = _decorationAt(tester, 0);
      expect(circle.color, TriageColors.hospitalAccent);
      expect(circle.shape, BoxShape.circle);
      expect(tester.getSize(find.byType(DecoratedBox)), const Size(38, 38));

      final icon = tester.widget<TriageIcon>(find.byType(TriageIcon));
      expect(icon.asset, TriageIcons.navigation);
      expect(icon.color, TriageColors.textInverse);
      expect(find.bySemanticsLabel('Tu ubicación'), findsOneWidget);
    });

    testWidgets('en un Marker más pequeño no se desborda', (tester) async {
      await tester.pumpWidget(
        _wrap(const SizedBox.square(dimension: 28, child: TriageUserMarker())),
      );
      expect(tester.takeException(), isNull);
    });
  });

  test('íconos con contraste ≥ 3 sobre su fondo', () {
    expect(
      _contrast(TriageColors.hospitalAccent, TriageColors.surface),
      greaterThanOrEqualTo(3),
    );
    expect(
      _contrast(TriageColors.textPrimary, TriageColors.surface),
      greaterThanOrEqualTo(3),
    );
    expect(
      _contrast(TriageColors.textInverse, TriageColors.hospitalAccent),
      greaterThanOrEqualTo(3),
    );
  });
}
