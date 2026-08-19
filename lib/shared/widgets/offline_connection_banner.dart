import 'package:flutter/material.dart';
import 'package:sistema_triage/core/connectivity/app_connectivity_notifier.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

class OfflineConnectionBanner extends StatelessWidget {
  const OfflineConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppConnectivityNotifier.instance,
      builder: (context, _) {
        final connected = AppConnectivityNotifier.instance.isConnected;
        return IgnorePointer(
          ignoring: connected,
          child: AnimatedSlide(
            offset: connected ? const Offset(0, -1) : Offset.zero,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: connected ? 0 : 1,
              duration: const Duration(milliseconds: 180),
              child: SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primaryParamedico.withValues(
                          alpha: 0.35,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          color: AppColors.primaryParamedico,
                          size: 16,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Sin conexion',
                          style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
                            color: AppColors.primaryParamedico,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
