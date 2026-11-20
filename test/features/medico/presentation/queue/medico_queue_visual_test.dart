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
import 'package:sistema_triage/features/medico/domain/constants/medico_queue_patient_status.dart';
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
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: _Sandbox()),
  );
}

class _Sandbox extends StatefulWidget {
  const _Sandbox();

  @override
  State<_Sandbox> createState() => _SandboxState();
}

class _SandboxState extends State<_Sandbox> {
  /// La app ya no expone la pestaña Cola; el índice es solo decorativo en este sandbox.
  int _navIndex = 0;
  MedicoQueueFilter _filter = MedicoQueueFilter.todos;
  MedicoPatientSortOption _sort = MedicoPatientSortOption.recent;

  late final List<MedicoQueuePatientCardData> _patients = _buildMockPatients();

  List<MedicoQueuePatientCardData> _buildMockPatients() {
    return [
      MedicoQueuePatientCardData(
        level: 1,
        levelColor: MedicoTriageCategory.rojo.color,
        name: 'Alberto Pérez',
        status: MedicoQueuePatientStatus.recibido,
        subtitle: 'Hace 4 min · del incidente INC-729',
        onTap: () => debugPrint('open patient 1'),
      ),
      MedicoQueuePatientCardData(
        level: 1,
        levelColor: MedicoTriageCategory.rojo.color,
        name: 'Paciente sin identificar',
        status: MedicoQueuePatientStatus.recibido,
        subtitle: 'Hace 9 min · del incidente INC-729',
        onTap: () => debugPrint('open patient 2'),
      ),
      MedicoQueuePatientCardData(
        level: 2,
        levelColor: MedicoTriageCategory.naranja.color,
        name: 'Lourdes Carrillo',
        status: MedicoQueuePatientStatus.enEspera,
        subtitle: 'Hace 22 min · llegó por su cuenta',
        onTap: () => debugPrint('open patient 3'),
      ),
      MedicoQueuePatientCardData(
        level: 3,
        levelColor: MedicoTriageCategory.amarillo.color,
        name: 'Ramiro Hernández',
        status: MedicoQueuePatientStatus.enEspera,
        subtitle: 'Hace 35 min · del incidente INC-731',
        onTap: () => debugPrint('open patient 4'),
      ),
      MedicoQueuePatientCardData(
        level: 4,
        levelColor: MedicoTriageCategory.verde.color,
        name: 'Sofía Ibarra',
        status: MedicoQueuePatientStatus.alta,
        subtitle: 'Hace 51 min · llegó por su cuenta',
        onTap: () => debugPrint('open patient 5'),
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
