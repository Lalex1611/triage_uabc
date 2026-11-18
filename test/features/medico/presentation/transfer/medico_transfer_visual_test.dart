// Sandbox de las pantallas de traslado del médico: confirmar recepción
// (mockup 03) y rechazar traslado (mockup 04). Sin backend.
//
// Run:
// flutter run -t test/features/medico/presentation/transfer/medico_transfer_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_review/medico_incoming_review.dart';
import 'package:sistema_triage/features/medico/presentation/transfer/medico_accept_transfer_page.dart';
import 'package:sistema_triage/features/medico/presentation/transfer/medico_reject_transfer_page.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: _Sandbox()),
  );
}

final _review = MedicoIncomingReview(
  patientId: '2031a7c0-0000-0000-0000-000000000000',
  displayName: 'Alberto Pérez',
  triage: TriageCategory.rojo,
  incidentId: '729ab000-0000-0000-0000-000000000000',
  paramedicName: 'Carlos Huerta',
  unitCode: 'A-12',
  estimatedArrivalAt: DateTime.now().add(
    const Duration(minutes: 6, seconds: 30),
  ),
);

class _Sandbox extends StatelessWidget {
  const _Sandbox();

  Future<void> _open(BuildContext context, Widget page) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => page),
    );
    debugPrint('resultado: $ok');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () => _open(
                context,
                MedicoAcceptTransferPage(
                  review: _review,
                  onConfirm: () => Future.delayed(const Duration(seconds: 1)),
                ),
              ),
              child: const Text('03 · Confirmar recepción'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _open(
                context,
                MedicoRejectTransferPage(
                  patientId: _review.patientId,
                  patientName: _review.displayName,
                  onReject: (reason) async {
                    debugPrint('motivo: $reason');
                    await Future.delayed(const Duration(seconds: 1));
                  },
                ),
              ),
              child: const Text('04 · Rechazar traslado'),
            ),
          ],
        ),
      ),
    );
  }
}
