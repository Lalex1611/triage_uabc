import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/start_protocol.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/start_triage_tab_options.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/patient_intake_session.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/patient_intake_widgets.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Panel «START guiado»: cinco preguntas, el color que resulta y el registro
///
/// Devuelve el paciente registrado. «Omitir y asignar el color yo mismo» cierra
/// el panel y llama a [onAssignColor]. Si ya hay respuestas, cerrar con la X,
/// Cancelar o el botón atrás pide confirmación; por eso no se cierra tocando
/// fuera ni arrastrando.
Future<RegisteredPatient?> showStartGuidedSheet(
  BuildContext context, {
  required PatientIntakeSession session,
  required VoidCallback onAssignColor,
}) {
  return showTriageSheetWith<RegisteredPatient>(
    context,
    dismissible: false,
    sheetBuilder: (_) =>
        StartGuidedPanel(session: session, onAssignColor: onAssignColor),
  );
}

@visibleForTesting
class StartGuidedPanel extends StatefulWidget {
  const StartGuidedPanel({
    super.key,
    required this.session,
    required this.onAssignColor,
  });

  final PatientIntakeSession session;
  final VoidCallback onAssignColor;

  @override
  State<StartGuidedPanel> createState() => _StartGuidedPanelState();
}

class _StartGuidedPanelState extends State<StartGuidedPanel> {
  /// Ícono de cada pregunta de [startSteps]
  static const _stepIcons = [
    TriageIcons.walk,
    TriageIcons.breathing,
    TriageIcons.pulse,
    TriageIcons.drop,
    TriageIcons.head,
  ];
  static const double _symbolSize = 112;
  static const double _symbolIconSize = 54;

  final List<StartAnswer> _answers = [];
  TriageLevel? _chosenLevel;
  bool _changingColor = false;
  String _name = '';
  final List<String> _photos = [];
  bool _saving = false;
  String? _error;

  /// Color al que llevaron las respuestas; `null` mientras se pregunta
  TriageLevel? get _suggested => _answers.lastOrNull?.level;
  TriageLevel? get _level => _chosenLevel ?? _suggested;

  /// Ignora la respuesta si [step] ya no es la pregunta pendiente: un doble
  /// toque antes de redibujar no debe contestar también la siguiente
  void _answer(int step, StartAnswer answer) {
    if (step != _answers.length) return;
    setState(() => _answers.add(answer));
  }

  void _assignColorMyself() {
    Navigator.pop(context);
    widget.onAssignColor();
  }

  Future<void> _requestClose() async {
    if (_saving) return;
    if (_answers.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => TriageDialog(
        icon: const TriageMessageIcon(
          TriageIcons.alert,
          tone: TriageTone.warning,
        ),
        title: '¿Salir sin registrar?',
        message:
            'Perderás la clasificación de este paciente. En escena conviene '
            'registrar aunque sea con el color.',
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
    if (leave == true && mounted) Navigator.pop(context);
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
        mode: StartTriageTabOption.protocoloGuiado,
      );
      if (mounted) Navigator.pop(context, patient);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = _level;
    final step = _answers.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestClose();
      },
      child: TriageSheet(
        title: 'START guiado',
        // Sin preparar, el número de paciente aún no se conoce
        subtitle: widget.session.isPrepared
            ? 'Paciente ${widget.session.nextNumber} · '
                  '${widget.session.incidentFolio}'
            : widget.session.incidentFolio,
        steps: level == null
            ? TriageSteps(
                current: step + 1,
                total: startSteps.length,
                showLabel: true,
              )
            : null,
        onClose: _requestClose,
        showGrip: false,
        child: level == null
            ? SingleChildScrollView(child: _question(step))
            : _result(level),
      ),
    );
  }

  Widget _question(int index) {
    final step = startSteps[index];
    final role = context.triageRole;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TriageSpacing.xl,
        TriageSpacing.xxl,
        TriageSpacing.xl,
        TriageSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox.square(
              dimension: context.rDim(_symbolSize),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: role.soft,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: TriageIcon(
                    _stepIcons[index],
                    size: context.rDim(_symbolIconSize),
                    color: role.accent,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: TriageSpacing.lg),
          Semantics(
            header: true,
            child: Text(
              step.question,
              textAlign: TextAlign.center,
              style: TriageTextStyles.screenTitle.copyWith(
                color: TriageColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: TriageSpacing.lg),
          Text(
            step.hint,
            textAlign: TextAlign.center,
            style: TriageTextStyles.bodyMedium.copyWith(
              color: TriageColors.textSecondary,
            ),
          ),
          const SizedBox(height: TriageSpacing.xxl),
          for (final answer in step.answers) ...[
            _AnswerOption(
              answer: answer,
              nextStep: index + 2,
              onTap: () => _answer(index, answer),
            ),
            const SizedBox(height: TriageSpacing.sm),
          ],
          const SizedBox(height: TriageSpacing.lg),
          Center(
            child: TriageSectionAction(
              label: 'Omitir y asignar el color yo mismo',
              onTap: _assignColorMyself,
            ),
          ),
        ],
      ),
    );
  }

  Widget _result(TriageLevel level) {
    final suggested = _suggested!;
    final error = _error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              TriageSpacing.xl,
              TriageSpacing.lg,
              TriageSpacing.xl,
              TriageSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: TriageSpacing.lg,
              children: [
                _ResultCard(level: level, changed: level != suggested),
                TriageSectionCard(
                  title: 'Por qué salió ${suggested.label.toLowerCase()}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (index, answer) in _answers.indexed)
                        TriageDataRow(
                          label: startSteps[index].concept,
                          value: answer.reason,
                        ),
                    ],
                  ),
                ),
                Center(
                  child: TriageSectionAction(
                    icon: TriageIcons.pencil,
                    label: 'No estoy de acuerdo · cambiar el color',
                    onTap: () =>
                        setState(() => _changingColor = !_changingColor),
                  ),
                ),
                if (_changingColor)
                  StartLevelGrid(
                    selected: level,
                    onSelected: (picked) =>
                        setState(() => _chosenLevel = picked),
                  ),
                TriageField(
                  label: 'Nombre o alias (opcional)',
                  hint: 'Si lo conoces',
                  textInputAction: TextInputAction.done,
                  onChanged: (value) => _name = value,
                ),
                IntakePhotos(
                  photos: _photos,
                  onAdded: (path) {
                    if (mounted) setState(() => _photos.add(path));
                  },
                ),
                if (error != null)
                  TriageAlert(
                    tone: TriageTone.danger,
                    title: 'No se pudo registrar al paciente',
                    message: error,
                  ),
              ],
            ),
          ),
        ),
        TriageActionBar(
          secondary: TriageButton(
            label: 'Cancelar',
            variant: TriageButtonVariant.secondary,
            onPressed: _saving ? null : _requestClose,
          ),
          primary: TriageButton(
            label: 'Guardar paciente',
            isLoading: _saving,
            onPressed: _save,
          ),
        ),
      ],
    );
  }
}

/// Respuesta de una pregunta START: con el color que asigna o, si sigue a otra
/// pregunta, blanca con borde
class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.answer,
    required this.nextStep,
    required this.onTap,
  });

  final StartAnswer answer;
  final int nextStep;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final level = answer.level;
    final foreground = level?.onColor ?? TriageColors.textPrimary;

    return TriageTapCard(
      onTap: onTap,
      color: level?.color ?? TriageColors.surface,
      borderColor: level == null ? TriageColors.borderStrong : null,
      shadow: TriageShadows.card,
      inkColor: level?.onColor,
      child: Row(
        spacing: TriageSpacing.md,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: TriageSpacing.xxs,
              children: [
                Text(
                  answer.label,
                  style: TriageTextStyles.labelLarge.copyWith(
                    color: foreground,
                  ),
                ),
                Text(
                  level == null
                      ? 'Sigue al paso $nextStep'
                      : 'Clasifica como ${level.label.toLowerCase()}',
                  style: TriageTextStyles.bodySmall.copyWith(
                    color: level == null
                        ? TriageColors.textSecondary
                        : foreground,
                  ),
                ),
              ],
            ),
          ),
          TriageIcon(
            TriageIcons.chevronRight,
            size: TriageSizes.icon,
            color: foreground,
          ),
        ],
      ),
    );
  }
}

/// Tarjeta del color resultante, con el fondo del nivel
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.level, required this.changed});

  final TriageLevel level;

  /// El paramédico cambió el color sugerido
  final bool changed;

  @override
  Widget build(BuildContext context) {
    final foreground = level.onColor;

    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: level.color,
          borderRadius: BorderRadius.circular(TriageRadii.xxl),
          boxShadow: TriageShadows.floating,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TriageSpacing.xl,
            vertical: TriageSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: TriageSpacing.xs,
            children: [
              Row(
                spacing: TriageSpacing.sm,
                children: [
                  Expanded(
                    child: Text(
                      changed
                          ? 'CLASIFICACIÓN ASIGNADA'
                          : 'CLASIFICACIÓN SUGERIDA',
                      style: TriageTextStyles.labelSmall.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                  TriageIcon(
                    TriageIcons.checkCircle,
                    size: TriageSizes.icon,
                    color: foreground,
                  ),
                ],
              ),
              Text(
                '${level.label} · ${level.startName}',
                style: TriageTextStyles.screenTitle.copyWith(color: foreground),
              ),
              Text(
                startResultSummary(level),
                style: TriageTextStyles.bodyMedium.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
