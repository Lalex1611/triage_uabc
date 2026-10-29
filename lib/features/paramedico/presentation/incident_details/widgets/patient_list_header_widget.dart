import 'package:flutter/material.dart';
//import 'package:flutter_svg/flutter_svg.dart';
//import 'package:sistema_triage/core/constants/app_colors.dart';
//import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
//import 'package:sistema_triage/features/paramedico/domain/constants/patient_sorting_options.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_list_header_data.dart';

//import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/patient_sort_options_widget.dart';

// Encabezado de la lista de pacientes del incidente activo
class PatientListHeader extends StatelessWidget {
  final PatientListHeaderData data;

  const PatientListHeader({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'Pacientes (${data.patientCount})',
        style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
          color: Colors.black,
          fontSize: 15,
        ),
      ),
    );
  }
}
