import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_search_bar_widget.dart';

/*
  COMANDO PARA PROBAR: 
  flutter run -t test/features/medico/presentation/home/widgets/medico_search_bar_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MedicoSearchBarVisualTest(),
    ),
  );
}

class MedicoSearchBarVisualTest extends StatelessWidget {
  const MedicoSearchBarVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: const Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(children: [SizedBox(height: 40), MedicoSearchBar()]),
          ),
        ),
      ),
    );
  }
}
