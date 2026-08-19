import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_sorting_options.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_triage_filter.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

/// Mapeos DB → catálogos de dominio y utilidades de listado (sin UI)
class ParamedicoCatalogMappers {
  ParamedicoCatalogMappers._();

  static TriageCategory triageFromDb(String raw) {
    switch (raw) {
      case 'rojo':
        return TriageCategory.rojo;
      case 'naranja':
        return TriageCategory.naranja;
      case 'amarillo':
        return TriageCategory.amarillo;
      case 'verde':
        return TriageCategory.verde;
      case 'azul':
        return TriageCategory.azul;
      case 'negro':
        return TriageCategory.negro;
      default:
        return TriageCategory.amarillo;
    }
  }

  static PatientStatus statusFromDb(String raw) {
    switch (raw) {
      case 'registrado':
        return PatientStatus.registrado;
      case 'en_espera':
        return PatientStatus.enEspera;
      case 'trasladando':
        return PatientStatus.trasladando;
      case 'recibido':
        return PatientStatus.recibido;
      case 'alta_medica':
        return PatientStatus.alta;
      default:
        return PatientStatus.registrado;
    }
  }

  static int triageGravityRank(String color) {
    switch (color) {
      case 'rojo':
        return 0;
      case 'naranja':
        return 1;
      case 'amarillo':
        return 2;
      case 'verde':
        return 3;
      case 'azul':
        return 4;
      case 'negro':
        return 5;
      default:
        return 6;
    }
  }

  static bool matchesTriageFilter(
    ParamedicoPatientRow p,
    PatientTriageFilter filter,
  ) {
    final c = p.triageColor;
    switch (filter) {
      case PatientTriageFilter.todos:
        return true;
      case PatientTriageFilter.amarillo:
        return c == 'amarillo' || c == 'naranja';
      case PatientTriageFilter.rojo:
        return c == 'rojo';
      case PatientTriageFilter.verde:
        return c == 'verde' || c == 'azul';
      case PatientTriageFilter.negro:
        return c == 'negro';
    }
  }

  static List<ParamedicoPatientRow> filterAndSortPatients({
    required List<ParamedicoPatientRow> patients,
    required String query,
    required PatientTriageFilter triageFilter,
    required PatientSortOption sortOption,
  }) {
    var list = List<ParamedicoPatientRow>.from(patients);
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.displayName.toLowerCase().contains(q) ||
                p.id.toLowerCase().contains(q),
          )
          .toList();
    }
    if (triageFilter != PatientTriageFilter.todos) {
      list = list.where((p) => matchesTriageFilter(p, triageFilter)).toList();
    }
    switch (sortOption) {
      case PatientSortOption.recent:
        list.sort((a, b) {
          final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return tb.compareTo(ta);
        });
      case PatientSortOption.gravity:
        list.sort(
          (a, b) => triageGravityRank(
            a.triageColor,
          ).compareTo(triageGravityRank(b.triageColor)),
        );
      case PatientSortOption.name:
        list.sort((a, b) => a.displayName.compareTo(b.displayName));
    }
    return list;
  }

  static IncidentPatientTriageCounts triageCountsFor(
    List<ParamedicoPatientRow> patients,
  ) {
    var r = 0, y = 0, g = 0, b = 0;
    for (final p in patients) {
      switch (p.triageColor) {
        case 'rojo':
          r++;
          break;
        case 'amarillo':
        case 'naranja':
          y++;
          break;
        case 'verde':
        case 'azul':
          g++;
          break;
        case 'negro':
          b++;
          break;
        default:
          y++;
      }
    }
    return IncidentPatientTriageCounts(
      red: r,
      yellow: y,
      green: g,
      black: b,
      total: patients.length,
    );
  }
}
