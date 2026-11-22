import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/features/paramedico/data/offline/offline_capture_store.dart';
import 'package:sistema_triage/features/paramedico/data/offline/paramedico_offline_runtime.dart';
import 'package:sistema_triage/features/paramedico/presentation/offline/offline_connection_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/patient_intake_flow.dart';
import 'package:sistema_triage/shared/patient/consultation_code_qr_dialog.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Read-only local receipt. Remote edits/transfers remain in existing screens.
class OfflineCapturePage extends StatelessWidget {
  const OfflineCapturePage({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) {
    final runtime = ParamedicoOfflineRuntime.instance;
    return ListenableBuilder(
      listenable: runtime,
      builder: (context, _) {
        if (!runtime.canCapture) {
          return Scaffold(
            appBar: AppBar(title: const Text('Captura protegida')),
            body: const Center(
              child: Text(
                'Inicia sesión con conexión para consultar esta captura.',
              ),
            ),
          );
        }
        return FutureBuilder<List<Capture>>(
          key: ValueKey(runtime.account),
          future: runtime.captures(),
          builder: (context, snapshot) {
            final rows = snapshot.data ?? [];
            final matches = rows.where((r) => r['id'] == id);
            final row = matches.isEmpty ? null : matches.first;
            if (row == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Captura local')),
                body: Center(
                  child: Text(
                    snapshot.connectionState == ConnectionState.waiting
                        ? 'Cargando…'
                        : 'Captura no disponible para esta cuenta.',
                  ),
                ),
              );
            }
            final payload = row['payload'] as Map;
            final isIncident = row['kind'] == 'incident';
            final code = row['code'] as String?;
            return Scaffold(
              backgroundColor: TriageColors.canvas,
              body: Column(
                children: [
                  TriageDetailHeader(
                    title: isIncident
                        ? 'Incidente en este teléfono'
                        : 'Paciente en este teléfono',
                    subtitle: captureStatus(row),
                    onBack: () => context.canPop()
                        ? context.pop()
                        : context.go('/sin-conexion'),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(TriageSpacing.xl),
                      children: [
                        Text(
                          captureTitle(row),
                          style: TriageTextStyles.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Captura: ${(row['id'] as String).substring(0, 8).toUpperCase()}',
                        ),
                        Text('Fecha: ${row['captured_at']}'),
                        Text('Ubicación: ${payload['lat']}, ${payload['lng']}'),
                        if (!isIncident)
                          Text('Clasificación: ${payload['triage_color']}'),
                        if (payload['description'] != null)
                          Text(payload['description'] as String),
                        if (payload['demographics'] is Map) ...[
                          for (final entry
                              in (payload['demographics'] as Map).entries)
                            if (entry.value != null &&
                                !entry.key.toString().startsWith('photo_'))
                              Text(
                                '${_fieldLabel(entry.key.toString())}: ${entry.value is List ? (entry.value as List).join(', ') : entry.value}',
                              ),
                        ],
                        if (row['message'] != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(row['message'] as String),
                          ),
                        if (row['state'] == 'attention')
                          TriageButton(
                            label: 'Reintentar captura revisada',
                            variant: TriageButtonVariant.secondary,
                            onPressed: runtime.syncing
                                ? null
                                : () async {
                                    try {
                                      await runtime.retryReviewedCapture(id);
                                    } catch (_) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'No se pudo reintentar. La captura sigue guardada.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                          ),
                        for (final raw in row['photos'] as List)
                          _CapturePhoto(
                            capture: row,
                            photo: Capture.from(raw as Map),
                          ),
                        if (isIncident) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Pacientes capturados en este teléfono',
                            style: TriageTextStyles.titleMedium,
                          ),
                          for (final child in rows.where(
                            (r) => r['parent_id'] == id,
                          ))
                            ListTile(
                              title: Text(captureTitle(child)),
                              subtitle: Text(captureStatus(child)),
                              onTap: () => context.push(
                                '/paramedico/captura/${child['id']}',
                              ),
                            ),
                        ],
                        if (!isIncident && code?.isNotEmpty == true)
                          TriageButton(
                            label: 'Código de consulta',
                            variant: TriageButtonVariant.secondary,
                            onPressed: () => ConsultationCodeQrDialog.show(
                              context,
                              code: code!,
                            ),
                          ),
                        if (!isIncident && code?.isNotEmpty != true)
                          const Text(
                            'El QR estará disponible cuando el servidor confirme el código.',
                          ),
                        const SizedBox(height: 16),
                        if (row['state'] == 'synced')
                          TriageButton(
                            label: 'Abrir registro del servidor',
                            variant: TriageButtonVariant.secondary,
                            onPressed: runtime.offline
                                ? null
                                : () => context.push(
                                    '/paramedico/${isIncident ? 'incident' : 'patient'}/${row['remote_id']}',
                                  ),
                          ),
                      ],
                    ),
                  ),
                  if (isIncident)
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(TriageSpacing.xl),
                        child: TriageButton(
                          label: 'Registrar paciente',
                          onPressed: () => startPatientIntake(
                            context,
                            incidentId: id,
                            subtitle: captureTitle(row),
                            onPatientsChanged: runtime.refreshView,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _fieldLabel(String key) =>
      const {
        'description': 'Descripción',
        'gender': 'Género',
        'blood_type': 'Grupo sanguíneo',
        'birth_day': 'Día de nacimiento',
        'birth_month': 'Mes de nacimiento',
        'birth_year': 'Año de nacimiento',
        'emergency_contact': 'Contacto de emergencia',
        'injury_types': 'Lesiones',
        'registered_from_start': 'Registro START',
        'start_triage_mode': 'Modo START',
      }[key] ??
      key;
}

class _CapturePhoto extends StatelessWidget {
  const _CapturePhoto({required this.capture, required this.photo});
  final Capture capture;
  final Capture photo;
  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: ParamedicoOfflineRuntime.instance.photoBytes(capture, photo),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Image.memory(
            snapshot.data!,
            height: 180,
            fit: BoxFit.contain,
            gaplessPlayback: false,
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          snapshot.hasError
              ? capture['state'] == 'synced'
                    ? 'Foto conservada en el servidor; requiere conexión para consultarla.'
                    : 'No se pudo abrir la foto local. Reintenta; la captura sigue guardada.'
              : 'Cargando foto…',
        ),
      );
    },
  );
}
