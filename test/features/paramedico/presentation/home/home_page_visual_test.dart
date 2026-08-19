import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/shared/widgets/app_header.dart';
import 'package:sistema_triage/features/paramedico/presentation/home/widgets/minidash_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/home/widgets/app_search_bar_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/home/widgets/sort_and_filter_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/home/widgets/incident_card_widget.dart';

import 'package:sistema_triage/features/paramedico/domain/entities/home/incident_for_cards.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/home_user_stats.dart';

/*
  COMANDO PARA PROBAR TODO JUNTO: 
  flutter run -t test/features/paramedico/presentation/home/home_page_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePageVisualTest(),
    ),
  );
}

class HomePageVisualTest extends StatelessWidget {
  const HomePageVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    // MOCK DE ESTADÍSTICAS DEL USUARIO
    final mockStats = HomeUserStats(
      userName: 'Carlos Huerta',
      totalActive: 11,
      redCount: 0,
      yellowCount: 4,
      greenCount: 7,
    );

    // MOCKS DE INCIDENTES (Más cantidad para probar el scroll)
    final mockIncidents = List.generate(
      10,
      (index) => IncidentForCards(
        id: '#INC-729',
        name_card: 'Incident #$index - Blvd. 2000',
        dateTime: DateTime.now(),
        latitude: 32.4841,
        longitude: -116.8920,
        red: index % 5,
        yellow: index % 3,
        green: 5,
        black: 0,
        totalVictims: 8,
        isMine: index % 2 == 0,
      ),
    );

    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // --- SECCIÓN FIJA (HEADER Y DASHBOARD) ---
            const AppHeader(
              type: HeaderType.home,
              color: Color(0xFFCE1125),
              isConnected: true,
              hasNotifications: false,
              subtitle: 'Cruz Roja - Tijuana',
            ),
            Minidash(userstats: mockStats),

            Transform.translate(
              offset: const Offset(0, -25),
              child: const AppSearchBar(),
            ),

            const SizedBox(height: 1),

            const SortAndFilter(totalIncidents: 25),

            const SizedBox(height: 10),

            // --- SECCIÓN SCROLLEABLE (LISTA DE TARJETAS) ---
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 35,
                  vertical: 15,
                ),
                itemCount: mockIncidents.length,
                separatorBuilder: (_, _) => const SizedBox(height: 15),
                itemBuilder: (context, index) {
                  return IncidentCard(incident: mockIncidents[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
