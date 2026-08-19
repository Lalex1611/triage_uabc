import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/services/map_incident_coverage_service.dart';

// Encabezado de color dinámico de la pantalla de registro de paciente
class PatientHeaderWidget extends StatefulWidget {
  final PatientHeaderData data;

  const PatientHeaderWidget({super.key, required this.data});

  @override
  State<PatientHeaderWidget> createState() => _PatientHeaderWidgetState();
}

class _PatientHeaderWidgetState extends State<PatientHeaderWidget> {
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.data.patientName ?? '');
  }

  @override
  void didUpdateWidget(covariant PatientHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final name = widget.data.patientName;
    if (name != null && name.isNotEmpty && name != oldWidget.data.patientName) {
      _nameCtrl.text = name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  static final _linkStyle = AppTextStyles.ESC_Bold_titleSmall.copyWith(
    fontSize: 13,
    color: Colors.white,
    decoration: TextDecoration.underline,
    decorationColor: Colors.white,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final headerColor = paramedicoHeaderColor(data.triageCategory);
    final locationIcon = MapIncidentCoverageService.triageLocationIcon(
      data.triageCategory?.sqlValue ?? 'rojo',
    );
    final qrContentColor = data.isQrEnabled
        ? Colors.black
        : const Color(0xFF6F747A);
    final qrBorderColor = data.isQrEnabled
        ? Colors.white
        : Colors.white.withValues(alpha: 0.55);

    return Container(
      width: double.infinity,
      color: headerColor,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.patientId,
            style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  onChanged: widget.data.onNameChanged,
                  style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.1,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nombre... (Opcional)',
                    hintStyle: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 30,
                      height: 1.1,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: data.onGenerateQrTap,
                child: Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: data.isQrEnabled
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.62),
                    border: Border.all(color: qrBorderColor, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        AppIcons.unicoPacienteQr,
                        width: 22,
                        height: 22,
                        colorFilter: ColorFilter.mode(
                          qrContentColor,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            data.qrButtonLabel,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.ESC_Light_bodyMedium.copyWith(
                              color: qrContentColor,
                              fontSize: 8,
                              height: 1.05,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.isGpsCaptured ? 'GPS capturado' : 'GPS no capturado',
            style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              SvgPicture.asset(locationIcon, width: 15, height: 15),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  data.gpsCoordinates,
                  style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: data.onShowMapTap,
                child: Text('Mostrar', style: _linkStyle),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: data.onEditLocationTap,
                child: Text('Editar', style: _linkStyle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
