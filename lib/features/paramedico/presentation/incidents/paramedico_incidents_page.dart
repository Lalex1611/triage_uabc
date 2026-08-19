import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';

// Cascarón del tab Incidentes: header y lista de tarjetas
class ParamedicoIncidentsPage extends StatelessWidget {
  final PreferredSizeWidget header;
  final String? errorMessage;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Widget incidentList;
  final VoidCallback onCreateIncident;

  const ParamedicoIncidentsPage({
    super.key,
    required this.header,
    this.errorMessage,
    required this.isLoading,
    required this.onRefresh,
    required this.incidentList,
    required this.onCreateIncident,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryParamedico,
        onPressed: onCreateIncident,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          header,
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(onRefresh: onRefresh, child: incidentList),
          ),
        ],
      ),
    );
  }
}
