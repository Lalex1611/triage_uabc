import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_app_bar_data.dart';

class MedicoRegisterAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final MedicoRegisterAppBarData data;

  const MedicoRegisterAppBarWidget({super.key, required this.data});

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
              'Regresar a Home',
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
