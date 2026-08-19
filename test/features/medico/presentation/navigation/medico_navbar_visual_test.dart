import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/presentation/navigation/medico_navbar_widget.dart';

/*
  COMANDO PARA PROBAR: 
  flutter run -t test/features/medico/presentation/navigation/medico_navbar_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MedicoNavbarVisualTest(),
    ),
  );
}

class MedicoNavbarVisualTest extends StatefulWidget {
  const MedicoNavbarVisualTest({super.key});

  @override
  State<MedicoNavbarVisualTest> createState() => _MedicoNavbarVisualTestState();
}

class _MedicoNavbarVisualTestState extends State<MedicoNavbarVisualTest> {
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
        bottomNavigationBar: MedicoNavbar(
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
