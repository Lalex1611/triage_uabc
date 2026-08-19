import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/incident_sorting_options.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/home_user_stats.dart';
import 'package:sistema_triage/features/paramedico/presentation/home/widgets/app_search_bar_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/home/widgets/minidash_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/home/widgets/sort_and_filter_widget.dart';
import 'package:sistema_triage/shared/widgets/home_screen_body.dart';

// Cascarón del home paramédico: un solo scroll con cabecera + lista de incidentes
class ParamedicoHomePage extends StatelessWidget {
  final PreferredSizeWidget header;
  final HomeUserStats userStats;
  final TextEditingController searchController;
  final int totalIncidents;
  final bool mineOnly;
  final ValueChanged<bool> onMineOnlyChanged;
  final IncidentSortOption sortOption;
  final ValueChanged<IncidentSortOption> onSortChanged;
  final String? errorMessage;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final List<Widget> contentSlivers;
  final VoidCallback onCreateIncident;

  const ParamedicoHomePage({
    super.key,
    required this.header,
    required this.userStats,
    required this.searchController,
    required this.totalIncidents,
    required this.mineOnly,
    required this.onMineOnlyChanged,
    required this.sortOption,
    required this.onSortChanged,
    this.errorMessage,
    required this.isLoading,
    required this.onRefresh,
    required this.contentSlivers,
    required this.onCreateIncident,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: context.bottomNavExtent * 0.15),
        child: FloatingActionButton(
          backgroundColor: AppColors.primaryParamedico,
          onPressed: onCreateIncident,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: HomeScreenBody(
        useSafeArea: false,
        isLoading: isLoading,
        onRefresh: onRefresh,
        slivers: contentSlivers,
        header: [
          header,
          Stack(
            clipBehavior: Clip.none,
            children: [
              Minidash(userstats: userStats),
              Positioned(
                left: 0,
                right: 0,
                bottom: -30.5,
                child: AppSearchBar(controller: searchController),
              ),
            ],
          ),
          const SizedBox(height: 40.5),
          SortAndFilter(
            totalIncidents: totalIncidents,
            mineOnly: mineOnly,
            onMineOnlyChanged: onMineOnlyChanged,
            sortOption: sortOption,
            onSortChanged: onSortChanged,
          ),
          const SizedBox(height: 10),
          if (errorMessage != null)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.horizontalPadding,
              ),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
