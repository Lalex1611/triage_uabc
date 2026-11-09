import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

final _image = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  ),
);

Widget _opener({
  int photos = 3,
  int initialIndex = 0,
  Future<bool> Function(int)? onDelete,
}) => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showTriagePhotoViewer(
          context,
          photos: List.filled(photos, _image),
          initialIndex: initialIndex,
          onDelete: onDelete,
        ),
        child: const Text('Abrir'),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('abre en la foto indicada y la X lo cierra', (tester) async {
    await tester.pumpWidget(_opener(initialIndex: 1));
    await _open(tester);
    expect(find.text('Foto 2 de 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Foto 2 de 3'), findsNothing);
  });

  testWidgets('deslizar cambia de foto', (tester) async {
    await tester.pumpWidget(_opener());
    await _open(tester);
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Foto 2 de 3'), findsOneWidget);
  });

  testWidgets('sin onDelete no hay papelera', (tester) async {
    await tester.pumpWidget(_opener());
    await _open(tester);
    expect(find.byTooltip('Eliminar fotografía'), findsNothing);
  });

  testWidgets('se cierra solo si la foto se eliminó', (tester) async {
    var result = false;
    final indexes = <int>[];
    await tester.pumpWidget(
      _opener(
        initialIndex: 2,
        onDelete: (index) async {
          indexes.add(index);
          return result;
        },
      ),
    );
    await _open(tester);

    await tester.tap(find.byTooltip('Eliminar fotografía'));
    await tester.pumpAndSettle();
    expect(find.text('Foto 3 de 3'), findsOneWidget);

    result = true;
    await tester.tap(find.byTooltip('Eliminar fotografía'));
    await tester.pumpAndSettle();
    expect(find.text('Foto 3 de 3'), findsNothing);
    expect(indexes, [2, 2]);
  });

  testWidgets('una sola foto no muestra puntos', (tester) async {
    await tester.pumpWidget(_opener(photos: 1));
    await _open(tester);
    expect(find.byType(Wrap), findsNothing);
  });

  testWidgets('una imagen que falla no rompe el visor', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showTriagePhotoViewer(
              context,
              photos: [MemoryImage(utf8.encode('no es imagen'))],
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Foto 1 de 1'), findsOneWidget);
  });
}
