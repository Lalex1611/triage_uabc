import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(Widget child, {TriageRoleTheme? role, double textScale = 1}) =>
    MaterialApp(
      theme: ThemeData(extensions: [?role]),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(TriageSpacing.lg),
          child: child,
        ),
      ),
    );

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

InputDecoration _decoration(WidgetTester tester) =>
    tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration;

void main() {
  testWidgets('la etiqueta visible es el nombre del campo para el lector', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const TriageField(label: 'Correo', hint: 'nombre@correo.com')),
    );
    expect(find.text('Correo'), findsOneWidget);
    // Se anuncia la etiqueta y después la sugerencia
    final node = tester.getSemantics(find.byType(TextField));
    expect(node, isSemantics(isTextField: true));
    expect(node.label, startsWith('Correo'));
  });

  testWidgets('alto mínimo de 48 y sugerencia con contraste ≥ 4.5', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const TriageField(label: 'Nombre')));
    expect(
      tester.getSize(find.byType(TextField)).height,
      greaterThanOrEqualTo(TriageSizes.touchTarget),
    );
    expect(
      _contrast(_decoration(tester).hintStyle!.color!, TriageColors.surface),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('enfocado toma el color del rol', (tester) async {
    await tester.pumpWidget(
      _wrap(const TriageField(label: 'Nombre'), role: TriageRoleTheme.hospital),
    );
    await tester.pumpAndSettle();
    final focused = _decoration(tester).focusedBorder!;
    expect(focused.borderSide.color, TriageColors.hospitalAccent);
  });

  testWidgets('dentro de un Form muestra el error del validador', (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      _wrap(
        Form(
          key: form,
          child: TriageField(
            label: 'Nombre',
            validator: (v) => v!.isEmpty ? 'Escribe el nombre' : null,
          ),
        ),
      ),
    );
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Escribe el nombre'), findsOneWidget);
    expect(
      _decoration(tester).errorBorder!.borderSide.color,
      TriageColors.danger,
    );
  });

  testWidgets('desactivado usa el fondo hundido', (tester) async {
    await tester.pumpWidget(
      _wrap(const TriageField(label: 'Folio', enabled: false)),
    );
    expect(_decoration(tester).fillColor, TriageColors.sunken);
  });

  testWidgets('el área arranca en tres líneas y crece con el texto', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            const TriageField(label: 'Nombre'),
            TriageField.area(label: 'Descripción', controller: controller),
          ],
        ),
      ),
    );
    double height(int i) => tester.getSize(find.byType(TextField).at(i)).height;
    final empty = height(1);
    expect(empty, greaterThan(height(0) * 1.5));

    controller.text = List.filled(6, 'línea').join('\n');
    await tester.pump();
    expect(height(1), greaterThan(empty));
  });

  testWidgets('con texto al 200 % no se desborda', (tester) async {
    tester.view.physicalSize = const Size(960, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _wrap(
        const TriageField(
          label: 'Nombre completo del paciente',
          errorText: 'Escribe nombre y apellidos para identificarlo',
        ),
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  group('TriageSelectField', () {
    testWidgets('despliega las opciones y avisa la elegida', (tester) async {
      String? chosen;
      await tester.pumpWidget(
        _wrap(
          TriageSelectField<String>(
            label: 'Sexo',
            hint: 'Selecciona',
            options: const ['F', 'M'],
            optionLabel: (o) => o == 'F' ? 'Femenino' : 'Masculino',
            onChanged: (v) => chosen = v,
          ),
        ),
      );
      expect(find.text('Selecciona'), findsOneWidget);
      expect(find.byType(TriageIcon), findsOneWidget);

      await tester.tap(find.text('Selecciona'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Masculino').last);
      await tester.pumpAndSettle();
      expect(chosen, 'M');
      expect(find.text('Masculino'), findsOneWidget);
    });

    testWidgets('misma caja que el campo de texto', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TriageSelectField<int>(
            label: 'Nivel',
            options: const [1, 2],
            optionLabel: (o) => '$o',
          ),
        ),
      );
      final decoration = _decoration(tester);
      expect(decoration.fillColor, TriageColors.surface);
      expect(
        decoration.enabledBorder!.borderSide.color,
        TriageColors.borderMedium,
      );
      expect(
        tester.getSemantics(find.text('Nivel')),
        isSemantics(label: 'Nivel', isButton: true),
      );
    });
  });
}
