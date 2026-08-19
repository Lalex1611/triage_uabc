import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_photo_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_photo_widget.dart';

/*
  flutter run -t test/features/paramedico/presentation/patient_registration/widgets/patient_photo_widget_test.dart
*/

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _PatientPhotoWidgetTest(),
  ));
}

class _PatientPhotoWidgetTest extends StatefulWidget {
  const _PatientPhotoWidgetTest();

  @override
  State<_PatientPhotoWidgetTest> createState() => _PatientPhotoWidgetTestState();
}

class _PatientPhotoWidgetTestState extends State<_PatientPhotoWidgetTest> {
  List<String> _photos = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() => _photos.add(image.path));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFCE1125)),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFCE1125)),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Test: PatientPhotoWidget'),
          backgroundColor: const Color(0xFFCE1125),
        ),
        body: Center(
          child: PatientPhotoWidget(
            data: PatientPhotoData(
              photos: _photos,
              onAddPhotoTap: _showPicker,
              onRemovePhotoTap: (index) {
                setState(() => _photos.removeAt(index));
              },
            ),
          ),
        ),
      ),
    );
  }
}
