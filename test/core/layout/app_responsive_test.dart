import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';

Future<BuildContext> _context(
  WidgetTester tester, {
  required Size size,
  EdgeInsets padding = EdgeInsets.zero,
  double textScale = 1,
}) async {
  late BuildContext captured;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: padding,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return captured;
}

void main() {
  testWidgets('rDim solo reduce, hasta el 82 %', (tester) async {
    Future<double> dimAt(double width) async {
      final context = await _context(tester, size: Size(width, 800));
      return context.rDim(100);
    }

    expect(await dimAt(800), 100);
    expect(await dimAt(393), 100);
    expect(await dimAt(360), closeTo(91.6, 0.1));
    expect(await dimAt(280), 82);
  });

  testWidgets('márgenes de pantalla con los tokens de espaciado', (
    tester,
  ) async {
    Future<double> paddingAt(double width) async {
      final context = await _context(tester, size: Size(width, 800));
      return context.horizontalPadding;
    }

    expect(await paddingAt(320), TriageSpacing.md);
    expect(await paddingAt(350), TriageSpacing.lg);
    expect(await paddingAt(393), TriageSpacing.xxl);
  });

  testWidgets('la barra suma la zona segura solo si supera su margen', (
    tester,
  ) async {
    const bar =
        TriageSizes.controlLarge + 2 * TriageSpacing.xs + TriageSpacing.sm;

    final plain = await _context(tester, size: const Size(393, 800));
    expect(plain.bottomNavExtent, bar + TriageSpacing.sm);

    final withSafeArea = await _context(
      tester,
      size: const Size(393, 800),
      padding: const EdgeInsets.only(bottom: 34),
    );
    expect(withSafeArea.bottomNavExtent, bar + 34);
  });

  testWidgets('textWidth respeta el tamaño de texto del usuario', (
    tester,
  ) async {
    const style = TextStyle(fontSize: 10);
    final normal = AppResponsive.textWidth(
      await _context(tester, size: const Size(393, 800)),
      'Hola',
      style,
    );
    final doubled = AppResponsive.textWidth(
      await _context(tester, size: const Size(393, 800), textScale: 2),
      'Hola',
      style,
    );
    expect(doubled, 2 * normal);
  });
}
