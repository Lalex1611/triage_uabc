import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/medico/data/repositories/medico_profile_repository.dart';
import 'package:sistema_triage/features/medico/domain/entities/profile/medico_profile_menu_item_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/profile/medico_profile_section_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/profile/medico_profile_summary.dart';
import 'package:sistema_triage/features/medico/presentation/profile/medico_profile_page.dart';
import 'package:sistema_triage/features/medico/presentation/profile/widgets/medico_capacity_edit_sheet.dart';

/// Pestaña Perfil del médico (mockup 13): carga el resumen del backend,
/// permite editar la capacidad de urgencias y cerrar sesión.
class MedicoProfileTab extends StatefulWidget {
  const MedicoProfileTab({
    super.key,
    required this.userName,
    required this.onBack,
    required this.onSignOut,
    required this.onNotificationsTap,
    this.repository,
  });

  final String userName;
  final VoidCallback onBack;
  final VoidCallback onSignOut;

  /// Abre el panel de notificaciones del médico
  final VoidCallback onNotificationsTap;
  final MedicoProfileRepository? repository;

  @override
  State<MedicoProfileTab> createState() => _MedicoProfileTabState();
}

class _MedicoProfileTabState extends State<MedicoProfileTab> {
  late final MedicoProfileRepository _repo;
  MedicoProfileSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? MedicoProfileRepository();
    unawaited(_load());
  }

  /// Número de la carga más reciente; solo esa aplica su resultado (al
  /// abrir, al deslizar y tras editar pueden cruzarse varias)
  int _loadGeneration = 0;

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    bool isCurrent() => mounted && generation == _loadGeneration;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _repo.fetchSummary();
      if (isCurrent()) setState(() => _summary = s);
    } catch (e) {
      if (isCurrent()) {
        setState(
          () =>
              _error = 'No se pudo cargar el perfil. Desliza para reintentar.',
        );
      }
    } finally {
      if (isCurrent()) setState(() => _loading = false);
    }
  }

  Future<void> _editCapacity() async {
    final s = _summary;
    if (s == null) return;
    final saved = await MedicoCapacityEditSheet.show(
      context,
      initial: s.capacity,
      onSave: (c) => _repo.updateCapacity(
        shockBedsFree: c.shockBedsFree,
        shockBedsTotal: c.shockBedsTotal,
        observationBedsFree: c.observationBedsFree,
        observationBedsTotal: c.observationBedsTotal,
        acceptingRedPatients: c.acceptingRedPatients,
        operatingRoomAvailable: c.operatingRoomAvailable,
      ),
    );
    if (!saved || !mounted) return;
    showAppSnackBar(context, 'Capacidad actualizada.');
    await _load();
  }

  static String _beds(int? free, int? total) {
    if (free == null && total == null) return '—';
    return '${free ?? '—'} de ${total ?? '—'}';
  }

  static String _yesNo(bool? v) => v == null ? '—' : (v ? 'Sí' : 'No');

  static String _updatedLabel(DateTime? at) {
    if (at == null) return 'Sin capturar todavía. Toca «Editar».';
    final diff = DateTime.now().difference(at);
    final String ago;
    if (diff.inMinutes < 1) {
      ago = 'hace un momento';
    } else if (diff.inMinutes < 60) {
      ago = 'hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      ago = 'hace ${diff.inHours} h';
    } else {
      ago = diff.inDays == 1 ? 'hace 1 día' : 'hace ${diff.inDays} días';
    }
    return 'Actualizado $ago';
  }

  List<MedicoProfileSectionData> _sections(MedicoProfileSummary s) {
    final c = s.capacity;
    final g = s.shift;
    return [
      MedicoProfileSectionData(
        title: 'Capacidad de urgencias',
        actionLabel: 'Editar',
        onActionTap: () => unawaited(_editCapacity()),
        footnote: _updatedLabel(c.updatedAt),
        rows: [
          MedicoProfileRowData(
            label: 'Camas de choque libres',
            value: _beds(c.shockBedsFree, c.shockBedsTotal),
          ),
          MedicoProfileRowData(
            label: 'Camas de observación libres',
            value: _beds(c.observationBedsFree, c.observationBedsTotal),
          ),
          MedicoProfileRowData(
            label: 'Recibiendo pacientes rojos',
            value: _yesNo(c.acceptingRedPatients),
          ),
          MedicoProfileRowData(
            label: 'Quirófano disponible',
            value: _yesNo(c.operatingRoomAvailable),
          ),
        ],
      ),
      MedicoProfileSectionData(
        title: 'Guardia de hoy',
        rows: [
          MedicoProfileRowData(
            label: 'Pacientes recibidos',
            value: '${g.received}',
          ),
          MedicoProfileRowData(
            label: 'Traslados rechazados',
            value: '${g.rejected}',
          ),
          MedicoProfileRowData(
            label: 'Altas registradas',
            value: '${g.discharged}',
          ),
          MedicoProfileRowData(label: 'En sala ahora', value: '${g.inRoom}'),
        ],
      ),
    ];
  }

  /// Opciones aún sin pantalla propia
  void _comingSoon(String what) {
    showAppSnackBar(context, '$what estará disponible próximamente.');
  }

  List<MedicoProfileMenuItemData> _menuItems() => [
    MedicoProfileMenuItemData(
      icon: Icons.notifications_none_rounded,
      label: 'Notificaciones',
      onTap: widget.onNotificationsTap,
    ),
    MedicoProfileMenuItemData(
      icon: Icons.verified_user_outlined,
      label: 'Privacidad y permisos',
      onTap: () => _comingSoon('Privacidad y permisos'),
    ),
    MedicoProfileMenuItemData(
      icon: Icons.error_outline_rounded,
      label: 'Ayuda y soporte',
      onTap: () => _comingSoon('Ayuda y soporte'),
    ),
    MedicoProfileMenuItemData(
      icon: Icons.description_outlined,
      label: 'Términos y aviso de privacidad',
      onTap: () => _comingSoon('Términos y aviso de privacidad'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final s = _summary;
    final hospitalLabel = s == null
        ? (_loading ? 'Cargando hospital…' : 'Hospital no disponible')
        : MedicoProfileSummary.hospitalLabel(
            s.hospitalName,
            s.hospitalAreaLabel,
          );

    return MedicoProfilePage(
      userName: widget.userName,
      hospitalLabel: hospitalLabel,
      sections: s == null ? const [] : _sections(s),
      menuItems: _menuItems(),
      loading: _loading,
      errorMessage: _error,
      onRefresh: _load,
      onBackTap: widget.onBack,
      onSignOutTap: widget.onSignOut,
    );
  }
}
