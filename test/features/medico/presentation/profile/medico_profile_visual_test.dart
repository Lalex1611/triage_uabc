// Sandbox del perfil del médico (mockup 13) con datos mock, sin backend.
//
// Run:
// flutter run -t test/features/medico/presentation/profile/medico_profile_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/profile/medico_profile_menu_item_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/profile/medico_profile_section_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/profile/medico_profile_summary.dart';
import 'package:sistema_triage/features/medico/presentation/navigation/medico_navbar_widget.dart';
import 'package:sistema_triage/features/medico/presentation/profile/medico_profile_page.dart';
import 'package:sistema_triage/features/medico/presentation/profile/widgets/medico_capacity_edit_sheet.dart';

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
  MedicoHospitalCapacity _capacity = const MedicoHospitalCapacity(
    shockBedsFree: 2,
    shockBedsTotal: 6,
    observationBedsFree: 5,
    observationBedsTotal: 14,
    acceptingRedPatients: true,
    operatingRoomAvailable: false,
  );

  String _yesNo(bool? v) => v == null ? '—' : (v ? 'Sí' : 'No');

  @override
  Widget build(BuildContext context) {
    final c = _capacity;
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      body: MedicoProfilePage(
        userName: 'Dra. Mariana Ruiz',
        hospitalLabel: 'Hospital General de Tijuana · Urgencias',
        loading: false,
        onRefresh: () async {},
        onBackTap: () => debugPrint('atrás'),
        onSignOutTap: () => debugPrint('cerrar sesión'),
        menuItems: [
          for (final (icon, label) in const [
            (Icons.notifications_none_rounded, 'Notificaciones'),
            (Icons.verified_user_outlined, 'Privacidad y permisos'),
            (Icons.error_outline_rounded, 'Ayuda y soporte'),
            (Icons.description_outlined, 'Términos y aviso de privacidad'),
          ])
            MedicoProfileMenuItemData(
              icon: icon,
              label: label,
              onTap: () => debugPrint(label),
            ),
        ],
        sections: [
          MedicoProfileSectionData(
            title: 'Capacidad de urgencias',
            actionLabel: 'Editar',
            footnote: 'Actualizado hace 5 min',
            onActionTap: () async {
              await MedicoCapacityEditSheet.show(
                context,
                initial: _capacity,
                onSave: (n) async => setState(() => _capacity = n),
              );
            },
            rows: [
              MedicoProfileRowData(
                label: 'Camas de choque libres',
                value: '${c.shockBedsFree} de ${c.shockBedsTotal}',
              ),
              MedicoProfileRowData(
                label: 'Camas de observación libres',
                value: '${c.observationBedsFree} de ${c.observationBedsTotal}',
              ),
              MedicoProfileRowData(
                label: 'Recibiendo pacientes rojos',
                value: _yesNo(c.acceptingRedPatients),
              ),
              MedicoProfileRowData(
                label: 'Quirófano disponible',
                value: _yesNo(c.operatingRoomAvailable),
              ),
            ],
          ),
          const MedicoProfileSectionData(
            title: 'Guardia de hoy',
            rows: [
              MedicoProfileRowData(label: 'Pacientes recibidos', value: '9'),
              MedicoProfileRowData(label: 'Traslados rechazados', value: '1'),
              MedicoProfileRowData(label: 'Altas registradas', value: '4'),
              MedicoProfileRowData(label: 'En sala ahora', value: '7'),
            ],
          ),
        ],
      ),
      bottomNavigationBar: MedicoNavbar(currentIndex: 3, onTap: (_) {}),
    );
  }
}
