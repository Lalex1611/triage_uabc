import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_blood_type.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_gender.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_injury_type.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_details/details_actions_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_details/details_app_bar_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_details/details_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_details/details_status_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_details/details_triage_classification_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_description_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_map_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_personal_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_photo_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/widgets/details_actions_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/widgets/details_app_bar_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/widgets/details_header_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/widgets/details_status_strip_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/widgets/details_triage_classification_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_description_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_personal_data_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_photo_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/widgets/details_map_widget.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_details/details_map_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/widgets/transfer_flow/transfer_folio_dialog_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/widgets/transfer_flow/transfer_insurance_question_dialog_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/widgets/transfer_flow/transfer_selection_dialog_widget.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PatientDetailsVisualTest(),
    ),
  );
}

class PatientDetailsVisualTest extends StatefulWidget {
  const PatientDetailsVisualTest({super.key});

  @override
  State<PatientDetailsVisualTest> createState() =>
      _PatientDetailsVisualTestState();
}

class _PatientDetailsVisualTestState extends State<PatientDetailsVisualTest> {
  // Global State
  bool _canEdit = true;
  bool _isEditingTriage = false;
  TriageCategory _triageCategory = TriageCategory.verde;
  PatientStatus _currentStatus = PatientStatus.enEspera;

  final List<String> _photos = [
    'https://via.placeholder.com/150',
  ]; // Simulated photo
  final Set<PatientInjuryType> _selectedInjuries = {};
  PatientGender? _gender;
  PatientBloodType? _bloodType;
  String _description = '';

  // Transfer Flow State
  String? _assignedHospital;
  String? _headingToText;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _photos.add(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error al tomar/seleccionar foto: $e");
    }
  }

  void _showImageSourceDialog() {
    if (!_canEdit) return;
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
                title: const Text('Tomar foto con la cámara'),
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
                title: const Text('Elegir de la galería'),
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

  // --- FLUJO DE TRASLADO ---

  void _startTransferFlow() {
    if (_triageCategory == TriageCategory.rojo) {
      // Flujo Rojo: Lista de TODO
      _showHospitalSelectionDialog([
        'Cruz Roja Mexicana Dele. Tijuana',
        'Cruz Roja Mexicana Estatal B.C.',
        'Hospital Angeles Tijuana',
        'Hospital General Tijuana',
        'IMSS Emergencia Clínica 1',
        'IMSS Clínica 20',
        'ISSSTECALI Mirador',
      ]);
    } else {
      // Flujo Normal: Preguntar Seguro
      showDialog(
        context: context,
        builder: (context) => TransferInsuranceQuestionDialog(
          onBackTap: () => Navigator.pop(context),
          onNoTap: () {
            Navigator.pop(context);
            _showHospitalSelectionDialog([
              'Cruz Roja Mexicana Dele. Tijuana',
              'Cruz Roja Mexicana Estatal B.C.',
              'Hospital Angeles Tijuana',
              'Hospital General Tijuana',
            ]);
          },
          onYesTap: () {
            Navigator.pop(context);
            _showInsuranceSelectionDialog();
          },
        ),
      );
    }
  }

  void _showHospitalSelectionDialog(List<String> options) {
    showDialog(
      context: context,
      builder: (context) => TransferSelectionDialog(
        title: 'Seleccione el hospital destino',
        options: options,
        onBackTap: () => Navigator.pop(context),
        onOptionSelected: (hospital) {
          Navigator.pop(context);
          if (_triageCategory != TriageCategory.rojo) {
            _showFolioDialog(hospital);
          } else {
            _finishTransferFlow(hospital);
          }
        },
      ),
    );
  }

  void _showFolioDialog(String hospital) {
    showDialog(
      context: context,
      builder: (context) => TransferFolioDialog(
        onBackTap: () => Navigator.pop(context),
        onSubmit: (folio) {
          Navigator.pop(context);
          _finishTransferFlow(hospital);
        },
      ),
    );
  }

  void _showInsuranceSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => TransferSelectionDialog(
        title: 'Seleccione su aseguradora',
        options: ['IMSS', 'ISSSTE', 'ISSSTECALI', 'Seguro privado', 'Otra'],
        editOption: 'Otra',
        onBackTap: () => Navigator.pop(context),
        onOptionSelected: (insurance) {
          Navigator.pop(context);
          _showClinicSelectionDialog(insurance);
        },
        onEditOptionTapped: () {
          Navigator.pop(context);
          _showCustomInsuranceDialog();
        },
      ),
    );
  }

  void _showCustomInsuranceDialog() {
    showDialog(
      context: context,
      builder: (context) => TransferFolioDialog(
        onBackTap: () => Navigator.pop(context),
        onSubmit: (insuranceName) {
          Navigator.pop(context);
          // Si puso un nombre personalizado lo usa, si omitió se va por "Otra"
          _showClinicSelectionDialog(
            insuranceName.isNotEmpty ? insuranceName : 'Otra',
          );
        },
      ),
    );
  }

  void _showClinicSelectionDialog(String insurance) {
    showDialog(
      context: context,
      builder: (context) => TransferSelectionDialog(
        title: 'Seleccione su clínica habitual',
        options: [
          '$insurance Clínica 1',
          '$insurance Clínica 7',
          '$insurance Clínica 20',
          '$insurance Clínica 27',
        ],
        onBackTap: () => Navigator.pop(context),
        onOptionSelected: (clinic) {
          Navigator.pop(context);
          _finishTransferFlow(clinic);
        },
      ),
    );
  }

  void _finishTransferFlow(String assigned) {
    setState(() {
      _currentStatus = PatientStatus.trasladando;
      _assignedHospital = null; // Quitado del mapa como se solicitó
      _headingToText = null;
    });

    // Mostrar el Toast tipo popup delimitado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF00C74A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Hospital de emergencia asignado: $assigned',
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 70, left: 20, right: 20),
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.yellow,
          onPressed: () => setState(() => _canEdit = !_canEdit),
          tooltip: 'Toggle Modo Edición',
          child: Icon(
            _canEdit ? Icons.edit : Icons.visibility,
            color: Colors.black,
          ),
        ),
        appBar: DetailsAppBarWidget(
          data: DetailsAppBarData(
            triageCategory: _triageCategory,
            onBackTap: () => debugPrint('Regresar'),
            onCloseIncidentTap: () => debugPrint('Cerrar Incidente'),
          ),
        ),
        bottomNavigationBar: DetailsActionsWidget(
          data: DetailsActionsData(
            canEdit: _canEdit,
            onCancelTap: () => debugPrint('CANCELAR'),
            onSaveTap: () => debugPrint('GUARDAR'),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              DetailsHeaderWidget(
                data: DetailsHeaderData(
                  patientId: 'PAC-28321',
                  patientName: 'Juan Carlos',
                  gpsCoordinates: '19.4326, -99.1332',
                  triageCategory: _triageCategory,
                  isEditing: _canEdit,
                  showEditButton: !_canEdit,
                  onStartEditTap: () => debugPrint('Editar'),
                  onGenerateQrTap: () => debugPrint('Generar QR'),
                  onShowMapTap: () => debugPrint('Mostrar mapa'),
                  onEditMapTap: () => debugPrint('Editar mapa'),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -15),
                child: DetailsStatusStripWidget(
                  data: DetailsStatusData(
                    creatorName: 'Carlos Huerta',
                    timeElapsed: '28 minutos',
                    currentStatus: _currentStatus,
                    canEdit: _canEdit,
                    onStatusChanged: (status) {
                      if (status == PatientStatus.trasladando &&
                          _currentStatus != PatientStatus.trasladando) {
                        _startTransferFlow();
                      } else {
                        setState(() {
                          _currentStatus = status;
                          if (status != PatientStatus.trasladando) {
                            _assignedHospital = null;
                            _headingToText = null;
                          }
                        });
                      }
                    },
                  ),
                ),
              ),

              // Fotos (Reusing PatientPhotoWidget)
              PatientPhotoWidget(
                data: PatientPhotoData(
                  isReadOnly: !_canEdit,
                  photos: _photos,
                  onAddPhotoTap: _showImageSourceDialog,
                  onRemovePhotoTap: (index) {
                    if (_canEdit) setState(() => _photos.removeAt(index));
                  },
                ),
              ),

              const Divider(height: 40),

              // Triage Classification
              DetailsTriageClassificationWidget(
                data: DetailsTriageClassificationData(
                  selectedCategory: _triageCategory,
                  canEdit: _canEdit,
                  isEditingMode: _isEditingTriage,
                  onEditTap: () => setState(() => _isEditingTriage = true),
                  onCategorySelected: (category) {
                    setState(() {
                      _triageCategory = category;
                      _isEditingTriage =
                          false; // Bloquear de nuevo después de seleccionar
                    });
                  },
                ),
              ),

              const Divider(height: 40),

              // Map (DetailsMapWidget wrapping PatientMapWidget)
              DetailsMapWidget(
                data: DetailsMapData(
                  currentStatus: _currentStatus,
                  assignedHospital: _assignedHospital,
                  headingToText: _headingToText,
                  mapData: PatientMapData(
                    latitude: 19.4326,
                    longitude: -99.1332,
                  ),
                ),
              ),

              const Divider(height: 40),

              // Personal Data (Reusing PatientPersonalDataWidget)
              PatientPersonalDataWidget(
                data: PatientPersonalData(
                  isReadOnly: !_canEdit,
                  gender: _gender,
                  bloodType: _bloodType,
                  onDayChanged: (v) {},
                  onMonthChanged: (v) {},
                  onYearChanged: (v) {},
                  onGenderChanged: (v) {
                    if (_canEdit) setState(() => _gender = v);
                  },
                  onBloodTypeChanged: (v) {
                    if (_canEdit) setState(() => _bloodType = v);
                  },
                  onContactNumberChanged: (v) {},
                ),
              ),

              const Divider(height: 40),

              // Description (Reusing PatientDescriptionWidget)
              PatientDescriptionWidget(
                data: PatientDescriptionData(
                  isReadOnly: !_canEdit,
                  selectedInjuries: _selectedInjuries,
                  descriptionText: _description,
                  onInjuryToggled: (injury) {
                    if (!_canEdit) return;
                    setState(() {
                      if (_selectedInjuries.contains(injury)) {
                        _selectedInjuries.remove(injury);
                      } else {
                        _selectedInjuries.add(injury);
                      }
                    });
                  },
                  onDescriptionChanged: (text) {
                    if (_canEdit) setState(() => _description = text);
                  },
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
