import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_details/details_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/services/map_incident_coverage_service.dart';

class DetailsHeaderWidget extends StatefulWidget {
  final DetailsHeaderData data;

  const DetailsHeaderWidget({super.key, required this.data});

  @override
  State<DetailsHeaderWidget> createState() => _DetailsHeaderWidgetState();
}

class _DetailsHeaderWidgetState extends State<DetailsHeaderWidget> {
  late TextEditingController _nameCtrl;

  static final _linkStyle = AppTextStyles.ESC_Bold_titleSmall.copyWith(
    fontSize: 10,
    color: Colors.white,
    decoration: TextDecoration.underline,
    decorationColor: Colors.white,
    fontWeight: FontWeight.w700,
  );

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.data.patientName);
  }

  @override
  void didUpdateWidget(covariant DetailsHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.patientName != oldWidget.data.patientName &&
        widget.data.patientName != _nameCtrl.text) {
      _nameCtrl.text = widget.data.patientName;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final headerColor = paramedicoHeaderColor(data.triageCategory);
    final locationIcon = MapIncidentCoverageService.triageLocationIcon(
      data.triageCategory.sqlValue,
    );

    return Container(
      color: headerColor,
      padding: const EdgeInsets.fromLTRB(35, 10, 35, 39),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.patientId,
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: data.isEditing
                    ? TextField(
                        controller: _nameCtrl,
                        onChanged: data.onNameChanged,
                        style: AppTextStyles.ESC_Bold_displayMedium.copyWith(
                          color: Colors.white,
                          fontSize: 28,
                          height: 1.1,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Nombre del paciente',
                          hintStyle:
                              AppTextStyles.ESC_Bold_displayMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 28,
                                height: 1.1,
                              ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    : Text(
                        data.patientName,
                        style: AppTextStyles.ESC_Bold_displayMedium.copyWith(
                          color: Colors.white,
                          fontSize: 28,
                          height: 1.1,
                        ),
                      ),
              ),
              if (data.showEditButton) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: data.onStartEditTap,
                  child: SvgPicture.asset(
                    AppIcons.paramedicoIncidenteEdit,
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GPS capturado',
                      style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SvgPicture.asset(locationIcon, width: 14, height: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            data.gpsCoordinates,
                            style:
                                AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: data.onShowMapTap,
                          child: Text('Mostrar', style: _linkStyle),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: data.onEditMapTap,
                          child: Text('Editar', style: _linkStyle),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: data.onGenerateQrTap,
                child: Container(
                  width: 50,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ver Código\nde Consulta',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                          fontSize: 6,
                          color: Colors.black,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SvgPicture.asset(
                        AppIcons.unicoPacienteQr,
                        width: 14,
                        height: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
