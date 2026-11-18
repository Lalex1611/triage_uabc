import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_walk_in_bottom_bar_data.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_walk_in_form_widgets.dart';

/// Botonera fija inferior del registro sin traslado: botón principal azul y,
/// opcionalmente, un botón de texto debajo (mockup 08: "Cancelar").
class MedicoWalkInBottomBar extends StatelessWidget {
  const MedicoWalkInBottomBar({super.key, required this.data});

  final MedicoWalkInBottomBarData data;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 12 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: data.isLoading ? null : data.onPrimaryTap,
              style: FilledButton.styleFrom(
                backgroundColor: MedicoWalkInColors.primary,
                disabledBackgroundColor: MedicoWalkInColors.primary.withValues(
                  alpha: 0.6,
                ),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: data.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(data.primaryLabel),
            ),
          ),
          if (data.secondaryLabel != null) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: data.isLoading ? null : data.onSecondaryTap,
              style: TextButton.styleFrom(
                foregroundColor: MedicoWalkInColors.textPrimary,
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: Text(data.secondaryLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
