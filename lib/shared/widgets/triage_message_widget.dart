import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/triage_level_style.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/core/theme/triage_tone.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';
import 'package:sistema_triage/shared/widgets/triage_button_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

/// Ícono destacado de [TriageDialog] y [TriageResultMessage]
///
/// Solo describe qué se pinta; el tamaño lo pone quien lo muestra.
/// - Por defecto, según un [TriageTone]: círculo si es éxito, recuadro si pide
///   una decisión (eliminar, permisos…), como en Figma.
/// - [TriageMessageIcon.role]: color del rol activo.
/// - [TriageMessageIcon.level]: color de un nivel de triage (paciente registrado).
class TriageMessageIcon {
  const TriageMessageIcon(this.asset, {required TriageTone this.tone})
    : level = null,
      _role = false;

  const TriageMessageIcon.role(this.asset)
    : tone = null,
      level = null,
      _role = true;

  const TriageMessageIcon.level(this.asset, TriageLevel this.level)
    : tone = null,
      _role = false;

  /// Ruta de `TriageIcons`
  final String asset;
  final TriageTone? tone;
  final TriageLevel? level;
  final bool _role;
}

class _MessageIconBadge extends StatelessWidget {
  const _MessageIconBadge(this.icon, {required this.size});

  final TriageMessageIcon icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tone = icon.tone;
    final level = icon.level;
    final role = context.triageRole;

    final (Color foreground, Color background) = switch ((tone, level)) {
      (final TriageTone tone, _) => (tone.color, tone.background),
      // Amarillo, naranja y verde no llegan a 3:1 sobre su fondo tenue
      (_, final TriageLevel level) => (
        level.onColor == TriageColors.textInverse
            ? level.color
            : TriageColors.textPrimary,
        level.background ?? TriageColors.sunken,
      ),
      _ => (role.accent, role.soft),
    };
    final isCircle = icon._role || level != null || tone == TriageTone.success;

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(
            isCircle ? TriageRadii.full : TriageRadii.xl,
          ),
        ),
        child: Center(
          child: TriageIcon(icon.asset, size: size / 2, color: foreground),
        ),
      ),
    );
  }
}

class _MessageTitle extends StatelessWidget {
  const _MessageTitle(this.text, this.style);

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      namesRoute: true,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: style.copyWith(color: TriageColors.textPrimary),
      ),
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TriageTextStyles.bodyMedium.copyWith(
        color: TriageColors.textSecondary,
      ),
    );
  }
}

/// Pide confirmación con un [TriageDialog] de dos botones
///
/// Devuelve `true` solo si se confirma; cancelar o tocar fuera devuelve `false`.
/// Para una acción destructiva, [confirmVariant] es
/// `TriageButtonVariant.danger`.
Future<bool> showTriageConfirm(
  BuildContext context, {
  required TriageMessageIcon icon,
  required String title,
  required String confirmLabel,
  String? message,
  String cancelLabel = 'Cancelar',
  TriageButtonVariant confirmVariant = TriageButtonVariant.primary,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => TriageDialog(
      icon: icon,
      title: title,
      message: message,
      actions: [
        TriageButton(
          label: confirmLabel,
          variant: confirmVariant,
          onPressed: () => Navigator.pop(dialogContext, true),
        ),
        TriageButton(
          label: cancelLabel,
          variant: TriageButtonVariant.subtle,
          size: TriageButtonSize.medium,
          onPressed: () => Navigator.pop(dialogContext, false),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Diálogo del rediseño (Figma "Panel" de "4 · Ventanas y hojas")
///
/// Ícono, título, mensaje, [content] opcional (p. ej. una pastilla de nivel) y
/// [actions] a todo el ancho. Se abre con `showDialog`; para una simple
/// confirmación, [showTriageConfirm]. Si no cabe, se desplaza.
class TriageDialog extends StatelessWidget {
  const TriageDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.actions,
    this.message,
    this.content,
  });

  final TriageMessageIcon icon;
  final String title;
  final String? message;
  final Widget? content;

  /// Normalmente `TriageButton`, de mayor a menor importancia
  final List<Widget> actions;

  static const _radius = BorderRadius.all(Radius.circular(TriageRadii.xxl));
  static const _iconSize = 64.0;
  static const _maxWidth = 416.0;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    final content = this.content;

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: TriageSpacing.lg,
        vertical: TriageSpacing.xxl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: _radius,
            boxShadow: TriageShadows.floating,
          ),
          child: Material(
            color: TriageColors.surface,
            borderRadius: _radius,
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                context.horizontalPadding,
                TriageSpacing.xxl,
                context.horizontalPadding,
                TriageSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: TriageSpacing.md,
                children: [
                  Center(
                    child: _MessageIconBadge(
                      icon,
                      size: context.rDim(_iconSize),
                    ),
                  ),
                  _MessageTitle(title, TriageTextStyles.titleLarge),
                  if (message != null) _MessageBody(message),
                  ?content,
                  Padding(
                    padding: const EdgeInsets.only(top: TriageSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: TriageSpacing.sm,
                      children: actions,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mensaje de resultado a pantalla completa del rediseño (B17, C03, C09, C11 y A08)
///
/// Va en el cuerpo de la pantalla, debajo del encabezado, y ocupa el alto
/// restante: el ícono, los textos y [content] se desplazan si no caben, y
/// [actions] quedan fijas abajo. [prominentTitle] usa el título grande de C03.
class TriageResultMessage extends StatelessWidget {
  const TriageResultMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.actions,
    this.message,
    this.content,
    this.prominentTitle = false,
  });

  final TriageMessageIcon icon;
  final String title;
  final String? message;

  /// Debajo del mensaje (p. ej. una tarjeta con los datos del traslado)
  final Widget? content;

  /// Normalmente `TriageButton`, de mayor a menor importancia
  final List<Widget> actions;
  final bool prominentTitle;

  static const _iconSize = 88.0;
  static const _topPadding = 40.0;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    final content = this.content;
    final gutter = context.horizontalPadding;
    // En móviles bajos, el ícono y el margen ceden espacio al contenido
    final isShort = context.isShortScreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              gutter,
              isShort ? TriageSpacing.xl : context.rDim(_topPadding),
              gutter,
              TriageSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: TriageSpacing.lg,
              children: [
                Center(
                  child: _MessageIconBadge(
                    icon,
                    size: context.rDim(
                      isShort ? TriageDialog._iconSize : _iconSize,
                    ),
                  ),
                ),
                _MessageTitle(
                  title,
                  prominentTitle
                      ? TriageTextStyles.screenTitle
                      : TriageTextStyles.titleLarge,
                ),
                if (message != null) _MessageBody(message),
                if (content != null)
                  Padding(
                    padding: const EdgeInsets.only(top: TriageSpacing.sm),
                    child: content,
                  ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              TriageSpacing.md,
              gutter,
              TriageSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: TriageSpacing.sm,
              children: actions,
            ),
          ),
        ),
      ],
    );
  }
}
