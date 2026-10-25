import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

Widget _wrap(Widget child) => MaterialApp(home: Center(child: child));

ColorFilter? _filter(WidgetTester tester) =>
    tester.widget<SvgPicture>(find.byType(SvgPicture)).colorFilter;

void main() {
  testWidgets('sin parámetros: 24 px y color de íconos del tema de la app', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          iconTheme: const IconThemeData(color: TriageColors.textPrimary),
        ),
        home: const Center(child: TriageIcon(TriageIcons.map)),
      ),
    );
    expect(tester.getSize(find.byType(SvgPicture)), const Size(24, 24));
    expect(
      _filter(tester),
      const ColorFilter.mode(TriageColors.textPrimary, BlendMode.srcIn),
    );
  });

  testWidgets('hereda tamaño y color del IconTheme', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const IconTheme(
          data: IconThemeData(size: 18, color: TriageColors.hospitalAccent),
          child: TriageIcon(TriageIcons.map),
        ),
      ),
    );
    expect(tester.getSize(find.byType(SvgPicture)), const Size(18, 18));
    expect(
      _filter(tester),
      const ColorFilter.mode(TriageColors.hospitalAccent, BlendMode.srcIn),
    );
  });

  testWidgets('los parámetros ganan al IconTheme', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const IconTheme(
          data: IconThemeData(size: 18, color: TriageColors.hospitalAccent),
          child: TriageIcon(
            TriageIcons.map,
            size: 20,
            color: TriageColors.danger,
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(SvgPicture)), const Size(20, 20));
    expect(
      _filter(tester),
      const ColorFilter.mode(TriageColors.danger, BlendMode.srcIn),
    );
  });

  testWidgets('aplica IconTheme.opacity incluso con color explícito', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const IconTheme(
          data: IconThemeData(opacity: 0.5),
          child: TriageIcon(TriageIcons.map, color: TriageColors.danger),
        ),
      ),
    );
    expect(
      _filter(tester),
      ColorFilter.mode(
        TriageColors.danger.withValues(alpha: 0.5),
        BlendMode.srcIn,
      ),
    );
  });

  testWidgets('decorativo sin etiqueta; con etiqueta se anuncia', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const TriageIcon(TriageIcons.bell)));
    expect(
      tester.widget<SvgPicture>(find.byType(SvgPicture)).excludeFromSemantics,
      isTrue,
    );

    await tester.pumpWidget(
      _wrap(
        const TriageIcon(TriageIcons.bell, semanticLabel: 'Notificaciones'),
      ),
    );
    expect(find.bySemanticsLabel('Notificaciones'), findsOneWidget);
  });
}
