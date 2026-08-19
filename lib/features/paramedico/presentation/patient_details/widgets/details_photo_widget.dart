import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_details/details_photo_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_photo_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_photo_widget.dart';

class DetailsPhotoWidget extends StatelessWidget {
  final DetailsPhotoData data;

  const DetailsPhotoWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return PatientPhotoWidget(
      data: PatientPhotoData(
        photos: data.photos,
        isReadOnly: data.isReadOnly,
        onAddPhotoTap: data.onAddPhotoTap,
        onRemovePhotoTap: data.onRemovePhotoTap,
        showAddAsideInView: !data.isReadOnly,
      ),
    );
  }
}
