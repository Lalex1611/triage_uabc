import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 340, child: child)),
  ),
);

final _clearButton = find.byTooltip('Borrar búsqueda');

void main() {
  testWidgets('muestra el hint y sin texto no hay ✕', (tester) async {
    await tester.pumpWidget(
      _wrap(const TriageSearchBar(hint: 'Buscar paciente')),
    );
    expect(find.text('Buscar paciente'), findsOneWidget);
    expect(_clearButton, findsNothing);
  });

  testWidgets('al escribir avisa el texto y aparece la ✕', (tester) async {
    String? last;
    await tester.pumpWidget(
      _wrap(TriageSearchBar(hint: 'Buscar', onChanged: (v) => last = v)),
    );
    await tester.enterText(find.byType(TextField), 'Bruce');
    await tester.pump();
    expect(last, 'Bruce');
    expect(_clearButton, findsOneWidget);
  });

  testWidgets('la ✕ borra el texto, avisa vacío y desaparece', (tester) async {
    String? last;
    final controller = TextEditingController(text: 'INC-729');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _wrap(
        TriageSearchBar(
          hint: 'Buscar',
          controller: controller,
          onChanged: (v) => last = v,
        ),
      ),
    );
    await tester.tap(_clearButton);
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(last, '');
    expect(_clearButton, findsNothing);
  });

  testWidgets('alto mínimo 48 y ✕ con zona táctil de 44', (tester) async {
    await tester.pumpWidget(_wrap(const TriageSearchBar(hint: 'Buscar')));
    expect(tester.getSize(find.byType(TriageSearchBar)).height, 48);

    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();
    expect(tester.getSize(_clearButton), const Size(44, 44));
  });
}
