import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_discharge_destination.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_level.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_notification_item.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';

/// Cómo se ve una notificación en la lista (mockup 12)
class MedicoNotificationView {
  final String title;
  final String body;
  final IconData icon;

  /// Color del icono; el fondo del icono es este color muy claro
  final Color color;

  const MedicoNotificationView({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });
}

/// Arma título, texto, icono y color de cada tipo de notificación a partir de
/// `kind` y `metadata`. Si faltan datos se usa el título y texto guardados.
abstract final class MedicoNotificationFormat {
  static const _blue = Color(0xFF1C69AA);
  static const _green = Color(0xFF1E9E52);
  static const _amber = Color(0xFFD08A00);

  static MedicoNotificationView viewOf(MedicoNotificationItem n, DateTime now) {
    final m = n.metadata;
    final name = _text(m['patient_display_name']);
    final who = name == null ? null : _withFolio(name, n.patientId);

    switch (n.kind) {
      case 'incoming_transfer':
        final triage = _triage(m['triage_color']);
        final color = triage == null
            ? _blue
            : MedicoTriageLevel.colorOf(triage);
        final title = triage == null
            ? 'Paciente en camino'
            : 'Paciente ${triage.label.toLowerCase()} en camino';
        if (who == null) {
          return MedicoNotificationView(
            title: title,
            body: n.body,
            icon: Icons.local_shipping_outlined,
            color: color,
          );
        }
        final eta = DateTime.tryParse(
          m['estimated_arrival_at'] as String? ?? '',
        )?.toLocal();
        final String when;
        if (eta == null) {
          when = 'va en camino';
        } else {
          final mins = eta.difference(now).inMinutes;
          when = mins <= 0
              ? 'debe estar llegando'
              : mins == 1
              ? 'llega en 1 min'
              : 'llega en $mins min';
        }
        final incident = _text(m['incident_id']);
        final from = incident == null
            ? ''
            : ' desde ${IncidentPresentationFormatters.shortIncidentId(incident)}';
        return MedicoNotificationView(
          title: title,
          body: '$who $when$from.',
          icon: Icons.local_shipping_outlined,
          color: color,
        );

      case 'walk_in_registered':
        final bodyName = who ?? _withFolio(n.body, n.patientId);
        return MedicoNotificationView(
          title: 'Nuevo registro en sala',
          body: '$bodyName llegó por su cuenta y ya está en la sala.',
          icon: Icons.person_add_alt_1_outlined,
          color: _blue,
        );

      case 'patient_discharged':
        final destination = MedicoDischargeDestination.fromDb(
          m['destination'] as String?,
        );
        final String body;
        if (who == null) {
          body = n.body;
        } else {
          body = switch (destination) {
            MedicoDischargeDestination.domicilio =>
              '$who salió con alta a domicilio.',
            MedicoDischargeDestination.hospitalizacion =>
              '$who pasó a hospitalización.',
            MedicoDischargeDestination.traslado =>
              '$who fue trasladado a otra unidad.',
            MedicoDischargeDestination.defuncion =>
              'Se registró la defunción de $who.',
            null => '$who salió con alta médica.',
          };
        }
        return MedicoNotificationView(
          title: 'Alta registrada',
          body: body,
          icon: Icons.check_circle_outline_rounded,
          color: _green,
        );

      case 'capacity_low':
        return MedicoNotificationView(
          title: n.title.isEmpty ? 'Capacidad al límite' : n.title,
          body: n.body,
          icon: Icons.warning_amber_rounded,
          color: _amber,
        );

      default:
        return MedicoNotificationView(
          title: n.title,
          body: n.body,
          icon: Icons.notifications_none_rounded,
          color: _blue,
        );
    }
  }

  /// "hace 1 min", "hace 2 h", "hace 3 días"
  static String relativeTime(DateTime at, DateTime now) {
    final diff = now.difference(at.toLocal());
    if (diff.inMinutes < 1) return 'justo ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return diff.inDays == 1 ? 'hace 1 día' : 'hace ${diff.inDays} días';
  }

  static String _withFolio(String name, String? patientId) {
    if (patientId == null || patientId.isEmpty) return name;
    return '$name (${IncidentPresentationFormatters.shortPatientId(patientId)})';
  }

  static String? _text(Object? v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  static TriageCategory? _triage(Object? raw) {
    for (final c in TriageCategory.values) {
      if (c.name == raw && c != TriageCategory.todos) return c;
    }
    return null;
  }
}
