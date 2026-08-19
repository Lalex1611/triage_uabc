import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/consulta_externa/domain/constants/consulta_status.dart';
import 'package:sistema_triage/features/consulta_externa/domain/consulta_lookup_result.dart';
import 'package:sistema_triage/features/consulta_externa/presentation/screens/consulta_input_screen.dart';
import 'package:sistema_triage/features/consulta_externa/presentation/screens/consulta_status_screen.dart';

void main() {
  runApp(
    Theme(
      data: appTheme,
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ConsultaVisualTest(),
      ),
    ),
  );
}

class ConsultaVisualTest extends StatefulWidget {
  const ConsultaVisualTest({super.key});

  @override
  State<ConsultaVisualTest> createState() => _ConsultaVisualTestState();
}

class _ConsultaVisualTestState extends State<ConsultaVisualTest> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
        const ConsultaInputScreen(),
        ConsultaStatusScreen(
          result: ConsultaLookupResult(status: ConsultaStatus.enEspera),
        ),
        ConsultaStatusScreen(
          result: ConsultaLookupResult(status: ConsultaStatus.trasladando),
        ),
        ConsultaStatusScreen(
          result: ConsultaLookupResult(
            status: ConsultaStatus.recibido,
            hospitalName: 'Hospital General de ejemplo',
            hospitalAddress: 'Av. Ejemplo 123',
            hospitalPhone: '664-000-0000',
          ),
        ),
        ConsultaStatusScreen(
          result: ConsultaLookupResult(status: ConsultaStatus.alta),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1D71B8),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.input), label: 'Input'),
          BottomNavigationBarItem(icon: Icon(Icons.monitor_heart), label: 'En Escena'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Trasladando'),
          BottomNavigationBarItem(icon: Icon(Icons.domain_verification), label: 'Recibido'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Alta'),
        ],
      ),
    );
  }
}
