import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_walk_in_success_data.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_walk_in_form_widgets.dart';

/// Cuerpo de la confirmación del registro sin traslado (mockup 09): check
/// verde, "Ya está en la sala", resumen del nivel y tarjeta con el código
/// para la familia.
class MedicoWalkInSuccess extends StatelessWidget {
  const MedicoWalkInSuccess({super.key, required this.data});

  final MedicoWalkInSuccessData data;

  static const _green = Color(0xFF2FA835);
  static const _greenSoft = Color(0xFFDDEFE0);

  @override
  Widget build(BuildContext context) {
    final registered = data.isFemale ? 'registrada' : 'registrado';
    final pronoun = data.isFemale ? 'la' : 'lo';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: _greenSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 44, color: _green),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Ya está en la sala',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: MedicoWalkInColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '${data.patientName} quedó $registered con nivel ${data.level} '
            '(${data.levelColorName}) y aparece en la lista por orden de '
            'prioridad.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: MedicoWalkInColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Material(
          color: const Color(0xFFDDE3EA),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: data.onFamilyCodeTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      size: 24,
                      color: MedicoWalkInColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Código para la familia',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: MedicoWalkInColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${data.consultationCode} · entrégalo a quien '
                          '$pronoun acompañe',
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.3,
                            color: MedicoWalkInColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: MedicoWalkInColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
