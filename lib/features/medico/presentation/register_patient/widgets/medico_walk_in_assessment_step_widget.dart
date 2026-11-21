import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_category.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_level.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_walk_in_assessment_data.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_walk_in_form_widgets.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

/// Paso 2 del registro sin traslado (mockup 08): cinco niveles de triage
/// hospitalario, motivo de consulta y signos vitales opcionales.
class MedicoWalkInAssessmentStep extends StatelessWidget {
  const MedicoWalkInAssessmentStep({super.key, required this.data});

  final MedicoWalkInAssessmentData data;

  static const _levels = <_LevelInfo>[
    _LevelInfo(
      MedicoTriageCategory.rojo,
      1,
      'ROJO',
      'Resucitación',
      'Atención inmediata',
    ),
    _LevelInfo(
      MedicoTriageCategory.naranja,
      2,
      'NARANJA',
      'Emergencia',
      'Atender antes de 10 min',
    ),
    _LevelInfo(
      MedicoTriageCategory.amarillo,
      3,
      'AMARILLO',
      'Urgente',
      'Atender antes de 60 min',
    ),
    _LevelInfo(
      MedicoTriageCategory.verde,
      4,
      'VERDE',
      'Poco urgente',
      'Atender antes de 2 h',
    ),
    _LevelInfo(
      MedicoTriageCategory.azul,
      5,
      'AZUL',
      'No urgente',
      'Consulta general',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'TRIAGE hospitalario',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: MedicoWalkInColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Cinco niveles. El nivel decide el orden de atención en la sala.',
          style: TextStyle(
            fontSize: 12.5,
            height: 1.35,
            color: MedicoWalkInColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _levelGrid(),
        const SizedBox(height: 18),
        MedicoWalkInCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MedicoWalkInCardTitle('Motivo de consulta'),
              const SizedBox(height: 12),
              const MedicoWalkInLabel('Síntomas y antecedentes'),
              MedicoWalkInTextField(
                controller: data.reasonController,
                hint: 'Describe por qué acudió',
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 14),
              const MedicoWalkInLabel('Alergias (opcional)'),
              MedicoWalkInTextField(
                controller: data.allergiesController,
                hint: 'Ej. penicilina',
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        MedicoWalkInCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MedicoWalkInCardTitle('Signos vitales (opcional)'),
              const SizedBox(height: 14),
              _vitalsRow([
                _vital('T/A sistólica', 'mmHg', data.systolicController),
                _vital('T/A diastólica', 'mmHg', data.diastolicController),
              ]),
              const SizedBox(height: 12),
              _vitalsRow([
                _vital('Frec. cardiaca', 'lpm', data.heartRateController),
                _vital(
                  'Frec. respiratoria',
                  'rpm',
                  data.respiratoryRateController,
                ),
              ]),
              const SizedBox(height: 12),
              _vitalsRow([
                _vital(
                  'Temperatura',
                  '°C',
                  data.temperatureController,
                  decimal: true,
                ),
                _vital('SpO₂', '%', data.oxygenController),
              ]),
              const SizedBox(height: 12),
              _vitalsRow([
                _vital('Glucosa', 'mg/dL', data.glucoseController),
                const SizedBox.shrink(),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _levelGrid() {
    final rows = <Widget>[];
    for (var i = 0; i < _levels.length; i += 2) {
      final left = _levels[i];
      final right = i + 1 < _levels.length ? _levels[i + 1] : null;
      if (i > 0) rows.add(const SizedBox(height: 10));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _levelCard(left)),
              const SizedBox(width: 10),
              Expanded(
                child: right == null
                    ? const SizedBox.shrink()
                    : _levelCard(right),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _levelCard(_LevelInfo info) {
    return _TriageLevelCard(
      info: info,
      selected: data.selectedLevel == info.category,
      onTap: () => data.onLevelSelected(info.category),
    );
  }

  Widget _vitalsRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: 12),
        Expanded(child: children[1]),
      ],
    );
  }

  Widget _vital(
    String label,
    String unit,
    TextEditingController controller, {
    bool decimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MedicoWalkInLabel(label),
        MedicoWalkInTextField(
          controller: controller,
          hint: unit,
          digitsOnly: !decimal,
          decimal: decimal,
          maxLength: 5,
        ),
      ],
    );
  }
}

class _LevelInfo {
  const _LevelInfo(
    this.category,
    this.level,
    this.colorName,
    this.title,
    this.subtitle,
  );

  final MedicoTriageCategory category;
  final int level;
  final String colorName;
  final String title;
  final String subtitle;

  Color get color =>
      MedicoTriageLevel.colorOf(TriageCategory.values.byName(category.name));
}

class _TriageLevelCard extends StatelessWidget {
  const _TriageLevelCard({
    required this.info,
    required this.selected,
    required this.onTap,
  });

  final _LevelInfo info;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Amarillo es claro: texto oscuro, como en las demás tarjetas de triage
    final fg = info.category == MedicoTriageCategory.amarillo
        ? const Color(0xFF1A1A1A)
        : Colors.white;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Nivel ${info.level}, ${info.title}',
      child: Material(
        color: info.color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? const Color(0xFF1A1A1A) : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'NIVEL ${info.level} · ${info.colorName}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: fg,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle_outline, size: 18, color: fg),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  info.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  info.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    color: fg.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
