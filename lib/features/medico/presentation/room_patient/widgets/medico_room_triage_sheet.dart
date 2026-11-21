import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_level.dart';
import 'package:sistema_triage/features/medico/presentation/room_patient/medico_room_format.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

/// Hoja para cambiar el triage hospitalario del paciente en sala (lápiz de la
/// tarjeta de color, mockup 06). Devuelve el nivel elegido o null si se cerró.
class MedicoRoomTriageSheet extends StatelessWidget {
  const MedicoRoomTriageSheet({super.key, required this.current});

  final TriageCategory current;

  static const levels = [
    TriageCategory.rojo,
    TriageCategory.naranja,
    TriageCategory.amarillo,
    TriageCategory.verde,
    TriageCategory.azul,
  ];

  static Future<TriageCategory?> show(
    BuildContext context, {
    required TriageCategory current,
  }) {
    return showModalBottomSheet<TriageCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MedicoRoomTriageSheet(current: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Triage hospitalario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Elige el nivel actual del paciente.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF5C6670)),
            ),
            const SizedBox(height: 12),
            for (final c in levels) _option(context, c),
          ],
        ),
      ),
    );
  }

  Widget _option(BuildContext context, TriageCategory c) {
    final level = MedicoTriageLevel.levelOf(c);
    final selected = c == current;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => Navigator.of(context).pop(c),
      leading: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: MedicoTriageLevel.colorOf(c),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${level ?? ''}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: c == TriageCategory.amarillo
                ? const Color(0xFF1A1A1A)
                : Colors.white,
          ),
        ),
      ),
      title: Text(
        '${MedicoRoomFormat.colorName(c.name)} · ${MedicoRoomFormat.levelName(c)}',
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: Color(0xFF1C69AA))
          : null,
    );
  }
}
