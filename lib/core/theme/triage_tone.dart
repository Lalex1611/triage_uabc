import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';

/// Tono de un mensaje del rediseño (Aviso y Aviso breve)
enum TriageTone { info, success, warning, danger }

/// Apariencia de cada [TriageTone]; única fuente para que un mismo tono se vea
/// igual en todos los componentes
extension TriageToneStyle on TriageTone {
  /// Título e ícono sobre [background]
  ///
  /// Figma usa el color de señal puro; en éxito y advertencia no llega a 3:1
  /// (2.8 y 2.6), así que se usa su variante de texto (≥ 4.5:1).
  Color get color => switch (this) {
    TriageTone.info => TriageColors.infoText,
    TriageTone.success => TriageColors.successText,
    TriageTone.warning => TriageColors.warningText,
    TriageTone.danger => TriageColors.danger,
  };

  Color get background => switch (this) {
    TriageTone.info => TriageColors.infoBackground,
    TriageTone.success => TriageColors.successBackground,
    TriageTone.warning => TriageColors.warningBackground,
    TriageTone.danger => TriageColors.dangerBackground,
  };

  /// Ícono sobre fondo oscuro ([TriageColors.inverse])
  Color get onInverse => switch (this) {
    TriageTone.info => TriageColors.infoOnInverse,
    TriageTone.success => TriageColors.successOnInverse,
    TriageTone.warning => TriageColors.triageYellow,
    TriageTone.danger => TriageColors.dangerOnInverse,
  };

  /// Ruta de [TriageIcons]
  String get icon => switch (this) {
    TriageTone.info => TriageIcons.info,
    TriageTone.success => TriageIcons.checkCircle,
    TriageTone.warning => TriageIcons.alert,
    TriageTone.danger => TriageIcons.reject,
  };
}
