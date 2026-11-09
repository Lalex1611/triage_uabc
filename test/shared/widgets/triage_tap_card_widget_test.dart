import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(Widget child, {double textScale = 1}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(
      body: Center(child: SizedBox(width: 280, child: child)),
    ),
  ),
);

BoxDecoration _decoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.descendant(
                of: find.byType(TriageTapCard),
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration
        as BoxDecoration;

const _content = Text('Contenido');

void main() {
  testWidgets('superficie blanca, sin borde ni sombra por defecto', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(TriageTapCard(onTap: () {}, child: _content)),
    );
    final decoration = _decoration(tester);
    expect(decoration.color, TriageColors.surface);
    expect(decoration.border, isNull);
    expect(decoration.boxShadow, isNull);
    expect(decoration.borderRadius, BorderRadius.circular(TriageRadii.xl));
  });

  testWidgets('aplica color, ancho de borde y sombra', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TriageTapCard(
          onTap: () {},
          borderColor: TriageColors.danger,
          borderWidth: TriageSizes.strokeStrong,
          shadow: TriageShadows.card,
          child: _content,
        ),
      ),
    );
    final decoration = _decoration(tester);
    final side = (decoration.border! as Border).top;
    expect(side.color, TriageColors.danger);
    expect(side.width, TriageSizes.strokeStrong);
    expect(decoration.boxShadow, TriageShadows.card);
  });

  testWidgets('toda la tarjeta responde al toque', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(TriageTapCard(onTap: () => taps++, child: _content)),
    );
    final card = find.byType(TriageTapCard);
    await tester.tapAt(tester.getTopRight(card) + const Offset(-4, 4));
    expect(taps, 1);
  });

  testWidgets('se anuncia como botón con su contenido y selección', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(TriageTapCard(onTap: () {}, selected: true, child: _content)),
    );
    expect(
      tester.getSemantics(find.byType(TriageTapCard)),
      isSemantics(
        label: 'Contenido',
        isButton: true,
        isEnabled: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('sin onTap se anuncia desactivada', (tester) async {
    await tester.pumpWidget(
      _wrap(const TriageTapCard(onTap: null, child: _content)),
    );
    expect(
      tester.getSemantics(find.byType(TriageTapCard)),
      isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
    );
  });

  testWidgets('exclusive la anuncia como opción de un grupo', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TriageTapCard(
          onTap: () {},
          selected: true,
          exclusive: true,
          child: _content,
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(TriageTapCard)),
      isSemantics(
        isButton: false,
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
  });

  group('TriageOptionText', () {
    testWidgets('estilo por defecto y detalle secundario', (tester) async {
      await tester.pumpWidget(
        _wrap(const TriageOptionText(title: 'Título', detail: 'Detalle')),
      );
      final title = tester.widget<Text>(find.text('Título')).style!;
      expect(title.fontSize, TriageTextStyles.labelLarge.fontSize);
      expect(title.color, TriageColors.textPrimary);
      expect(
        tester.widget<Text>(find.text('Detalle')).style!.color,
        TriageColors.textSecondary,
      );
    });

    testWidgets('admite otro estilo y color de título', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TriageOptionText(
            title: 'Título',
            detail: 'Detalle',
            titleStyle: TriageTextStyles.titleSmall,
            titleColor: TriageColors.danger,
          ),
        ),
      );
      final title = tester.widget<Text>(find.text('Título')).style!;
      expect(title.fontSize, TriageTextStyles.titleSmall.fontSize);
      expect(title.color, TriageColors.danger);
    });

    testWidgets('textos largos al 200 % no se desbordan', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TriageOptionText(
            title: 'Un título bastante largo para esta columna',
            detail: 'Un detalle que también necesita varias líneas',
          ),
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
