// Sandbox del paciente en sala del médico (mockup 06), con datos mock y sin
// backend. El botón flotante alterna entre "en sala" y "dado de alta".
//
// Run:
// flutter run -t test/features/medico/presentation/room_patient/medico_room_patient_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_review/medico_incoming_review.dart';
import 'package:sistema_triage/features/medico/domain/entities/room_patient/medico_attention_note.dart';
import 'package:sistema_triage/features/medico/presentation/room_patient/medico_room_patient_page.dart';
import 'package:sistema_triage/features/medico/presentation/room_patient/widgets/medico_attention_note_dialog.dart';
import 'package:sistema_triage/features/medico/presentation/room_patient/widgets/medico_room_photos_history_widget.dart';
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
  bool _discharged = false;
  final List<MedicoAttentionNote> _notes = [
    MedicoAttentionNote(
      id: '1',
      body:
          'Ingresa consciente. Se canaliza vía periférica y se inicia analgesia.',
      authorName: 'Dra. Sofía Ramírez',
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Stack(
      children: [
        MedicoRoomPatientPage(
          summary: const MedicoIncomingReview(
            patientId: '2031a7c0-0000-0000-0000-000000000000',
            displayName: 'Alberto Pérez',
            triage: TriageCategory.rojo,
            ageYears: 34,
            incidentId: '729ab000-0000-0000-0000-000000000000',
            emergencyTypeLabel: 'Choque múltiple',
            paramedicName: 'Carlos Huerta',
            unitCode: 'A-12',
            hasInsurance: true,
            insuranceInstitution: 'IMSS',
            injuryLabels: ['Fractura', 'Hemorragia'],
            reportedDescription:
                'Conductor prensado 20 min. Sangrado activo en pierna derecha '
                'controlado con torniquete. Posible fractura de fémur.',
          ),
          discharged: _discharged,
          receivedAt: now.subtract(const Duration(minutes: 4)),
          dischargedAt: _discharged ? now : null,
          consultationCode: 'ABK37X',
          photos: const [],
          notes: _notes,
          history: const [
            MedicoRoomHistoryItem(
              time: '14:52',
              event: 'Recibido en sala',
              actor: 'Médico',
            ),
            MedicoRoomHistoryItem(
              time: '14:38',
              event: 'En camino al hospital',
              actor: 'Paramédico',
            ),
            MedicoRoomHistoryItem(
              time: '14:34',
              event: 'Registrado como Rojo',
              actor: 'Paramédico',
            ),
          ],
          now: now,
          onBackTap: () => debugPrint('atrás'),
          onEditPatientTap: () => debugPrint('editar paciente'),
          onShowQrTap: () => debugPrint('mostrar QR'),
          onAddNoteTap: _discharged
              ? null
              : () => MedicoAttentionNoteDialog.show(
                  context,
                  onSave: (body) async {
                    await Future.delayed(const Duration(milliseconds: 600));
                    setState(
                      () => _notes.insert(
                        0,
                        MedicoAttentionNote(
                          id: '${_notes.length + 1}',
                          body: body.trim(),
                          authorName: 'Dra. Sofía Ramírez',
                          createdAt: DateTime.now(),
                        ),
                      ),
                    );
                  },
                ),
          onAddPhotoTap: _discharged ? null : () => debugPrint('añadir foto'),
          onDischargeTap: _discharged
              ? null
              : () => setState(() => _discharged = true),
        ),
        Positioned(
          right: 16,
          bottom: 180,
          child: FloatingActionButton.small(
            tooltip: 'Alternar alta',
            onPressed: () => setState(() => _discharged = !_discharged),
            child: const Icon(Icons.swap_horiz),
          ),
        ),
      ],
    );
  }
}
