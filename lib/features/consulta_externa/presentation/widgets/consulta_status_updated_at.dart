import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

/// Actualiza el tiempo transcurrido localmente; no realiza consultas al servidor.
class ConsultaStatusUpdatedAt extends StatefulWidget {
  final DateTime timestamp;

  const ConsultaStatusUpdatedAt({super.key, required this.timestamp});

  @override
  State<ConsultaStatusUpdatedAt> createState() =>
      _ConsultaStatusUpdatedAtState();
}

class _ConsultaStatusUpdatedAtState extends State<ConsultaStatusUpdatedAt> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final local = widget.timestamp.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    final exact =
        '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
    final age = DateTime.now().difference(widget.timestamp);
    final String label;
    if (age.isNegative) {
      // No atribuir una antigüedad ficticia si el reloj del dispositivo está atrasado.
      label = 'Actualizado el $exact';
    } else if (age.inMinutes < 1) {
      label = 'Actualizado hace menos de un minuto';
    } else if (age.inHours < 1) {
      label =
          'Actualizado hace ${age.inMinutes} ${age.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else if (age.inDays < 1) {
      label =
          'Actualizado hace ${age.inHours} ${age.inHours == 1 ? 'hora' : 'horas'}';
    } else {
      label =
          'Actualizado hace ${age.inDays} ${age.inDays == 1 ? 'día' : 'días'}';
    }
    return Semantics(
      label: 'Último cambio de estado: $exact, hora local del dispositivo',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Último cambio de estado: $exact (hora local)',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, size: 16, color: Color(0xFF8695A8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                  fontSize: 13,
                  height: 1.46,
                  color: const Color(0xFF8695A8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
