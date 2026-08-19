import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/home_user_stats.dart';
import 'package:sistema_triage/features/paramedico/presentation/home/widgets/minidash_widget.dart';

/*
  COMANDO PARA PROBAR: 
  flutter run -t test/features/paramedico/presentation/home/widgets/minidash_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MinidashVisualTest(),
    ),
  );
}

class MinidashVisualTest extends StatelessWidget {
  const MinidashVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de prueba (MOCK)
    const mockStats = HomeUserStats(
      userName: 'Carlos Huerta',
      totalActive: 11,
      redCount: 0,
      yellowCount: 4,
      greenCount: 7,
    );

    return Theme(
      data: appTheme,
      child: const Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(children: [Minidash(userstats: mockStats)]),
          ),
        ),
      ),
    );
  }
}
