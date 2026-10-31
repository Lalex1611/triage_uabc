import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_header_data.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

// Cabecera superior específica para la vista de detalles del incidente
class IncidentDetailHeader extends StatelessWidget {
  final IncidentHeaderData data;

  const IncidentDetailHeader({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TriageColors.surface,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          /* FILA 1: ID del incidente y Fecha de creación */
          Row(
            children: [
              Expanded(
                child: Text(
                  data.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TriageTextStyles.labelMedium.copyWith(
                    color: TriageColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                data.createdAtLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TriageTextStyles.bodySmall.copyWith(
                  color: TriageColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          /* FILA 2: Título del Incidente y Botón de Editar */
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: TriageTextStyles.dataLarge.copyWith(
                    color: TriageColors.textPrimary,
                  ),
                ),
              ),
              if (data.isEditable && data.onEditTitleTap != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: data.onEditTitleTap,
                  child: const TriageIcon(
                    TriageIcons.pencil,
                    size: 20,
                    color: TriageColors.textPrimary,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 6),

          /* FILA 3: Ubicación GPS y Controles (Mostrar / Editar) */
          Row(
            children: [
              const TriageIcon(
                TriageIcons.location,
                size: 14,
                color: TriageColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  data.gpsCoordinates,
                  style: TriageTextStyles.bodySmall.copyWith(
                    color: TriageColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (data.hasGps && data.onShowMapTap != null) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: data.onShowMapTap,
                  child: Text(
                    'Mostrar',
                    style: TriageTextStyles.labelSmall.copyWith(
                      color: TriageColors.textPrimary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
              if (data.isEditable && data.onEditLocationTap != null) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: data.onEditLocationTap,
                  child: Text(
                    'Editar',
                    style: TriageTextStyles.labelSmall.copyWith(
                      color: TriageColors.textPrimary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          /* FILA 4: Cuadros de conteo de Triage y Total de Pacientes */
          Row(
            children: [
              _buildTriageSquare(data.redCount, TriageColors.triageRed),
              _buildTriageSquare(
                data.yellowCount,
                TriageColors.triageYellow,
                textColor: TriageColors.textPrimary,
              ),
              _buildTriageSquare(data.greenCount, TriageColors.triageGreen),
              _buildTriageSquare(data.blackCount, TriageColors.triageBlack),
              const Spacer(),
              _buildTotalPatients(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTriageSquare(
    int count,
    Color color, {
    Color textColor = TriageColors.textInverse,
  }) {
    return Container(
      width: 26,
      height: 26,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        count.toString(),
        style: TriageTextStyles.labelMedium.copyWith(color: textColor),
      ),
    );
  }

  Widget _buildTotalPatients() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: TriageColors.canvas,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TriageColors.borderSubtle, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TriageIcon(
            TriageIcons.users,
            size: 14,
            color: TriageColors.textPrimary,
          ),
          const SizedBox(width: 6),
          Text(
            '${data.totalPatients} Pacientes',
            style: TriageTextStyles.labelMedium.copyWith(
              color: TriageColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
