import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/start_triage_tab_options.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/start_triage_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/start_triage_toggle_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/triage_color_grid_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/start_triage_name_input_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/selected_triage_pill_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/photo_capture_area_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/start_triage_actions_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/guided_protocol/guided_protocol_step_0_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/guided_protocol/guided_protocol_step_1_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/guided_protocol/guided_protocol_step_1_respira_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/guided_protocol/guided_protocol_step_2_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/guided_protocol/guided_protocol_step_3_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/start_triage_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/start_triage_header_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/start_triage_toggle_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/triage_color_grid_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/start_triage_name_input_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/selected_triage_pill_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/photo_capture_area_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/start_triage_actions_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/guided_protocol/guided_protocol_step_0_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/guided_protocol/guided_protocol_step_1_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/guided_protocol/guided_protocol_step_1_respira_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/guided_protocol/guided_protocol_step_2_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/guided_protocol/guided_protocol_step_3_widget.dart';

/*
  COMANDO PARA PROBAR EL ENSAMBLE COMPLETO (SANDBOX GLOBAL):
  flutter run -t test/features/paramedico/presentation/start_triage/start_triage_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartTriageVisualTest(),
    ),
  );
}

class StartTriageVisualTest extends StatefulWidget {
  const StartTriageVisualTest({super.key});

  @override
  State<StartTriageVisualTest> createState() => _StartTriageVisualTestState();
}

class _StartTriageVisualTestState extends State<StartTriageVisualTest> {
  StartTriageTabOption _activeTab = StartTriageTabOption.asignacionRapida;
  TriageCategory? _selectedCategory;
  List<String> _photos = [];
  final ImagePicker _picker = ImagePicker();
  
  // 0 = Deambulación, 1 = Vía Aérea, 2 = Frec. Respiratoria, 3 = Circulación, 4 = Estado Neurológico
  int _protocolStep = 0; 

  void _resetFlow() {
    setState(() {
      _selectedCategory = null;
      _photos.clear();
      _protocolStep = 0;
    });
  }

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
      debugPrint('Error al seleccionar imagen: \$e');
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
      child: StartTriagePage(
        children: [
          // 1. Header
          StartTriageHeaderWidget(
            data: StartTriageHeaderData(
              patientNumber: 5,
              onCloseTap: () =>
                  debugPrint('Cerrar triage desde Master Sandbox'),
            ),
          ),

          const SizedBox(height: 24),

          // 2. Toggle Pestañas
          StartTriageToggleWidget(
            data: StartTriageToggleData(
              activeTab: _activeTab,
              onTabChanged: (tab) => setState(() {
                _activeTab = tab;
                _resetFlow();
              }),
            ),
          ),

          const SizedBox(height: 60),

          // 3. Flujo de Asignación Rápida
          if (_activeTab == StartTriageTabOption.asignacionRapida) ...[
            if (_selectedCategory == null) ...[
              // PASO 1: Selección de color y nombre
              TriageColorGridWidget(
                data: TriageColorGridData(
                  categories: [
                    TriageCategory.rojo,
                    TriageCategory.amarillo,
                    TriageCategory.verde,
                    TriageCategory.negro,
                  ],
                  onColorSelected: (color) {
                    setState(() {
                      _selectedCategory = color;
                    });
                  },
                ),
              ),

              const SizedBox(height: 32),

              StartTriageNameInputWidget(
                data: StartTriageNameInputData(
                  onChanged: (text) => debugPrint('Escribiendo: \$text'),
                ),
              ),
            ] else ...[
              // PASO 2: Captura de Foto y Confirmación
              SelectedTriagePillWidget(
                data: SelectedTriagePillData(category: _selectedCategory!),
              ),

              const SizedBox(height: 24),

              PhotoCaptureAreaWidget(
                data: PhotoCaptureAreaData(
                  photos: _photos,
                  onAddPhotoTap: _showImageSourceDialog,
                  onRemovePhotoTap: (index) {
                    setState(() {
                      _photos.removeAt(index);
                    });
                  },
                ),
              ),

              const SizedBox(height: 32),

              StartTriageActionsWidget(
                data: StartTriageActionsData(
                  hasPhotos: _photos.isNotEmpty,
                  onCancelOrReturn: _resetFlow,
                  onSkip: () {
                    debugPrint('Omitir presionado - Continuar sin fotos');
                    _resetFlow();
                  },
                  onRegister: () {
                    debugPrint(
                      'Registrar presionado con \${_photos.length} fotos',
                    );
                    _resetFlow();
                  },
                ),
              ),
            ],
          ],

          // 4. Flujo de Protocolo Guiado
          if (_activeTab == StartTriageTabOption.protocoloGuiado) ...[
            if (_selectedCategory != null) ...[
              SelectedTriagePillWidget(
                data: SelectedTriagePillData(category: _selectedCategory!),
              ),
              const SizedBox(height: 24),
              PhotoCaptureAreaWidget(
                data: PhotoCaptureAreaData(
                  photos: _photos,
                  onAddPhotoTap: _showImageSourceDialog,
                  onRemovePhotoTap: (index) {
                    setState(() => _photos.removeAt(index));
                  },
                ),
              ),
              const SizedBox(height: 32),
              StartTriageActionsWidget(
                data: StartTriageActionsData(
                  hasPhotos: _photos.isNotEmpty,
                  onCancelOrReturn: _resetFlow,
                  onSkip: () => debugPrint('Omitir (protocolo guiado)'),
                  onRegister: () => debugPrint('Registrar (protocolo guiado)'),
                ),
              ),
            ] else if (_protocolStep == 0)
              GuidedProtocolStep0Widget(
                data: GuidedProtocolStep0Data(
                  onYesTap: () {
                    setState(() => _selectedCategory = TriageCategory.verde);
                  },
                  onNoTap: () {
                    setState(() => _protocolStep = 1);
                  },
                ),
              ),
            
            if (_protocolStep == 1)
              GuidedProtocolStep1Widget(
                data: GuidedProtocolStep1Data(
                  onYesTap: () {
                    setState(() => _protocolStep = 2);
                  },
                  onNoTap: () {
                    setState(() => _selectedCategory = TriageCategory.rojo);
                  },
                ),
              ),

            if (_protocolStep == 2)
              GuidedProtocolStep1RespiraWidget(
                data: GuidedProtocolStep1RespiraData(
                  onRedButtonTap: () {
                    setState(() => _selectedCategory = TriageCategory.rojo);
                  },
                  onOrangeButtonTap: () {
                    setState(() => _protocolStep = 3);
                  },
                ),
              ),

            if (_protocolStep == 3)
              GuidedProtocolStep2Widget(
                data: GuidedProtocolStep2Data(
                  onMenorTap: () {
                    setState(() => _protocolStep = 4);
                  },
                  onMayorTap: () {
                    setState(() => _selectedCategory = TriageCategory.rojo);
                  },
                ),
              ),

            if (_protocolStep == 4)
              GuidedProtocolStep3Widget(
                data: GuidedProtocolStep3Data(
                  onYesTap: () {
                    setState(() => _selectedCategory = TriageCategory.amarillo);
                  },
                  onNoTap: () {
                    setState(() => _selectedCategory = TriageCategory.rojo);
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}
