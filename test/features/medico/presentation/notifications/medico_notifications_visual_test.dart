// Sandbox de las notificaciones del médico (mockup 12), con datos mock y sin
// backend. Tocar una notificación la marca como leída.
//
// Run:
// flutter run -t test/features/medico/presentation/notifications/medico_notifications_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_notification_item.dart';
import 'package:sistema_triage/features/medico/presentation/notifications/medico_notifications_page.dart';

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
  static final _now = DateTime.now();

  late List<MedicoNotificationItem> _items = [
    MedicoNotificationItem(
      id: '1',
      title: 'Paciente en camino',
      body: '',
      kind: 'incoming_transfer',
      patientId: '2031a7c0-0000-0000-0000-000000000000',
      createdAt: _now.subtract(const Duration(minutes: 1)),
      metadata: {
        'patient_display_name': 'Alberto Pérez',
        'triage_color': 'rojo',
        'incident_id': '729ab000-0000-0000-0000-000000000000',
        'estimated_arrival_at': _now
            .add(const Duration(minutes: 6, seconds: 30))
            .toIso8601String(),
      },
    ),
    MedicoNotificationItem(
      id: '2',
      title: 'Paciente en camino',
      body: '',
      kind: 'incoming_transfer',
      patientId: '2033b1d0-0000-0000-0000-000000000000',
      createdAt: _now.subtract(const Duration(minutes: 4)),
      metadata: {
        'patient_display_name': 'Ramiro Hernández',
        'triage_color': 'amarillo',
        'incident_id': '731cd000-0000-0000-0000-000000000000',
        'estimated_arrival_at': _now
            .add(const Duration(minutes: 14, seconds: 30))
            .toIso8601String(),
      },
    ),
    MedicoNotificationItem(
      id: '3',
      title: 'Nuevo registro en hospital',
      body: 'Laura Gil',
      kind: 'walk_in_registered',
      patientId: '2040e000-0000-0000-0000-000000000000',
      createdAt: _now.subtract(const Duration(minutes: 18)),
      readAt: _now,
    ),
    MedicoNotificationItem(
      id: '4',
      title: 'Alta registrada',
      body: '',
      kind: 'patient_discharged',
      patientId: '2018f000-0000-0000-0000-000000000000',
      createdAt: _now.subtract(const Duration(minutes: 40)),
      readAt: _now,
      metadata: const {'patient_display_name': 'Rosa Méndez'},
    ),
    MedicoNotificationItem(
      id: '5',
      title: 'Capacidad al límite',
      body: 'Quedan 2 camas de choque disponibles en urgencias.',
      kind: 'capacity_low',
      createdAt: _now.subtract(const Duration(hours: 1)),
      readAt: _now,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MedicoNotificationsPage(
      items: _items,
      onBackTap: () => debugPrint('atrás'),
      onItemTap: (n) => setState(() {
        _items = [
          for (final i in _items)
            i.id == n.id
                ? MedicoNotificationItem(
                    id: i.id,
                    title: i.title,
                    body: i.body,
                    kind: i.kind,
                    patientId: i.patientId,
                    createdAt: i.createdAt,
                    readAt: DateTime.now(),
                    metadata: i.metadata,
                  )
                : i,
        ];
      }),
    );
  }
}
