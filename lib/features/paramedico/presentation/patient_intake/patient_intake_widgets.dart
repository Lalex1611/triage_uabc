import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Pregunta «¿Salir sin registrar?» antes de cerrar un panel con datos
///
/// Devuelve `true` solo con «Salir y perder los datos»; tocar fuera sigue
/// registrando.
Future<bool> confirmDiscardPatient(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => TriageDialog(
      icon: const TriageMessageIcon(
        TriageIcons.alert,
        tone: TriageTone.warning,
      ),
      title: '¿Salir sin registrar?',
      message:
          'Perderás lo que llevas registrado de este paciente. En escena '
          'conviene registrarlo aunque sea solo con el color.',
      actions: [
        TriageButton(
          label: 'Seguir registrando',
          onPressed: () => Navigator.pop(dialogContext),
        ),
        TriageButton(
          label: 'Salir y perder los datos',
          variant: TriageButtonVariant.subtle,
          size: TriageButtonSize.medium,
          onPressed: () => Navigator.pop(dialogContext, true),
        ),
      ],
    ),
  );
  return leave ?? false;
}

/// Los cuatro colores START en dos filas, para Asignar color, START guiado y
/// Registro extendido
class StartLevelGrid extends StatelessWidget {
  const StartLevelGrid({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final TriageLevel? selected;
  final ValueChanged<TriageLevel> onSelected;

  Widget _pair(TriageLevel first, TriageLevel second) {
    Widget button(TriageLevel level) => Expanded(
      child: TriageLevelButton.start(
        level,
        selected: selected == level,
        onTap: () => onSelected(level),
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
    return Column(
      spacing: TriageSpacing.sm,
      children: [
        _pair(TriageLevel.red, TriageLevel.yellow),
        _pair(TriageLevel.green, TriageLevel.black),
      ],
    );
  }
}

/// Aviso «No se pudo registrar al paciente» al final del formulario
///
/// Al aparecer se desplaza a la vista: quien guarda suele estar arriba, junto
/// a la clasificación, y no lo vería.
class IntakeSaveError extends StatefulWidget {
  const IntakeSaveError(this.message, {super.key});

  final String message;

  @override
  State<IntakeSaveError> createState() => _IntakeSaveErrorState();
}

class _IntakeSaveErrorState extends State<IntakeSaveError> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Scrollable.ensureVisible(context, alignment: 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TriageAlert(
      tone: TriageTone.danger,
      title: 'No se pudo registrar al paciente',
      message: widget.message,
    );
  }
}

/// «Fotografía (opcional)»: fotos tomadas y botón para tomar otra con la cámara
///
/// [onAdded] recibe la ruta local de la foto nueva; puede llegar después de que
/// se cierre el panel, así que quien la recibe comprueba `mounted`. Sin
/// [enabled] (mientras se guarda) no se pueden tomar más.
class IntakePhotos extends StatelessWidget {
  const IntakePhotos({
    super.key,
    required this.photos,
    required this.onAdded,
    this.enabled = true,
  });

  final List<String> photos;
  final ValueChanged<String> onAdded;
  final bool enabled;

  static const double _photoSize = 96;

  Future<void> _takePhoto() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (image != null) onAdded(image.path);
    } catch (e) {
      debugPrint('No se pudo tomar la foto: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoSize = context.rDim(_photoSize);

    return Column(
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
            for (final (index, path) in photos.indexed)
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
                onTap: enabled ? _takePhoto : null,
                semanticLabel: 'Tomar fotografía',
              ),
            ),
            if (photos.isEmpty)
              Text(
                'Ayuda a identificar al paciente si no trae documentos.',
                style: TriageTextStyles.bodySmall.copyWith(
                  color: TriageColors.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
