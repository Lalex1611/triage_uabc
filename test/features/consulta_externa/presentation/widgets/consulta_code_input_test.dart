import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/consulta_externa/presentation/widgets/consulta_code_input.dart';

void main() {
  late TextEditingController controller;
  var rejected = 0;

  setUp(() {
    controller = TextEditingController();
    rejected = 0;
  });
  tearDown(() => controller.dispose());

  Future<void> pumpInput(WidgetTester tester, {bool error = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 350,
              child: ConsultaCodeInput(
                controller: controller,
                hasError: error,
                onRejectedInput: () => rejected++,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Comparte un campo y presenta seis casillas', (tester) async {
    await pumpInput(tester);
    expect(find.byType(TextField), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      expect(find.byKey(ValueKey('consulta-code-cell-$i')), findsOneWidget);
    }
    await tester.enterText(find.byType(TextField), 'ab3k7x');
    expect(controller.text, 'AB3K7X');
    expect(controller.selection.extentOffset, 6);
  });

  testWidgets('Normaliza el pegado completo sin generar caracteres extras', (
    tester,
  ) async {
    await pumpInput(tester);
    await tester.enterText(find.byType(TextField), ' ab-3 k7x ');
    expect(controller.text, 'AB3K7X');
    expect(rejected, 0);
  });

  testWidgets('Rechaza el contenido invalido o mayor a seis sin recortarlo', (
    tester,
  ) async {
    await pumpInput(tester);
    await tester.enterText(find.byType(TextField), 'AB3K7X');
    await tester.enterText(find.byType(TextField), 'ABCDEFG');
    expect(controller.text, 'AB3K7X');
    await tester.enterText(find.byType(TextField), 'AB!K7X');
    expect(controller.text, 'AB3K7X');
    expect(rejected, 2);
  });

  testWidgets('Tocar una casilla permite reemplazar ese caracter', (
    tester,
  ) async {
    await pumpInput(tester);
    await tester.enterText(find.byType(TextField), 'AB3K7X');
    await tester.pump();
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('consulta-code-cell-2'))),
    );
    await tester.pump();
    expect(
      controller.selection,
      const TextSelection(baseOffset: 2, extentOffset: 3),
    );
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'AB9K7X',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    await tester.pump();
    expect(controller.text, 'AB9K7X');
  });

  testWidgets('Permite borrar y seleccionar con teclado', (tester) async {
    await pumpInput(tester);
    await tester.enterText(find.byType(TextField), 'AB3K7X');
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(controller.text, 'AB3K7');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(controller.selection.extentOffset, 4);
  });

  testWidgets('Pegado por portapapeles sustituye el codigo completo', (
    tester,
  ) async {
    await pumpInput(tester);
    await tester.enterText(find.byType(TextField), 'AB3K7X');
    await tester.pump();
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('consulta-code-cell-2'))),
    );
    await tester.pump();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async =>
          call.method == 'Clipboard.getData' ? {'text': 'cd-4p9z'} : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(controller.text, 'CD4P9Z');
  });

  testWidgets('Conserva un valor editable anunciado al lector de pantalla', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpInput(tester);
    await tester.enterText(find.byType(TextField), 'AB3K7X');
    await tester.pump();
    expect(
      find.bySemanticsLabel('Código de consulta, seis letras o números'),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.byType(EditableText)).getSemanticsData().value,
      'AB3K7X',
    );
    semantics.dispose();
  });

  testWidgets('A07 conserva el valor y las seis casillas de error', (
    tester,
  ) async {
    controller.text = 'AB3K7X';
    await pumpInput(tester, error: true);
    expect(controller.text, 'AB3K7X');
    for (var i = 0; i < 6; i++) {
      final cell = tester.widget<Container>(
        find.byKey(ValueKey('consulta-code-cell-$i')),
      );
      final decoration = cell.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFFFDECEC));
      expect((decoration.border! as Border).top.color, const Color(0xFFC30508));
    }
  });
}
