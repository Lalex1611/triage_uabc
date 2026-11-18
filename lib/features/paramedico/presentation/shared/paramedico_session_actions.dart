import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/session/auth_gate.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedic_notifications_repository.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/services/incident_location_service.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/notifications/paramedic_notification.dart';
import 'package:sistema_triage/features/paramedico/presentation/notifications/widgets/paramedic_notifications_modal_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Acciones de sesión compartidas para el perfil de paramédico
class ParamedicoSessionActions {
  ParamedicoSessionActions._();

  static Future<void> openProfileSheet(BuildContext context) async {
    final parentContext = context;
    final incidentsRepo = ParamedicoIncidentsRepository();
    final notificationsRepo = ParamedicNotificationsRepository();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TriageColors.surface.withValues(alpha: 0),
      builder: (_) => _ParamedicoProfileSheet(
        parentContext: parentContext,
        repo: incidentsRepo,
        notificationsRepo: notificationsRepo,
      ),
    );
  }

  static Future<String?> _openUnitCodeDialog(
    BuildContext context,
    ParamedicoIncidentsRepository repo,
    String? initialCode,
  ) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UnitCodeDialog(
        parentContext: context,
        repo: repo,
        initialCode: initialCode,
      ),
    );
  }

  static Future<void> confirmSignOut(BuildContext context) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: TriageColors.surface.withValues(alpha: 0),
      isScrollControlled: true,
      builder: (ctx) => _ProfileFloatingSheet(
        showDragHandle: false,
        padding: const EdgeInsets.fromLTRB(
          TriageSpacing.xl,
          TriageSpacing.xl + 4,
          TriageSpacing.xl,
          TriageSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: TriageColors.paramedicAccent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: TriageColors.paramedicAccent,
                size: 28,
              ),
            ),
            const SizedBox(height: TriageSpacing.lg),
            Text(
              '¿Cerrar sesión?',
              textAlign: TextAlign.center,
              style: TriageTextStyles.titleLarge.copyWith(
                color: TriageColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: TriageSpacing.sm),
            Text(
              'Si compartes el equipo, deja la sesión cerrada al terminar tu turno.',
              textAlign: TextAlign.center,
              style: TriageTextStyles.bodyMedium.copyWith(
                color: TriageColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: TriageSpacing.xl),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TriageRadii.md + 4),
                boxShadow: [
                  BoxShadow(
                    color: TriageColors.paramedicAccent.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: TriageColors.paramedicAccent,
                    foregroundColor: TriageColors.textInverse,
                    padding: const EdgeInsets.symmetric(
                      vertical: TriageSpacing.md + 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TriageRadii.md + 4),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    'Cerrar sesión',
                    style: TriageTextStyles.titleSmall.copyWith(
                      color: TriageColors.textInverse,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: TriageSpacing.sm),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: TriageColors.textSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: TriageSpacing.lg,
                  vertical: TriageSpacing.sm + 2,
                ),
              ),
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancelar',
                style: TriageTextStyles.labelLarge.copyWith(
                  color: TriageColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (ok == true && context.mounted) {
      await AuthGate.instance.signOut();
      if (context.mounted) context.go('/auth');
    }
  }
}

class _ParamedicoProfileSheet extends StatefulWidget {
  const _ParamedicoProfileSheet({
    required this.parentContext,
    required this.repo,
    required this.notificationsRepo,
  });

  final BuildContext parentContext;
  final ParamedicoIncidentsRepository repo;
  final ParamedicNotificationsRepository notificationsRepo;

  @override
  State<_ParamedicoProfileSheet> createState() =>
      _ParamedicoProfileSheetState();
}

class _ParamedicoProfileSheetState extends State<_ParamedicoProfileSheet> {
  bool _loading = true;
  String? _unitCode;
  int _incidentsCount = 0;
  int _patientsCount = 0;
  int _transfersCount = 0;
  List<ParamedicNotification> _notifications = const [];
  late final String _shiftStartTime;

  @override
  void initState() {
    super.initState();
    _shiftStartTime = _resolveSessionStartTime();
    _loadData();
  }

  String _resolveSessionStartTime() {
    if (!SupabaseEnv.isConfigured) return '—';
    final raw = Supabase.instance.client.auth.currentUser?.lastSignInAt;
    if (raw == null || raw.isEmpty) return '—';
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return '—';
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<List<ParamedicNotification>> _safeListNotifications() async {
    try {
      return await widget.notificationsRepo.listRecent();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _openNotificationsModal() async {
    await showDialog<void>(
      context: context,
      builder: (_) => ParamedicNotificationsModal(
        notifications: _notifications,
        onNotificationTap: (notification) =>
            widget.notificationsRepo.markRead(notification.id),
      ),
    );
    if (!mounted) return;
    final updated = await _safeListNotifications();
    if (mounted) {
      setState(() => _notifications = updated);
    }
  }

  Future<void> _openSubSheet(Widget sheet) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: TriageColors.surface.withValues(alpha: 0),
      isScrollControlled: true,
      builder: (_) => sheet,
    );
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait<dynamic>([
        widget.repo.currentAmbulanceUnitCode(),
        widget.repo.listOpenIncidents(),
        widget.repo.listRecentPatientsForCurrentUser(limit: 100),
        _safeListNotifications(),
      ]);

      final code = results[0] as String?;
      final incidents = results[1] as List<ParamedicoIncidentSummary>;
      final recentPatients = results[2] as List<ParamedicoPatientRow>;
      final notifications = results[3] as List<ParamedicNotification>;

      final now = DateTime.now();
      final todayPatients = recentPatients.where((p) {
        final created = p.createdAt?.toLocal();
        if (created == null) return false;
        return created.year == now.year &&
            created.month == now.month &&
            created.day == now.day;
      }).toList();

      final confirmedTransfers = todayPatients.where((p) {
        return p.status == 'trasladando' ||
            p.status == 'recibido' ||
            p.status == 'alta_medica';
      }).length;

      if (!mounted) return;
      setState(() {
        _unitCode = code;
        _incidentsCount = incidents.length;
        _patientsCount = todayPatients.length;
        _transfersCount = confirmedTransfers;
        _notifications = notifications;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _editUnit() async {
    final newCode = await ParamedicoSessionActions._openUnitCodeDialog(
      context,
      widget.repo,
      _unitCode,
    );
    if (newCode != null && mounted) {
      setState(() => _unitCode = newCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final sheetHeight = media.size.height - media.padding.top - 64;
    final fullName = AuthGate.instance.fullName ?? 'Cuenta activa';
    final unreadNotifications = _notifications.where((n) => n.isUnread).length;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: TriageColors.textPrimary.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Encabezado con manija superior y botón de regreso
          Container(
            padding: const EdgeInsets.fromLTRB(
              TriageSpacing.sm,
              TriageSpacing.sm,
              TriageSpacing.lg,
              TriageSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: TriageColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                bottom: BorderSide(color: TriageColors.borderSubtle),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TriageColors.borderMedium,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: TriageSpacing.sm),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: TriageColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: TriageSpacing.xs),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mi perfil',
                          style: TriageTextStyles.titleMedium.copyWith(
                            color: TriageColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Turno actual',
                          style: TriageTextStyles.bodySmall.copyWith(
                            color: TriageColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Cuerpo desplazable con tarjetas del turno
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                TriageSpacing.lg,
                TriageSpacing.lg,
                TriageSpacing.lg,
                media.padding.bottom + 88,
              ),
              children: [
                // 1. Tarjeta de identidad del paramédico
                Container(
                  padding: const EdgeInsets.all(TriageSpacing.lg),
                  decoration: BoxDecoration(
                    color: TriageColors.paramedicAccent,
                    borderRadius: BorderRadius.circular(TriageRadii.md + 4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: TriageColors.textInverse.withValues(
                            alpha: 0.16,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: TriageColors.textInverse,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: TriageSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PARAMÉDICO',
                              style: TriageTextStyles.labelSmall.copyWith(
                                color: TriageColors.textInverse.withValues(
                                  alpha: 0.85,
                                ),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TriageTextStyles.titleLarge.copyWith(
                                color: TriageColors.textInverse,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cruz Roja Mexicana · Tijuana',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TriageTextStyles.bodySmall.copyWith(
                                color: TriageColors.textInverse.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TriageSpacing.md),

                // 2. Tarjeta de unidad asignada
                TriageSectionCard(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: TriageColors.paramedicAccent.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(TriageRadii.md),
                        ),
                        child: const Center(
                          child: TriageIcon(
                            TriageIcons.ambulance,
                            color: TriageColors.paramedicAccent,
                            size: TriageSizes.icon,
                          ),
                        ),
                      ),
                      const SizedBox(width: TriageSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UNIDAD ASIGNADA',
                              style: TriageTextStyles.labelSmall.copyWith(
                                color: TriageColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _loading ? '...' : (_unitCode ?? 'Sin asignar'),
                              style: TriageTextStyles.titleLarge.copyWith(
                                color: TriageColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: TriageColors.borderSubtle,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _editUnit,
                          child: const SizedBox(
                            width: 38,
                            height: 38,
                            child: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: TriageColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TriageSpacing.md),

                // 3. Resumen del turno de hoy
                TriageSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Turno de hoy',
                        style: TriageTextStyles.titleMedium.copyWith(
                          color: TriageColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: TriageSpacing.md),
                      _ShiftMetricRow(
                        label: 'Incidentes atendidos',
                        value: _loading ? '—' : '$_incidentsCount',
                      ),
                      const SizedBox(height: TriageSpacing.md),
                      _ShiftMetricRow(
                        label: 'Pacientes registrados',
                        value: _loading ? '—' : '$_patientsCount',
                      ),
                      const SizedBox(height: TriageSpacing.md),
                      _ShiftMetricRow(
                        label: 'Traslados confirmados',
                        value: _loading ? '—' : '$_transfersCount',
                      ),
                      const SizedBox(height: TriageSpacing.md),
                      _ShiftMetricRow(
                        label: 'Entró en turno',
                        value: _shiftStartTime,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TriageSpacing.md),

                // 4. Opciones de configuración, privacidad y soporte
                TriageSectionCard(
                  child: Column(
                    children: [
                      _ProfileMenuRow(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notificaciones',
                        badgeCount: unreadNotifications,
                        onTap: _openNotificationsModal,
                      ),
                      const SizedBox(height: TriageSpacing.lg),
                      _ProfileMenuRow(
                        icon: Icons.verified_user_outlined,
                        title: 'Privacidad y permisos',
                        onTap: () =>
                            IncidentLocationService.showPermissionsSheet(
                              context,
                            ),
                      ),
                      const SizedBox(height: TriageSpacing.lg),
                      _ProfileMenuRow(
                        icon: Icons.info_outline_rounded,
                        title: 'Ayuda y soporte',
                        onTap: () => _openSubSheet(const _BasicGuideSheet()),
                      ),
                      const SizedBox(height: TriageSpacing.lg),
                      _ProfileMenuRow(
                        icon: Icons.description_outlined,
                        title: 'Términos y aviso de privacidad',
                        onTap: () =>
                            _openSubSheet(const _InstitutionalTermsSheet()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TriageSpacing.md),

                // 5. Botón independiente de cerrar sesión
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(TriageRadii.md + 4),
                    boxShadow: [
                      BoxShadow(
                        color: TriageColors.textPrimary.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: TriageColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TriageRadii.md + 4),
                      side: const BorderSide(color: TriageColors.borderMedium),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(TriageRadii.md + 4),
                      onTap: () async {
                        Navigator.of(context).pop();
                        if (!widget.parentContext.mounted) return;
                        await ParamedicoSessionActions.confirmSignOut(
                          widget.parentContext,
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: TriageSpacing.md + 2,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Cerrar sesión',
                          style: TriageTextStyles.titleSmall.copyWith(
                            color: TriageColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BasicGuideSheet extends StatelessWidget {
  const _BasicGuideSheet();

  @override
  Widget build(BuildContext context) {
    return _ProfileFloatingSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ProfileSheetHeader(
            icon: Icons.menu_book_outlined,
            title: 'Guía básica de operación',
            subtitle: 'Flujo rápido en campo y traslado',
          ),
          const SizedBox(height: TriageSpacing.md),
          const _GuideStepItem(
            step: '1',
            title: 'Verifica tu unidad al iniciar',
            description:
                'Confirma o edita tu número económico (ej. CRT-101) en Mi perfil antes de iniciar traslados.',
          ),
          const SizedBox(height: TriageSpacing.md),
          const _GuideStepItem(
            step: '2',
            title: 'Registra incidente o paciente rápido',
            description:
                'Crea un incidente activo para múltiples lesionados o usa registro directo para atención individual, asignando color de triage.',
          ),
          const SizedBox(height: TriageSpacing.md),
          const _GuideStepItem(
            step: '3',
            title: 'Asigna hospital y atiende alertas',
            description:
                'Inicia el traslado hacia el hospital disponible. Si el centro rechaza por saturación, recibirás aviso para reasignar destino.',
          ),
          const SizedBox(height: TriageSpacing.md),
          const _GuideStepItem(
            step: '4',
            title: 'Comparte el folio de consulta',
            description:
                'Entrega el código generado a recepción hospitalaria o familiares para dar seguimiento al estado del paciente.',
          ),
          const SizedBox(height: TriageSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: TriageColors.paramedicAccent,
                foregroundColor: TriageColors.textInverse,
                padding: const EdgeInsets.symmetric(
                  vertical: TriageSpacing.md + 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TriageRadii.md + 4),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Entendido',
                style: TriageTextStyles.titleSmall.copyWith(
                  color: TriageColors.textInverse,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstitutionalTermsSheet extends StatelessWidget {
  const _InstitutionalTermsSheet();

  @override
  Widget build(BuildContext context) {
    return _ProfileFloatingSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ProfileSheetHeader(
            icon: Icons.verified_user_outlined,
            title: 'Uso institucional',
            subtitle: 'Términos y confidencialidad clínica',
          ),
          const SizedBox(height: TriageSpacing.md),
          Container(
            padding: const EdgeInsets.all(TriageSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(TriageRadii.md + 2),
              border: Border.all(color: TriageColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plataforma exclusiva de atención prehospitalaria',
                  style: TriageTextStyles.titleSmall.copyWith(
                    color: TriageColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TriageSpacing.xs),
                Text(
                  'El acceso y operación de este sistema están reservados únicamente para personal autorizado de Cruz Roja Mexicana y centros hospitalarios vinculados.',
                  style: TriageTextStyles.bodySmall.copyWith(
                    color: TriageColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TriageSpacing.md),
          Text(
            '• Confidencialidad: Los signos vitales, lesiones y datos de identidad capturados son información clínica protegida; queda prohibida su difusión externa.',
            style: TriageTextStyles.bodySmall.copyWith(
              color: TriageColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: TriageSpacing.xs + 2),
          Text(
            '• Trazabilidad: Toda captura, asignación de unidad y cambio de traslado queda registrado bajo tu sesión institucional activa.',
            style: TriageTextStyles.bodySmall.copyWith(
              color: TriageColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: TriageSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: TriageColors.paramedicAccent,
                foregroundColor: TriageColors.textInverse,
                padding: const EdgeInsets.symmetric(
                  vertical: TriageSpacing.md + 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TriageRadii.md + 4),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cerrar',
                style: TriageTextStyles.titleSmall.copyWith(
                  color: TriageColors.textInverse,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitCodeDialog extends StatefulWidget {
  const _UnitCodeDialog({
    required this.parentContext,
    required this.repo,
    this.initialCode,
  });

  final BuildContext parentContext;
  final ParamedicoIncidentsRepository repo;
  final String? initialCode;

  @override
  State<_UnitCodeDialog> createState() => _UnitCodeDialogState();
}

class _UnitCodeDialogState extends State<_UnitCodeDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCode ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final code = await widget.repo.setCurrentAmbulanceUnitCode(
        _controller.text,
      );
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).pop(code);
      if (widget.parentContext.mounted) {
        showAppSnackBar(widget.parentContext, 'Unidad registrada: $code');
      }
    } catch (e) {
      if (widget.parentContext.mounted) {
        showAppSnackBar(
          widget.parentContext,
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: TriageColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TriageRadii.md),
      ),
      title: Text(
        'Código de unidad',
        style: TriageTextStyles.titleMedium.copyWith(
          color: TriageColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: TextField(
        controller: _controller,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          hintText: 'Ej. CRT-101',
          labelText: 'Número económico',
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.of(context).pop();
                },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: TriageColors.paramedicAccent,
            foregroundColor: TriageColors.textInverse,
          ),
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}

class _ProfileFloatingSheet extends StatelessWidget {
  const _ProfileFloatingSheet({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      TriageSpacing.lg,
      TriageSpacing.md,
      TriageSpacing.lg,
      TriageSpacing.lg,
    ),
    this.showDragHandle = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        TriageSpacing.md,
        TriageSpacing.md,
        TriageSpacing.md,
        bottomInset + TriageSpacing.md,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: TriageColors.surface,
          borderRadius: BorderRadius.circular(TriageRadii.xxl),
          boxShadow: TriageShadows.floating,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDragHandle) ...[
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TriageColors.borderMedium,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: TriageSpacing.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _ProfileSheetHeader extends StatelessWidget {
  const _ProfileSheetHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: TriageColors.paramedicAccent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: TriageColors.paramedicAccent, size: 22),
            ),
            const SizedBox(width: TriageSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TriageTextStyles.titleMedium.copyWith(
                      color: TriageColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TriageTextStyles.bodySmall.copyWith(
                      color: TriageColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TriageIconButton(
              icon: TriageIcons.close,
              tooltip: 'Cerrar',
              onPressed: () => Navigator.of(context).pop(),
              variant: TriageIconButtonVariant.plain,
              iconSize: TriageSizes.iconLarge,
            ),
          ],
        ),
        const SizedBox(height: TriageSpacing.md),
        const Divider(
          height: TriageSizes.hairline,
          thickness: TriageSizes.hairline,
          color: TriageColors.borderSubtle,
        ),
      ],
    );
  }
}

class _GuideStepItem extends StatelessWidget {
  const _GuideStepItem({
    required this.step,
    required this.title,
    required this.description,
  });

  final String step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TriageColors.paramedicAccent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: TriageTextStyles.labelSmall.copyWith(
              color: TriageColors.paramedicAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: TriageSpacing.sm + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TriageTextStyles.bodyMedium.copyWith(
                  color: TriageColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TriageTextStyles.bodySmall.copyWith(
                  color: TriageColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShiftMetricRow extends StatelessWidget {
  const _ShiftMetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TriageTextStyles.bodyMedium.copyWith(
            color: TriageColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TriageTextStyles.labelLarge.copyWith(
            color: TriageColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TriageRadii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TriageSpacing.xs),
        child: Row(
          children: [
            Icon(icon, color: TriageColors.textSecondary, size: 20),
            const SizedBox(width: TriageSpacing.md),
            Expanded(
              child: Text(
                title,
                style: TriageTextStyles.bodyMedium.copyWith(
                  color: TriageColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (badgeCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TriageSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: TriageColors.paramedicAccent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$badgeCount',
                  style: TriageTextStyles.labelSmall.copyWith(
                    color: TriageColors.textInverse,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: TriageSpacing.xs),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: TriageColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
