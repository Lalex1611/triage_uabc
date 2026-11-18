import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_filter_chips_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_header_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_patient_card_data.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_search_bar_widget.dart';
import 'package:sistema_triage/features/medico/presentation/queue/widgets/medico_queue_filter_chips_widget.dart';
import 'package:sistema_triage/features/medico/presentation/queue/widgets/medico_queue_header_widget.dart';
import 'package:sistema_triage/features/medico/presentation/queue/widgets/medico_queue_patient_card_widget.dart';
import 'package:sistema_triage/shared/widgets/home_screen_body.dart';

/// Cuerpo de la pestaña Sala (mockup 05). Sin lógica de negocio: recibe los
/// datos ya calculados. La barra inferior la pone el Scaffold contenedor.
class MedicoQueuePage extends StatelessWidget {
  final MedicoQueueHeaderData header;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final MedicoQueueFilterChipsData filters;
  final List<MedicoQueuePatientCardData> patients;
  final bool loading;
  final String? errorMessage;
  final String emptyMessage;
  final Future<void> Function()? onRefresh;

  const MedicoQueuePage({
    super.key,
    required this.header,
    required this.filters,
    required this.patients,
    this.searchController,
    this.onSearchChanged,
    this.loading = false,
    this.errorMessage,
    this.emptyMessage = 'Sin pacientes en sala.',
    this.onRefresh,
  });

  static const Color background = Color(0xFFF5F5F7);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: HomeScreenBody(
        header: [
          MedicoQueueHeaderWidget(data: header),
          const SizedBox(height: 16),
          MedicoSearchBar(
            controller: searchController,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 14),
          MedicoQueueFilterChipsWidget(data: filters),
          const SizedBox(height: 14),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
        isLoading: loading,
        onRefresh: onRefresh,
        slivers: [
          if (patients.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList.separated(
                itemCount: patients.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    MedicoQueuePatientCardWidget(data: patients[index]),
              ),
            ),
        ],
      ),
    );
  }
}
