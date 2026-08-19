import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_map_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_compact_action_button.dart';

// Mapa embebido del paciente con accesos Mapas, Google Maps y triangulación (GPS)
class PatientMapWidget extends StatelessWidget {
  final PatientMapData data;

  const PatientMapWidget({super.key, required this.data});

  static const double _zoom = 15;
  static const double _actionScale = 0.85;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(data.latitude, data.longitude);

    final hPad = context.horizontalPadding + 11;
    final compact = context.isCompactWidth;
    final mapBtnW = compact ? 72.0 : 88.0;
    final googleBtnW = compact ? 96.0 : 118.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  data.sectionTitle,
                  style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
                    fontSize: 15,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (data.onOpenAppMapTap != null) ...[
                ParamedicoCompactActionButton(
                  label: 'Mapas',
                  width: mapBtnW,
                  scale: _actionScale,
                  forceLowercase: false,
                  iconAssetPath: AppIcons.unicoPacienteNavigation,
                  onTap: data.onOpenAppMapTap,
                ),
                SizedBox(width: 8 * _actionScale),
              ],
              if (data.onOpenGoogleMapsTap != null)
                ParamedicoCompactActionButton(
                  label: compact ? 'Maps' : 'Google Maps',
                  width: googleBtnW,
                  scale: _actionScale,
                  forceLowercase: false,
                  iconAssetPath: AppIcons.unicoPacienteGoogleMaps,
                  onTap: data.onOpenGoogleMapsTap,
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: double.infinity,
              height: 180,
              child: Stack(
                children: [
                  AbsorbPointer(
                    child: FlutterMap(
                      key: ValueKey('map_${data.latitude}_${data.longitude}'),
                      options: MapOptions(
                        initialCenter: point,
                        initialZoom: _zoom,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'sistema_triage',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: point,
                              width: 44,
                              height: 44,
                              alignment: Alignment.bottomCenter,
                              child: const Icon(
                                Icons.location_pin,
                                size: 44,
                                color: AppColors.primaryParamedico,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (data.showTriangulationButton && data.onTriangulateTap != null)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Material(
                        color: Colors.white,
                        elevation: 2,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: data.onTriangulateTap,
                          child: Padding(
                            padding: EdgeInsets.all(10 * _actionScale),
                            child: SvgPicture.asset(
                              AppIcons.unicoPacienteNavigation,
                              width: 22 * _actionScale,
                              height: 22 * _actionScale,
                              colorFilter: const ColorFilter.mode(
                                AppColors.primaryParamedico,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${data.latitude.toStringAsFixed(5)}, ${data.longitude.toStringAsFixed(5)}',
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              fontSize: 11,
              color: const Color(0xFF555555),
            ),
          ),
          Text(
            'Mapa © OpenStreetMap contributors',
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              fontSize: 9,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}
