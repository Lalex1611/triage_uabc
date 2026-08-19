import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/start_triage_header_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/start_triage_header_widget.dart';

/*
  COMANDO PARA PROBAR ESTE WIDGET AISLADO:
  flutter run -t test/features/paramedico/presentation/start_triage/widgets/start_triage_header_visual_test.dart
*/

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Theme(
        data: appTheme,
        child: Scaffold(
          backgroundColor: Colors.black, // Fondo negro puro
          body: SafeArea(
            child: Column(
              children: [
                StartTriageHeaderWidget(
                  data: StartTriageHeaderData(
                    patientNumber: 5,
                    onCloseTap: () =>
                        debugPrint('X Presionada - Cerrar Start Triage'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
