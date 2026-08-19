import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_blood_type.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_gender.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_injury_type.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_actions_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_app_bar_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_description_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_map_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_personal_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_photo_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_triage_classification_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_actions_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_app_bar_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_description_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_header_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_map_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_personal_data_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_photo_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_triage_classification_widget.dart';

/*
  COMANDO PARA CORRER EL SANDBOX:
  flutter run -t test/features/paramedico/presentation/patient_registration/patient_registration_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PatientRegistrationVisualTest(),
    ),
  );
}

class PatientRegistrationVisualTest extends StatefulWidget {
  const PatientRegistrationVisualTest({super.key});

  @override
  State<PatientRegistrationVisualTest> createState() =>
      _PatientRegistrationVisualTestState();
}

class _PatientRegistrationVisualTestState
    extends State<PatientRegistrationVisualTest> {
  // --- Estado global de la pantalla ---

  /// Categoría de triage activa. Controla el color de AMBOS headers.
  TriageCategory _triageCategory = TriageCategory.rojo;

  List<String> _photos = [];
  Set<PatientInjuryType> _selectedInjuries = {};
  PatientGender? _gender;
  PatientBloodType? _bloodType;
  String _description = '';

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _photos.add(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error al seleccionar imagen: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFCE1125)),
                title: Text(
                  'Tomar foto con la cámara',
                  style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFFCE1125),
                ),
                title: Text(
                  'Elegir de la galería',
                  style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        // AppBar cambia de color según la clasificación START seleccionada
        appBar: PatientAppBarWidget(
          data: PatientAppBarData(
            triageCategory: _triageCategory,
            onBackTap: () => debugPrint('Regresar a Home'),
            onCloseIncidentTap: () => debugPrint('Cerrar Incidente'),
          ),
        ),

        // Botones fijos al fondo, FUERA del scroll
        bottomNavigationBar: PatientActionsWidget(
          data: PatientActionsData(
            onCancelTap: () => debugPrint('CANCELAR presionado'),
            onConfirmTap: () => debugPrint('CONFIRMAR presionado'),
          ),
        ),

        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header de color — también cambia con la clasificación
              PatientHeaderWidget(
                data: PatientHeaderData(
                  patientId: 'PAC-28321',
                  gpsCoordinates: '19.4326, -99.1332',
                  isGpsCaptured: true,
                  triageCategory: _triageCategory,
                  onShowMapTap: () => debugPrint('Mostrar mapa'),
                  onEditLocationTap: () => debugPrint('Ajustar ubicación'),
                  onGenerateQrTap: () => debugPrint('Generar QR'),
                  onNameChanged: (name) => debugPrint('Nombre: $name'),
                ),
              ),

              PatientPhotoWidget(
                data: PatientPhotoData(
                  photos: _photos,
                  onAddPhotoTap: _showImageSourceDialog,
                  onCameraTap: () => _pickImage(ImageSource.camera),
                  onGalleryTap: () => _pickImage(ImageSource.gallery),
                  onRemovePhotoTap: (index) {
                    setState(() {
                      _photos.removeAt(index);
                    });
                  },
                ),
              ),

              const Divider(height: 1),

              // Clasificación de triage — al seleccionar un color cambian AMBOS headers
              PatientTriageClassificationWidget(
                data: PatientTriageClassificationData(
                  selectedCategory: _triageCategory,
                  onCategorySelected: (category) {
                    setState(() {
                      _triageCategory = category;
                    });
                  },
                ),
              ),

              const Divider(height: 1),

              PatientMapWidget(
                data: PatientMapData(
                  latitude: 19.4326,
                  longitude: -99.1332,
                ),
              ),

              const Divider(height: 1),

              PatientPersonalDataWidget(
                data: PatientPersonalData(
                  gender: _gender,
                  bloodType: _bloodType,
                  onDayChanged: (v) => debugPrint('Día: $v'),
                  onMonthChanged: (v) => debugPrint('Mes: $v'),
                  onYearChanged: (v) => debugPrint('Año: $v'),
                  onGenderChanged: (g) => setState(() => _gender = g),
                  onBloodTypeChanged: (b) => setState(() => _bloodType = b),
                  onContactNumberChanged: (v) => debugPrint('Contacto: $v'),
                ),
              ),

              const Divider(height: 1),

              PatientDescriptionWidget(
                data: PatientDescriptionData(
                  selectedInjuries: _selectedInjuries,
                  descriptionText: _description,
                  onInjuryToggled: (injury) {
                    setState(() {
                      if (_selectedInjuries.contains(injury)) {
                        _selectedInjuries.remove(injury);
                      } else {
                        _selectedInjuries.add(injury);
                      }
                    });
                  },
                  onDescriptionChanged: (text) =>
                      setState(() => _description = text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
