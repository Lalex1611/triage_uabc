import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_user_stats.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_minidash_widget.dart';

/*
  COMANDO PARA PROBAR: 
  flutter run -t test/features/medico/presentation/home/widgets/medico_minidash_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MedicoMinidashVisualTest(),
    ),
  );
}

class MedicoMinidashVisualTest extends StatelessWidget {
  const MedicoMinidashVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    const mockStats = MedicoUserStats(
      userName: 'Juan Ozuna',
      totalActive: 11,
      enCaminoCount: 2,
      rojoCriticoCount: 2,
      enColaCount: 7,
    );

    return Theme(
      data: appTheme,
      child: const Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(children: [MedicoMinidash(userstats: mockStats)]),
          ),
        ),
      ),
    );
  }
}
