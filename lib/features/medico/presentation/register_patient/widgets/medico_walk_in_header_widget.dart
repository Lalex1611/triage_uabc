import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_walk_in_header_data.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_walk_in_form_widgets.dart';

/// Encabezado del registro sin traslado (mockups 07 y 08): botón cerrar/atrás,
/// título, "paso N de M" y barra de progreso segmentada.
class MedicoWalkInHeader extends StatelessWidget {
  const MedicoWalkInHeader({super.key, required this.data});

  final MedicoWalkInHeaderData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 6, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: data.onLeadingTap,
                icon: Icon(data.leadingIcon, size: 24),
                color: MedicoWalkInColors.textPrimary,
                tooltip: data.leadingIcon == Icons.close ? 'Cerrar' : 'Atrás',
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: MedicoWalkInColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.showsProgress
                          ? '${data.subtitle} · paso ${data.currentStep} de ${data.totalSteps}'
                          : data.subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: MedicoWalkInColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (data.showsProgress) ...[
            const SizedBox(height: 10),
            _progressBar(data.currentStep!, data.totalSteps!),
          ],
        ],
      ),
    );
  }

  Widget _progressBar(int currentStep, int totalSteps) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        children: [
          for (var i = 1; i <= totalSteps; i++) ...[
            if (i > 1) const SizedBox(width: 8),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 5,
                decoration: BoxDecoration(
                  color: i <= currentStep
                      ? MedicoWalkInColors.primary
                      : MedicoWalkInColors.progressInactive,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
