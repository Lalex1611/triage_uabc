import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/triage_color_grid_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/triage_color_grid_widget.dart';

/*
  COMANDO PARA PROBAR ESTE WIDGET AISLADO:
  flutter run -t test/features/paramedico/presentation/start_triage/widgets/triage_color_grid_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TriageColorGridSandbox(),
    ),
  );
}

class TriageColorGridSandbox extends StatelessWidget {
  const TriageColorGridSandbox({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.black, // Fondo negro puro
        body: SafeArea(
          child: Center(
            child: TriageColorGridWidget(
              data: TriageColorGridData(
                categories: [
                  TriageCategory.rojo,
                  TriageCategory.amarillo,
                  TriageCategory.verde,
                  TriageCategory.negro,
                ],
                onColorSelected: (category) => debugPrint('Color seleccionado: \${category.label}'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
