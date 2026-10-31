import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/incident_for_cards.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

// Tarjeta de incidente adaptada al estándar oficial del sistema de diseño (B02)
class IncidentCard extends StatelessWidget {
  final IncidentForCards incident;
  final bool selected;
  final VoidCallback? onTap;

  const IncidentCard({
    super.key,
    required this.incident,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locationText = '${incident.latitude}, ${incident.longitude}';

    final timeText = incident.dateTime.toString().substring(0, 16);

    return TriageIncidentCard(
      folio: incident.id,
      timeAgo: timeText,
      title: incident.name_card,
      location: locationText,
      selected: selected,
      patientCount: incident.totalVictims,
      onTap: onTap,
      counts: {
        TriageLevel.red: incident.red,
        TriageLevel.yellow: incident.yellow,
        TriageLevel.green: incident.green,
        TriageLevel.black: incident.black,
      },
    );
  }
}
