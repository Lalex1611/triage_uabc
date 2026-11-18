// Sandbox de la pestaña Sala del médico (mockup 05).
// Ensambla todos los widgets con datos mock e interactividad local.
//
// Run:
// flutter run -t test/features/medico/presentation/queue/medico_queue_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_queue_filter.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_queue_patient_status.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_level.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_filter_chips_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_header_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_patient_card_data.dart';
import 'package:sistema_triage/features/medico/presentation/navigation/medico_navbar_widget.dart';
import 'package:sistema_triage/features/medico/presentation/queue/medico_queue_page.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

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
  int _navIndex = 1;
  MedicoQueueFilter _filter = MedicoQueueFilter.todos;

  MedicoQueuePatientCardData _card(
    TriageCategory cat,
    String name,
    MedicoQueuePatientStatus status,
    String subtitle,
  ) {
    return MedicoQueuePatientCardData(
      level: MedicoTriageLevel.levelOf(cat),
      levelColor: MedicoTriageLevel.colorOf(cat),
      name: name,
      status: status,
      subtitle: subtitle,
      onTap: () => debugPrint('open $name'),
    );
  }

  late final List<MedicoQueuePatientCardData> _all = [
    _card(
      TriageCategory.rojo,
      'Alberto Pérez',
      MedicoQueuePatientStatus.recibido,
      'Hace 4 min · del incidente INC-729',
    ),
    _card(
      TriageCategory.rojo,
      'Paciente sin identificar',
      MedicoQueuePatientStatus.recibido,
      'Hace 9 min · del incidente INC-729',
    ),
    _card(
      TriageCategory.naranja,
      'Lourdes Carrillo',
      MedicoQueuePatientStatus.enEspera,
      'Hace 22 min · llegó por su cuenta',
    ),
    _card(
      TriageCategory.amarillo,
      'Ramiro Hernández',
      MedicoQueuePatientStatus.enEspera,
      'Hace 35 min · del incidente INC-731',
    ),
    _card(
      TriageCategory.verde,
      'Sofía Ibarra',
      MedicoQueuePatientStatus.enEspera,
      'Hace 51 min · llegó por su cuenta',
    ),
    _card(
      TriageCategory.verde,
      'Mario López',
      MedicoQueuePatientStatus.alta,
      'Alta hace 2 h',
    ),
  ];

  List<MedicoQueuePatientCardData> get _visible => _all.where((p) {
    return switch (_filter) {
      MedicoQueueFilter.todos => p.status != MedicoQueuePatientStatus.alta,
      MedicoQueueFilter.enEspera =>
        p.status == MedicoQueuePatientStatus.enEspera,
      MedicoQueueFilter.recibidos =>
        p.status == MedicoQueuePatientStatus.recibido,
      MedicoQueueFilter.dadosDeAlta =>
        p.status == MedicoQueuePatientStatus.alta,
    };
  }).toList();

  @override
  Widget build(BuildContext context) {
    final levels = [
      TriageCategory.rojo,
      TriageCategory.naranja,
      TriageCategory.amarillo,
      TriageCategory.verde,
      TriageCategory.azul,
    ];
    const counts = [2, 1, 3, 1, 0];

    return Scaffold(
      backgroundColor: MedicoQueuePage.background,
      body: MedicoQueuePage(
        header: MedicoQueueHeaderData(
          patientsInCare: 7,
          levelCounts: [
            for (var i = 0; i < levels.length; i++)
              MedicoQueueLevelCount(
                color: MedicoTriageLevel.colorOf(levels[i]),
                count: counts[i],
              ),
          ],
          hasUnreadNotifications: true,
          onNotificationTap: () => debugPrint('notificaciones'),
        ),
        filters: MedicoQueueFilterChipsData(
          selectedFilter: _filter,
          onFilterSelected: (f) => setState(() => _filter = f),
        ),
        patients: _visible,
      ),
      bottomNavigationBar: MedicoNavbar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}
