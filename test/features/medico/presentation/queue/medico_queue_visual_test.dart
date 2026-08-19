// Sandbox maestro de la pantalla de Cola del médico.
// Ensambla todos los widgets con datos mock e interactividad local.
//
// Run:
// flutter run -t test/features/medico/presentation/queue/medico_queue_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_sorting_options.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_queue_filter.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_category.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_filter_chips_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_patient_card_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_role_title_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_section_header_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_stats_data.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_search_bar_widget.dart';
import 'package:sistema_triage/features/medico/presentation/navigation/medico_navbar_widget.dart';
import 'package:sistema_triage/features/medico/presentation/queue/medico_queue_page.dart';
import 'package:sistema_triage/features/medico/presentation/queue/widgets/medico_queue_filter_chips_widget.dart';
import 'package:sistema_triage/features/medico/presentation/queue/widgets/medico_queue_patient_card_widget.dart';
import 'package:sistema_triage/features/medico/presentation/queue/widgets/medico_queue_role_title_widget.dart';
import 'package:sistema_triage/features/medico/presentation/queue/widgets/medico_queue_section_header_widget.dart';
import 'package:sistema_triage/features/medico/presentation/queue/widgets/medico_queue_stats_widget.dart';
import 'package:sistema_triage/shared/widgets/app_header.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _Sandbox(),
  ));
}

class _Sandbox extends StatefulWidget {
  const _Sandbox();

  @override
  State<_Sandbox> createState() => _SandboxState();
}

class _SandboxState extends State<_Sandbox> {
  /// La app ya no expone la pestaña Cola; el índice es solo decorativo en este sandbox.
  int _navIndex = 0;
  MedicoQueueFilter _filter = MedicoQueueFilter.enCamino;
  MedicoPatientSortOption _sort = MedicoPatientSortOption.recent;

  late final List<MedicoQueuePatientCardData> _patients = _buildMockPatients();

  List<MedicoQueuePatientCardData> _buildMockPatients() {
    return [
      MedicoQueuePatientCardData(
        patientId: 'PAC-28320',
        level: 1,
        category: MedicoTriageCategory.rojo,
        patientLine: 'Paciente Numero 1 - 12-Mar-2026 14:32 - Blvd. 2000',
        ingressLabel: 'Ingresó hace 5 minutos',
        registrationDateTime: '12/03/206 14:32:54',
        onCardTap: () => debugPrint('open patient 1'),
        onCallTap: () => debugPrint('call patient 1'),
      ),
      MedicoQueuePatientCardData(
        patientId: 'PAC-28320',
        level: 2,
        category: MedicoTriageCategory.amarillo,
        patientLine: 'Paciente Numero 2 - 12-Mar-2026 14:32 - Blvd. 2000',
        ingressLabel: 'Ingresó hace 12 minutos',
        registrationDateTime: '12/03/206 14:32:54',
        onCardTap: () => debugPrint('open patient 2'),
        onCallTap: () => debugPrint('call patient 2'),
      ),
      MedicoQueuePatientCardData(
        patientId: 'PAC-28320',
        level: 2,
        category: MedicoTriageCategory.amarillo,
        patientLine: 'Paciente Numero 3 - 12-Mar-2026 14:32 - Blvd. 2000',
        ingressLabel: 'Ingresó hace 10 minutos',
        registrationDateTime: '12/03/206 14:32:54',
        onCardTap: () => debugPrint('open patient 3'),
        onCallTap: () => debugPrint('call patient 3'),
      ),
      MedicoQueuePatientCardData(
        patientId: 'PAC-28320',
        level: 2,
        category: MedicoTriageCategory.verde,
        patientLine: 'Paciente Numero 4 - 12-Mar-2026 14:32 - Blvd. 2000',
        ingressLabel: 'Ingresó hace 20 minutos',
        registrationDateTime: '12/03/206 14:32:54',
        onCardTap: () => debugPrint('open patient 4'),
        onCallTap: () => debugPrint('call patient 4'),
      ),
      MedicoQueuePatientCardData(
        patientId: 'PAC-28320',
        level: 3,
        category: MedicoTriageCategory.naranja,
        patientLine: 'Paciente Numero 5 - 12-Mar-2026 14:32 - Blvd. 2000',
        ingressLabel: 'Ingresó hace 30 minutos',
        registrationDateTime: '12/03/206 14:32:54',
        onCardTap: () => debugPrint('open patient 5'),
        onCallTap: () => debugPrint('call patient 5'),
      ),
    ];
  }

  void _onSortTap(MedicoPatientSortOption newSort) {
    setState(() {
      _sort = newSort;
    });
  }

  @override
  Widget build(BuildContext context) {
    const stats = MedicoQueueStatsData(
      enCaminoCount: 2,
      rojosCriticosCount: 2,
      enColaCount: 7,
    );
    const roleTitle = MedicoQueueRoleTitleData(
      roleLabel: 'Personal de hospitalario',
      userName: 'Juan Ozuna',
      currentPatientCount: 11,
    );

    return MedicoQueuePage(
      appHeader: const AppHeader(
        type: HeaderType.home,
        color: AppColors.primaryMedico,
        isConnected: true,
        hasNotifications: false,
        subtitle: 'Cruz Roja - Tijuana',
        logoPath: AppIcons.medicoHeaderLogo,
        notificationIconPath: AppIcons.medicoHeaderNotification,
        profileIconPath: AppIcons.medicoHeaderProfile,
      ),
      fixedSection: [
        Container(
          color: AppColors.primaryMedico,
          padding: const EdgeInsets.only(top: 8, bottom: 45),
          child: Column(
            children: const [
              MedicoQueueRoleTitleWidget(data: roleTitle),
              SizedBox(height: 14),
              MedicoQueueStatsWidget(data: stats),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -25),
          child: const MedicoSearchBar(),
        ),
        const SizedBox(height: 4),
        MedicoQueueSectionHeaderWidget(
          data: MedicoQueueSectionHeaderData(
            total: _patients.length,
            currentSort: _sort,
            onSortTap: _onSortTap,
          ),
        ),
        const SizedBox(height: 12),
        MedicoQueueFilterChipsWidget(
          data: MedicoQueueFilterChipsData(
            selectedFilter: _filter,
            onFilterSelected: (f) => setState(() => _filter = f),
          ),
        ),
        const SizedBox(height: 8),
      ],
      scrollableSection: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        itemCount: _patients.length,
        itemBuilder: (context, index) {
          return MedicoQueuePatientCardWidget(data: _patients[index]);
        },
      ),
      bottomNavbar: MedicoNavbar(
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
      ),
    );
  }
}
