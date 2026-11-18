import 'package:sistema_triage/features/medico/domain/constants/medico_discharge_destination.dart';

/// Alta médica registrada (`patient_discharges`): destino, nota, quién y cuándo
class MedicoDischargeInfo {
  final MedicoDischargeDestination? destination;
  final String? note;
  final String? dischargedByName;
  final DateTime? createdAt;

  const MedicoDischargeInfo({
    this.destination,
    this.note,
    this.dischargedByName,
    this.createdAt,
  });

  static const maxNoteLength = 2000;

  factory MedicoDischargeInfo.fromRow(Map<String, dynamic> row) {
    final by = row['by'];
    final name = by is Map ? (by['full_name'] as String?)?.trim() : null;
    final note = (row['note'] as String?)?.trim();
    return MedicoDischargeInfo(
      destination: MedicoDischargeDestination.fromDb(
        row['destination'] as String?,
      ),
      note: (note == null || note.isEmpty) ? null : note,
      dischargedByName: (name == null || name.isEmpty) ? null : name,
      createdAt: DateTime.tryParse(
        row['created_at'] as String? ?? '',
      )?.toLocal(),
    );
  }
}
