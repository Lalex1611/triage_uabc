import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/photo_upload_section_widget.dart';

/*
  COMANDO PARA PROBAR: 
  flutter run -t test/features/paramedico/presentation/create_incident/widgets/photo_upload_section_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PhotoUploadSectionVisualTest(),
    ),
  );
}

class PhotoUploadSectionVisualTest extends StatelessWidget {
  const PhotoUploadSectionVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: PhotoUploadSection()),
      ),
    );
  }
}
