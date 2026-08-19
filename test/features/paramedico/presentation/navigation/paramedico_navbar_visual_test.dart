import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/presentation/navigation/paramedico_navbar_widget.dart';

/*
  COMANDO PARA PROBAR: 
  flutter run -t test/features/paramedico/presentation/navigation/paramedico_navbar_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ParamedicoNavbarVisualTest(),
    ),
  );
}

class ParamedicoNavbarVisualTest extends StatefulWidget {
  const ParamedicoNavbarVisualTest({super.key});

  @override
  State<ParamedicoNavbarVisualTest> createState() =>
      _ParamedicoNavbarVisualTestState();
}

class _ParamedicoNavbarVisualTestState
    extends State<ParamedicoNavbarVisualTest> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'Tab seleccionado: $_currentIndex',
            style: AppTextStyles.ESC_Bold_titleLarge,
          ),
        ),
        bottomNavigationBar: ParamedicoNavbar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
