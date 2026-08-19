import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_filter.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_patient_list_header_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_triage_filters_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_user_stats.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_minidash_widget.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_patient_list_header_widget.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_search_bar_widget.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_triage_filters_widget.dart';
import 'package:sistema_triage/features/medico/presentation/navigation/medico_navbar_widget.dart';
import 'package:sistema_triage/shared/widgets/app_header.dart';
import 'package:sistema_triage/shared/widgets/home_screen_body.dart';

// Cascarón del home médico: layout según Figma; sin lógica de negocio
class MedicoHomePage extends StatelessWidget {
  final Widget walkInRegisterTab;

  const MedicoHomePage({
    super.key,
    required this.navIndex,
    required this.onNavTap,
    required this.isConnected,
    required this.userStats,
    required this.searchController,
    required this.onSearchChanged,
    required this.patientCount,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.showTriageFilters,
    this.errorMessage,
    required this.loading,
    required this.onRefresh,
    required this.contentSlivers,
    this.onProfileTap,
    required this.walkInRegisterTab,
    this.hasUnreadNotifications = false,
    this.onNotificationTap,
  });

  final int navIndex;
  final ValueChanged<int> onNavTap;
  final bool isConnected;
  final MedicoUserStats userStats;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final int patientCount;
  final MedicoPatientFilter activeFilter;
  final ValueChanged<MedicoPatientFilter> onFilterChanged;
  final bool showTriageFilters;
  final String? errorMessage;
  final bool loading;
  final Future<void> Function() onRefresh;
  final List<Widget> contentSlivers;
  final VoidCallback? onProfileTap;
  final bool hasUnreadNotifications;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    if (navIndex == 1) {
      return Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.horizontalPadding,
                  10,
                  context.horizontalPadding,
                  4,
                ),
                child: Text(
                  'Registro cuando el paciente llega por su cuenta al hospital '
                  '(no viene en ambulancia ni en traslado). Quedará como '
                  '«Recibido» en su hospital.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
              Expanded(child: walkInRegisterTab),
            ],
          ),
        ),
        bottomNavigationBar: MedicoNavbar(
          currentIndex: navIndex,
          onTap: onNavTap,
        ),
      );
    }

    final hPad = context.horizontalPadding;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: HomeScreenBody(
        header: [
          _header(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              MedicoMinidash(userstats: userStats),
              Positioned(
                left: 0,
                right: 0,
                bottom: -30.5,
                child: MedicoSearchBar(
                  controller: searchController,
                  onChanged: onSearchChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40.5),
          MedicoPatientListHeader(
            data: MedicoPatientListHeaderData(patientCount: patientCount),
          ),
          const SizedBox(height: 10),
          if (showTriageFilters)
            MedicoTriageFilters(
              data: MedicoTriageFiltersData(
                activeFilter: activeFilter,
                onFilterChanged: onFilterChanged,
              ),
            )
          else
            const SizedBox(height: 26),
          const SizedBox(height: 10),
          if (errorMessage != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
        isLoading: loading,
        onRefresh: onRefresh,
        slivers: contentSlivers,
      ),
      bottomNavigationBar: MedicoNavbar(
        currentIndex: navIndex,
        onTap: onNavTap,
      ),
    );
  }

  PreferredSizeWidget _header() {
    return AppHeader(
      type: HeaderType.home,
      color: AppColors.primaryMedico,
      isConnected: isConnected,
      hasNotifications: hasUnreadNotifications,
      subtitle: 'Cruz Roja - Tijuana',
      logoPath: AppIcons.medicoHeaderLogo,
      notificationIconPath: AppIcons.medicoHeaderNotification,
      profileIconPath: AppIcons.medicoHeaderProfile,
      onNotificationTap: onNotificationTap,
      onProfileTap: onProfileTap,
    );
  }
}
