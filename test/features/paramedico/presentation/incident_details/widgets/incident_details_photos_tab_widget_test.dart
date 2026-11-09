import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/incident_details_view_mapper.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_details_photos_tab_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

final _image = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  ),
);

Widget _tab({
  int photos = 2,
  bool isEditable = true,
  bool isUploading = false,
  String? description = 'Choque en el libramiento',
  VoidCallback? onAdd,
  Future<bool> Function(int)? onRemove,
  Future<void> Function(String)? onSave,
  double textScale = 1,
}) => MaterialApp(
  builder: (context, navigator) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: navigator!,
  ),
  home: Scaffold(
    body: IncidentDetailsPhotosTab(
      description: description,
      photos: List.filled(photos, _image),
      isEditable: isEditable,
      isUploading: isUploading,
      onAddPhotoTap: onAdd ?? () {},
      onRemovePhoto: onRemove ?? (_) async => false,
      onSaveDescription: onSave,
    ),
  ),
);

void main() {
  testWidgets('quien edita ve sus fotos, «Añadir» y «Editar»', (tester) async {
    var added = 0;
    await tester.pumpWidget(_tab(onAdd: () => added++));
    expect(find.byType(TriagePhoto), findsNWidgets(3));
    expect(find.text('Fotografías del evento'), findsOneWidget);
    await tester.tap(find.byType(TriagePhoto).last);
    expect(added, 1);
  });

  testWidgets('sin permiso no hay «Añadir» ni acciones de editar', (
    tester,
  ) async {
    await tester.pumpWidget(_tab(isEditable: false));
    expect(find.byType(TriagePhoto), findsNWidgets(2));
    expect(find.byType(TriageSectionAction), findsNothing);
  });

  testWidgets('sin permiso ni fotos explica que no hay', (tester) async {
    await tester.pumpWidget(_tab(photos: 0, isEditable: false));
    expect(find.text('Sin fotografías registradas.'), findsOneWidget);
    expect(find.byType(TriagePhoto), findsNothing);
  });

  testWidgets('«Editar» muestra la papelera y «Listo» la oculta', (
    tester,
  ) async {
    int? removed;
    await tester.pumpWidget(
      _tab(
        onRemove: (index) async {
          removed = index;
          return true;
        },
      ),
    );
    expect(find.byTooltip('Eliminar fotografía 2'), findsNothing);

    await tester.tap(find.widgetWithText(TriageSectionAction, 'Editar').first);
    await tester.pump();
    await tester.tap(find.byTooltip('Eliminar fotografía 2'));
    expect(removed, 1);

    await tester.tap(find.text('Listo'));
    await tester.pump();
    expect(find.byTooltip('Eliminar fotografía 2'), findsNothing);
  });

  testWidgets('mientras sube muestra progreso en lugar de «Añadir»', (
    tester,
  ) async {
    await tester.pumpWidget(_tab(isUploading: true));
    expect(find.byType(TriagePhoto), findsNWidgets(2));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Subiendo fotografía'), findsOneWidget);
  });

  testWidgets('tocar una foto abre el visor sin compartir', (tester) async {
    await tester.pumpWidget(_tab());
    await tester.tap(find.byType(TriagePhoto).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Foto 2 de 2'), findsOneWidget);
    expect(find.byTooltip('Eliminar fotografía'), findsOneWidget);
    expect(find.byTooltip('Compartir'), findsNothing);
  });

  group('descripción', () {
    Finder editButton() => find.descendant(
      of: find.byType(TriageSectionCard),
      matching: find.byType(TriageSectionAction),
    );

    testWidgets('se edita en una hoja y guarda el texto', (tester) async {
      String? saved;
      await tester.pumpWidget(_tab(onSave: (text) async => saved = text));
      await tester.tap(editButton());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Texto nuevo');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(saved, 'Texto nuevo');
      expect(find.byType(TriageSheet), findsNothing);
    });

    testWidgets('cerrar con la X no guarda', (tester) async {
      String? saved;
      await tester.pumpWidget(_tab(onSave: (text) async => saved = text));
      await tester.tap(editButton());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Descartado');
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
    });

    testWidgets('tocar fuera no descarta lo escrito', (tester) async {
      await tester.pumpWidget(_tab());
      await tester.tap(editButton());
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(TriageSheet), findsOneWidget);
    });

    testWidgets('vacía muestra su aviso', (tester) async {
      await tester.pumpWidget(_tab(description: '  '));
      expect(find.text('Sin descripción registrada.'), findsOneWidget);
    });
  });

  group('imágenes', () {
    test('usa el enlace firmado y, sin él, el archivo local', () {
      final images = IncidentDetailsViewMapper.photoImages(
        paths: const ['inc/a.jpg', '/data/antigua.jpg'],
        signedUrls: const {'inc/a.jpg': 'https://s.test/a'},
      );
      expect((images[0] as NetworkImage).url, 'https://s.test/a');
      expect((images[1] as FileImage).file.path, '/data/antigua.jpg');
    });
  });

  for (final (width, scale) in const [
    (280.0, 2.0),
    (393.0, 1.0),
    (800.0, 2.0),
  ]) {
    testWidgets('sin desbordes en $width al ${scale * 100} %', (tester) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_tab(photos: 5, textScale: scale));
      expect(tester.takeException(), isNull);
    });
  }
}
