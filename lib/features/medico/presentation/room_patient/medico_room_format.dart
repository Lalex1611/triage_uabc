import 'package:sistema_triage/features/medico/domain/entities/patient_details/patient_triage_history_entry.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

/// Textos de la vista de paciente en sala (mockup 06)
abstract final class MedicoRoomFormat {
  /// Nombre del nivel hospitalario: "atención inmediata", "emergencia", ...
  static String levelName(TriageCategory c) => switch (c) {
    TriageCategory.rojo => 'atención inmediata',
    TriageCategory.naranja => 'emergencia',
    TriageCategory.amarillo => 'urgente',
    TriageCategory.verde => 'poco urgente',
    TriageCategory.azul => 'no urgente',
    TriageCategory.negro => 'sin signos vitales',
    TriageCategory.todos => '',
  };

  static String colorName(String raw) {
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1);
  }

  static String hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// "4 min", "1 h 20 min", "2 días"
  static String duration(Duration d) {
    if (d.inMinutes < 1) return 'menos de 1 min';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 24) {
      final m = d.inMinutes % 60;
      return m == 0 ? '${d.inHours} h' : '${d.inHours} h $m min';
    }
    return d.inDays == 1 ? '1 día' : '${d.inDays} días';
  }

  /// "Recibido a las 14:52 · lleva 4 min en sala" o, si ya tiene alta,
  /// "Alta a las 16:10 · estuvo 1 h 18 min en sala"
  static String stayLine({
    required bool discharged,
    DateTime? receivedAt,
    DateTime? dischargedAt,
    required DateTime now,
  }) {
    if (discharged) {
      if (dischargedAt == null) return 'Dado de alta';
      final stay = receivedAt == null
          ? ''
          : ' · estuvo ${duration(dischargedAt.difference(receivedAt))} en sala';
      return 'Alta a las ${hhmm(dischargedAt)}$stay';
    }
    if (receivedAt == null) return 'En sala';
    return 'Recibido a las ${hhmm(receivedAt)} · lleva '
        '${duration(now.difference(receivedAt))} en sala';
  }

  static String _status(String s) => switch (s) {
    'en_espera' => 'En espera',
    'trasladando' => 'En camino al hospital',
    'recibido' => 'Recibido en sala',
    'alta_medica' => 'Alta médica',
    _ => s,
  };

  /// Una línea por evento del historial: "Recibido en sala", "Triage Naranja
  /// → Rojo", "Registrado como Amarillo"
  static String historyEvent(PatientTriageHistoryEntry e) {
    final f = e.changedFields;
    if (f.contains('created')) {
      return 'Registrado como ${e.newTriageColor.code}';
    }
    final parts = <String>[
      if (f.contains('status')) _status(e.newStatus),
      if (f.contains('triage_color'))
        'Triage ${e.oldTriageColor?.code ?? '—'} → ${e.newTriageColor.code}',
    ];
    return parts.isEmpty ? 'Actualización' : parts.join(' · ');
  }

  /// "14:52" si es de hoy; "12/11 14:52" si es de otro día
  static String historyTime(DateTime at, DateTime now) {
    final sameDay =
        at.year == now.year && at.month == now.month && at.day == now.day;
    if (sameDay) return hhmm(at);
    final dd = at.day.toString().padLeft(2, '0');
    final mm = at.month.toString().padLeft(2, '0');
    return '$dd/$mm ${hhmm(at)}';
  }
}
