import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/shared/widgets/app_header.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_minidash_widget.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_search_bar_widget.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_patient_list_header_widget.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_patient_card_widget.dart';
import 'package:sistema_triage/features/medico/presentation/navigation/medico_navbar_widget.dart';

import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_user_stats.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_patient_card_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_patient_list_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

/*
  COMANDO PARA PROBAR TODO JUNTO: 
  flutter run -t test/features/medico/presentation/home/medico_home_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MedicoHomeVisualTest(),
    ),
  );
}

class MedicoHomeVisualTest extends StatefulWidget {
  const MedicoHomeVisualTest({super.key});

  @override
  State<MedicoHomeVisualTest> createState() => _MedicoHomeVisualTestState();
}

class _MedicoHomeVisualTestState extends State<MedicoHomeVisualTest> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    // MOCK DE ESTADÍSTICAS DEL MÉDICO
    const mockStats = MedicoUserStats(
      userName: 'Juan Ozuna',
      totalActive: 11,
      enCaminoCount: 2,
      rojoCriticoCount: 2,
      enColaCount: 7,
    );

    // MOCKS DE PACIENTES
    final mockPatients = [
      MedicoPatientCardData(
        id: 'PAC-28320',
        number: 1,
        triageCategory: TriageCategory.rojo,
        name: 'Paciente Numero 1 - 12-Mar-2026 14:32 - Blvd. 2000',
        dateStr: '12/03/206 14:32:54',
        coordinates: '19.4326, -99.1332',
        eta: 'A 10 Min...',
        ambulanceUnit: 'No. de Unidad: 156',
        status: PatientStatus.trasladando,
      ),
      MedicoPatientCardData(
        id: 'PAC-28320',
        number: 2,
        triageCategory: TriageCategory.amarillo,
        name: 'Paciente Numero 1 - 12-Mar-2026 14:32 - Blvd. 2000',
        dateStr: '12/03/206 14:32:54',
        coordinates: '19.4326, -99.1332',
        eta: 'A 10 Min...',
        ambulanceUnit: 'No. de Unidad: 156',
        status: PatientStatus.trasladando,
      ),
      MedicoPatientCardData(
        id: 'PAC-28325',
        number: 3,
        triageCategory: TriageCategory.rojo,
        name: 'Paciente Numero 1 - 12-Mar-2026 14:32 - Blvd. 2000',
        dateStr: '12/03/206 14:32:54',
        coordinates: '19.4326, -99.1332',
        eta: 'A 10 Min...',
        ambulanceUnit: 'No. de Unidad: 156',
        status: PatientStatus.trasladando,
      ),
      MedicoPatientCardData(
        id: 'PAC-28329',
        number: 4,
        triageCategory: TriageCategory.verde,
        name: 'Paciente Numero 4 - 12-Mar-2026 14:32 - Blvd. 2000',
        dateStr: '12/03/206 14:32:54',
        coordinates: '19.4326, -99.1332',
        eta: 'A 10 Min...',
        ambulanceUnit: 'No. de Unidad: 156',
        status: PatientStatus.trasladando,
      ),
      MedicoPatientCardData(
        id: 'PAC-28330',
        number: 5,
        triageCategory: TriageCategory.rojo,
        name: 'Paciente Numero 1 - 12-Mar-2026 14:32 - Blvd. 2000',
        dateStr: '12/03/206 14:32:54',
        coordinates: '19.4326, -99.1332',
        eta: 'A 10 Min...',
        ambulanceUnit: 'No. de Unidad: 156',
        status: PatientStatus.trasladando,
      ),
    ];

    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // --- SECCIÓN FIJA (HEADER Y DASHBOARD) ---
            AppHeader(
              type: HeaderType.home,
              color: AppColors.primaryMedico,
              isConnected: true,
              hasNotifications: false,
              subtitle: 'Cruz Roja - Tijuana',
              logoPath: AppIcons.medicoHeaderLogo,
              notificationIconPath: AppIcons.medicoHeaderNotification,
              profileIconPath: AppIcons.medicoHeaderProfile,
            ),
            const MedicoMinidash(userstats: mockStats),

            Transform.translate(
              offset: const Offset(0, -25),
              child: const MedicoSearchBar(),
            ),

            const SizedBox(height: 1),

            const MedicoPatientListHeader(
              data: MedicoPatientListHeaderData(patientCount: 5),
            ),

            const SizedBox(height: 10),

            // Sin pestaña Cola: mismo hueco que [MedicoHomePage] con showTriageFilters false.
            const SizedBox(height: 26),

            const SizedBox(height: 10),

            // --- SECCIÓN SCROLLEABLE (LISTA DE TARJETAS) ---
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 35,
                  vertical: 15,
                ),
                itemCount: mockPatients.length,
                separatorBuilder: (_, _) => const SizedBox(height: 15),
                itemBuilder: (context, index) {
                  return MedicoPatientCard(data: mockPatients[index]);
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: MedicoNavbar(
          currentIndex: _navIndex,
          onTap: (index) {
            setState(() {
              _navIndex = index;
            });
          },
        ),
      ),
    );
  }
}
