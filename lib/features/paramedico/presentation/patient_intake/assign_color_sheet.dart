import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/patient_intake_session.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Panel «Asignar color»
///
/// Normal: guarda un paciente y devuelve el registrado. Con [emergency] se queda
/// abierto: tras cada paciente avisa, vacía el formulario y llama a
/// [onRegistered], hasta que el usuario lo cierra. [onUseGuided] se llama al
/// elegir el protocolo guiado, después de cerrar el panel.
Future<RegisteredPatient?> showAssignColorSheet(
  BuildContext context, {
  required PatientIntakeSession session,
  bool emergency = false,
  VoidCallback? onUseGuided,
  ValueChanged<RegisteredPatient>? onRegistered,
}) {
  return showTriageSheet<RegisteredPatient>(
    context,
    title: emergency ? 'Emergencias' : 'Asignar color',
    subtitle: emergency
        ? 'Registro continuo · ${session.incidentFolio}'
        : 'Paciente ${session.nextNumber} · ${session.incidentFolio}',
    builder: (_) => AssignColorForm(
      session: session,
      emergency: emergency,
      onUseGuided: onUseGuided,
      onRegistered: onRegistered,
    ),
  );
}

@visibleForTesting
class AssignColorForm extends StatefulWidget {
  const AssignColorForm({
    super.key,
    required this.session,
    required this.emergency,
    this.onUseGuided,
    this.onRegistered,
  });

  final PatientIntakeSession session;
  final bool emergency;
  final VoidCallback? onUseGuided;
  final ValueChanged<RegisteredPatient>? onRegistered;

  @override
  State<AssignColorForm> createState() => _AssignColorFormState();
}

class _AssignColorFormState extends State<AssignColorForm> {
  static const double _photoSize = 96;

  TriageLevel? _level;
  String _name = '';
  final List<String> _photos = [];
  bool _saving = false;
  String? _error;
  RegisteredPatient? _last;

  /// Cambia al vaciar el formulario para reiniciar el campo de nombre
  int _formSerial = 0;

  Future<void> _takePhoto() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (image != null && mounted) setState(() => _photos.add(image.path));
    } catch (e) {
      debugPrint('No se pudo tomar la foto: $e');
    }
  }

  Future<void> _save() async {
    final level = _level;
    if (level == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final patient = await widget.session.register(
        level: level,
        name: _name,
        photos: _photos,
      );
      if (!mounted) return;
      if (!widget.emergency) {
        Navigator.pop(context, patient);
        return;
      }
      widget.onRegistered?.call(patient);
      setState(() {
        _last = patient;
        _level = null;
        _name = '';
        _photos.clear();
        _formSerial++;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _useGuided() {
    Navigator.pop(context);
    widget.onUseGuided?.call();
  }

  Widget _levelPair(TriageLevel first, TriageLevel second) {
    Widget button(TriageLevel level) => Expanded(
      child: TriageLevelButton.start(
        level,
        selected: _level == level,
        onTap: () => setState(() => _level = level),
      ),
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: TriageSpacing.sm,
        children: [button(first), button(second)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = _last;
    final error = _error;
    final photoSize = context.rDim(_photoSize);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TriageSpacing.xl,
        TriageSpacing.lg,
        TriageSpacing.xl,
        TriageSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: TriageSpacing.lg,
        children: [
          if (last != null)
            TriageAlert(
              tone: TriageTone.success,
              title: 'Paciente ${last.number} registrado con éxito',
              message:
                  '${last.folio} · registra el siguiente o cierra el panel.',
            ),
          Semantics(
            header: true,
            child: Text(
              '¿Qué prioridad le corresponde?',
              style: TriageTextStyles.titleLarge.copyWith(
                color: TriageColors.textPrimary,
              ),
            ),
          ),
          KeyedSubtree(
            key: ValueKey(_formSerial),
            child: TriageField(
              label: 'Nombre o alias (opcional)',
              hint: 'Si lo conoces, escríbelo',
              textInputAction: TextInputAction.done,
              onChanged: (value) => _name = value,
            ),
          ),
          Column(
            spacing: TriageSpacing.sm,
            children: [
              _levelPair(TriageLevel.red, TriageLevel.yellow),
              _levelPair(TriageLevel.green, TriageLevel.black),
            ],
          ),
          if (widget.onUseGuided != null)
            TriageTapCard(
              onTap: _useGuided,
              color: TriageColors.sunken,
              padding: const EdgeInsets.all(TriageSpacing.md),
              child: Row(
                spacing: TriageSpacing.sm,
                children: [
                  const TriageIcon(
                    TriageIcons.info,
                    size: TriageSizes.icon,
                    color: TriageColors.textSecondary,
                  ),
                  Expanded(
                    child: Text(
                      '¿No estás seguro? Usa el protocolo guiado',
                      style: TriageTextStyles.labelMedium.copyWith(
                        color: TriageColors.textPrimary,
                      ),
                    ),
                  ),
                  const TriageIcon(
                    TriageIcons.chevronRight,
                    size: TriageSizes.iconSmall,
                    color: TriageColors.textSecondary,
                  ),
                ],
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: TriageSpacing.sm,
            children: [
              Text(
                'Fotografía (opcional)',
                style: TriageTextStyles.labelMedium.copyWith(
                  color: TriageColors.textSecondary,
                ),
              ),
              Wrap(
                spacing: TriageSpacing.sm,
                runSpacing: TriageSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final (index, path) in _photos.indexed)
                    SizedBox.square(
                      dimension: photoSize,
                      child: TriagePhoto(
                        image: FileImage(File(path)),
                        semanticLabel: 'Fotografía ${index + 1}',
                      ),
                    ),
                  SizedBox.square(
                    dimension: photoSize,
                    child: TriagePhoto(
                      onTap: _takePhoto,
                      semanticLabel: 'Tomar fotografía',
                    ),
                  ),
                  if (_photos.isEmpty)
                    Text(
                      'Ayuda a identificar al paciente si no trae documentos.',
                      style: TriageTextStyles.bodySmall.copyWith(
                        color: TriageColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (error != null)
            TriageAlert(
              tone: TriageTone.danger,
              title: 'No se pudo registrar al paciente',
              message: error,
            ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: TriageSpacing.sm,
              children: [
                Expanded(
                  flex: 2,
                  child: TriageButton(
                    label: 'Cancelar',
                    variant: TriageButtonVariant.secondary,
                    onPressed: _saving ? null : () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: TriageButton(
                    label: 'Guardar paciente',
                    isLoading: _saving,
                    onPressed: _level == null ? null : _save,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
