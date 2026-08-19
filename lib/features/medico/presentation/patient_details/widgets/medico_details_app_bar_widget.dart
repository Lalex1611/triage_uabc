import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_details/medico_details_app_bar_data.dart';

class MedicoDetailsAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final MedicoDetailsAppBarData data;

  const MedicoDetailsAppBarWidget({super.key, required this.data});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primaryMedico,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: GestureDetector(
        onTap: data.onBackTap,
        child: Row(
          children: [
            const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              data.backLabel,
              style: AppTextStyles.ESC_SemiBold_titleMedium.copyWith(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
