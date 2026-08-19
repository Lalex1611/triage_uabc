import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/presentation/home/widgets/sort_and_filter_widget.dart';

/*
  COMANDO PARA PROBAR: 
  flutter run -t test/features/paramedico/presentation/home/widgets/sort_and_filter_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SortAndFilterVisualTest(),
    ),
  );
}

class SortAndFilterVisualTest extends StatelessWidget {
  const SortAndFilterVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(top: 100),
            child: SortAndFilter(totalIncidents: 25),
          ),
        ),
      ),
    );
  }
}
