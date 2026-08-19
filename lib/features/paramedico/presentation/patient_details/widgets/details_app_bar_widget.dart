import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_details/details_app_bar_data.dart';

class DetailsAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final DetailsAppBarData data;

  const DetailsAppBarWidget({super.key, required this.data});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: paramedicoHeaderColor(data.triageCategory),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: data.onBackTap,
            child: Row(
              children: [
                const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  data.backLabel ?? 'Regresar a Home',
                  style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: data.onCloseIncidentTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Cerrar Incidente',
                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
