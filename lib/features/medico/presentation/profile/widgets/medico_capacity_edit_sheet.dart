import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/profile/medico_profile_summary.dart';

/// Hoja inferior para editar la capacidad de urgencias del hospital.
/// Devuelve `true` si se guardó.
class MedicoCapacityEditSheet extends StatefulWidget {
  const MedicoCapacityEditSheet({
    super.key,
    required this.initial,
    required this.onSave,
  });

  final MedicoHospitalCapacity initial;

  /// Guarda en el backend; si lanza, el error se muestra en la hoja
  final Future<void> Function(MedicoHospitalCapacity capacity) onSave;

  static Future<bool> show(
    BuildContext context, {
    required MedicoHospitalCapacity initial,
    required Future<void> Function(MedicoHospitalCapacity) onSave,
  }) async {
    // Último guardado iniciado: si la hoja se cierra mientras guarda (toque
    // fuera, arrastre o Atrás), se espera aquí para no perder la recarga
    Future<void>? pending;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MedicoCapacityEditSheet(
        initial: initial,
        onSave: (c) => pending = onSave(c),
      ),
    );
    if (ok == true) return true;
    // Cancelado antes de guardar
    if (pending == null) return false;
    try {
      await pending;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  State<MedicoCapacityEditSheet> createState() =>
      _MedicoCapacityEditSheetState();
}

class _MedicoCapacityEditSheetState extends State<MedicoCapacityEditSheet> {
  static const _primary = Color(0xFF1C69AA);
  static const _maxBeds = 999;

  late int _shockFree = widget.initial.shockBedsFree ?? 0;
  late int _shockTotal = widget.initial.shockBedsTotal ?? 0;
  late int _obsFree = widget.initial.observationBedsFree ?? 0;
  late int _obsTotal = widget.initial.observationBedsTotal ?? 0;
  late bool _acceptingRed = widget.initial.acceptingRedPatients ?? true;
  late bool _orAvailable = widget.initial.operatingRoomAvailable ?? false;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        MedicoHospitalCapacity(
          shockBedsFree: _shockFree,
          shockBedsTotal: _shockTotal,
          observationBedsFree: _obsFree,
          observationBedsTotal: _obsTotal,
          acceptingRedPatients: _acceptingRed,
          operatingRoomAvailable: _orAvailable,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      final match = RegExp(r'message: ([^,]+)').firstMatch('$e');
      if (mounted) {
        setState(() {
          _saving = false;
          _error = match?.group(1)?.trim() ?? '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom =
        MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;

    // Desplazable: en pantallas bajas (o con letra grande) Guardar y el error
    // siguen al alcance; la hoja nunca pasa de la altura disponible
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Capacidad de urgencias',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'La ven todos los médicos de su hospital.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF5C6670)),
          ),
          const SizedBox(height: 16),
          _bedsBlock(
            title: 'Camas de choque',
            free: _shockFree,
            total: _shockTotal,
            onFree: (v) => setState(() => _shockFree = v),
            onTotal: (v) => setState(() {
              _shockTotal = v;
              if (_shockFree > v) _shockFree = v;
            }),
          ),
          const SizedBox(height: 12),
          _bedsBlock(
            title: 'Camas de observación',
            free: _obsFree,
            total: _obsTotal,
            onFree: (v) => setState(() => _obsFree = v),
            onTotal: (v) => setState(() {
              _obsTotal = v;
              if (_obsFree > v) _obsFree = v;
            }),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeTrackColor: _primary,
            title: const Text(
              'Recibiendo pacientes rojos',
              style: TextStyle(fontSize: 14),
            ),
            value: _acceptingRed,
            onChanged: _saving
                ? null
                : (v) => setState(() => _acceptingRed = v),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeTrackColor: _primary,
            title: const Text(
              'Quirófano disponible',
              style: TextStyle(fontSize: 14),
            ),
            value: _orAvailable,
            onChanged: _saving ? null : (v) => setState(() => _orAvailable = v),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFC62828), fontSize: 13),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Guardar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1A1A1A),
            ),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _bedsBlock({
    required String title,
    required int free,
    required int total,
    required ValueChanged<int> onFree,
    required ValueChanged<int> onTotal,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          _stepperRow('Libres', free, 0, total, onFree),
          _stepperRow('Total', total, 0, _maxBeds, onTotal),
        ],
      ),
    );
  }

  Widget _stepperRow(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF3F4850)),
          ),
        ),
        IconButton(
          onPressed: _saving || value <= min
              ? null
              : () => onChanged(value - 1),
          icon: const Icon(Icons.remove_circle_outline),
          color: _primary,
          tooltip: 'Quitar',
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: _saving || value >= max
              ? null
              : () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
          color: _primary,
          tooltip: 'Agregar',
        ),
      ],
    );
  }
}
