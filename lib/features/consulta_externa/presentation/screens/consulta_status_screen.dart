import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:postgrest/postgrest.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/consulta_externa/domain/constants/consulta_status.dart';
import 'package:sistema_triage/features/consulta_externa/domain/consulta_lookup_result.dart';
import 'package:sistema_triage/features/consulta_externa/domain/consulta_code.dart';
import 'package:sistema_triage/features/consulta_externa/domain/consulta_rate_limit_exception.dart';
import 'package:sistema_triage/features/consulta_externa/data/repositories/consulta_repository.dart';
import 'package:sistema_triage/features/consulta_externa/presentation/widgets/consulta_status_updated_at.dart';

class ConsultaStatusScreen extends StatefulWidget {
  final ConsultaLookupResult result;
  final ConsultaRepository? repository;

  const ConsultaStatusScreen({
    super.key,
    required this.result,
    this.repository,
  });

  @override
  State<ConsultaStatusScreen> createState() => _ConsultaStatusScreenState();
}

class _ConsultaStatusScreenState extends State<ConsultaStatusScreen>
    with WidgetsBindingObserver {
  late final ConsultaRepository _repo;
  late ConsultaLookupResult result;
  Timer? _pollTimer;
  Timer? _cooldownTimer;
  bool _active = true;
  bool _refreshing = false;
  bool _canRefresh = true;
  bool _codeInvalid = false;
  String? _refreshNotice;
  int _requestVersion = 0;

  bool get _hasLookupCode =>
      SupabaseEnv.isConfigured && ConsultaCode.isValid(result.code ?? '');

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ConsultaRepository();
    result = widget.result;
    _active =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _schedulePoll();
  }

  @override
  void didUpdateWidget(covariant ConsultaStatusScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.result, widget.result)) {
      _requestVersion++;
      _pollTimer?.cancel();
      _cooldownTimer?.cancel();
      result = widget.result;
      _refreshing = false;
      _canRefresh = true;
      _codeInvalid = false;
      _refreshNotice = null;
      _schedulePoll();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (!_active) {
      _pollTimer?.cancel();
    } else if (_canRefresh && !_refreshing) {
      unawaited(_refresh());
    } else {
      _schedulePoll();
    }
  }

  void _schedulePoll([Duration delay = const Duration(minutes: 1)]) {
    _pollTimer?.cancel();
    if (!_active || !_hasLookupCode || _codeInvalid || _refreshing) return;
    _pollTimer = Timer(delay, () => unawaited(_refresh()));
  }

  Future<void> _refresh() async {
    if (!_active ||
        !_hasLookupCode ||
        _refreshing ||
        !_canRefresh ||
        _codeInvalid) {
      return;
    }
    final version = ++_requestVersion;
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    setState(() {
      _refreshing = true;
      _canRefresh = false;
    });
    var cooldown = const Duration(seconds: 35);
    var nextPoll = const Duration(minutes: 1);
    try {
      final updated = await _repo.lookupByCode(result.code!);
      if (!mounted || version != _requestVersion) return;
      setState(() {
        result = updated;
        _refreshNotice = null;
      });
    } on ConsultaRateLimitException catch (error) {
      if (!mounted || version != _requestVersion) return;
      cooldown = nextPoll = const Duration(minutes: 5);
      setState(
        () => _refreshNotice =
            '$error Se muestra la última información consultada.',
      );
    } on PostgrestException catch (error) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _codeInvalid =
            error.message.contains('not_found') || error.code == 'P0001';
        _refreshNotice = _codeInvalid
            ? 'El código no existe o ya venció. Regresa para consultar otro código.'
            : 'No pudimos actualizar el estado. Se muestra la última información consultada.';
      });
    } catch (_) {
      if (!mounted || version != _requestVersion) return;
      setState(
        () => _refreshNotice =
            'No pudimos actualizar el estado. Se muestra la última información consultada. Verifica tu conexión e inténtalo de nuevo.',
      );
    } finally {
      if (mounted && version == _requestVersion) {
        setState(() => _refreshing = false);
        if (!_codeInvalid) {
          _cooldownTimer = Timer(cooldown, () {
            if (!mounted) return;
            setState(() => _canRefresh = true);
            if (!(_pollTimer?.isActive ?? false)) {
              _schedulePoll(Duration.zero);
            }
          });
          _schedulePoll(nextPoll);
        }
      }
    }
  }

  @override
  void dispose() {
    _requestVersion++;
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppResponsive.isCompactWidth(context)
        ? 16.0
        : 20.0;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SizedBox.expand(
          child: ColoredBox(
            color: const Color(0xFFF1F5F9),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(context),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      18,
                      horizontalPadding,
                      30 + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_refreshNotice != null) ...[
                              Semantics(
                                liveRegion: true,
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _codeInvalid
                                        ? const Color(0xFFFDECEC)
                                        : const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    _refreshNotice!,
                                    style:
                                        AppTextStyles
                                            .ESC_Regular_bodyMedium.copyWith(
                                          fontSize: 14,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (_codeInvalid)
                              OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Consultar otro código'),
                              ),
                            if (!_codeInvalid) ...[
                              _buildProgressBar(),
                              const SizedBox(height: 14),
                              _buildStatusCard(),
                              const SizedBox(height: 14),
                              _buildHospitalCard(context),
                              if (result.statusChangedAt != null) ...[
                                const SizedBox(height: 14),
                                ConsultaStatusUpdatedAt(
                                  timestamp: result.statusChangedAt!,
                                ),
                              ],
                            ],
                            const SizedBox(height: 14),
                            _buildPrivacyNotice(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final code = result.code?.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 6, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE6EBF1))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Regresar',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF121924),
              size: 22,
            ),
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado del paciente',
                  style: AppTextStyles.ESC_SemiBold_titleMedium.copyWith(
                    fontSize: 18,
                    height: 1.33,
                    color: const Color(0xFF121924),
                  ),
                ),
                Text(
                  code != null && code.isNotEmpty
                      ? 'Código $code'
                      : 'Consulta externa',
                  style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                    fontSize: 13,
                    height: 1.46,
                    color: const Color(0xFF4A5667),
                  ),
                ),
              ],
            ),
          ),
          if (_hasLookupCode && !_codeInvalid)
            IconButton(
              tooltip: _canRefresh
                  ? 'Actualizar estado'
                  : 'Espera antes de volver a actualizar',
              onPressed: _refreshing || !_canRefresh
                  ? null
                  : () => unawaited(_refresh()),
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: _refreshing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, color: Color(0xFF0A7EA4)),
            ),
        ],
      ),
    );
  }

  Color get _accentColor => result.status == ConsultaStatus.trasladando
      ? const Color(0xFF0A7EA4)
      : result.status.color;

  Widget _buildProgressBar() {
    const steps = [
      'Registro',
      'En espera',
      'Trasladando',
      'Recibido',
      'Alta médica',
    ];
    // Registro es una etapa visual completada, no otro estado del paciente.
    final activeIndex = result.status.index + 1;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.isCompactWidth(context) ? 12 : 18,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EBF1), width: 1.25),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length, (index) {
          final isActive = index == activeIndex;
          final isReached = index <= activeIndex;
          return Expanded(
            child: Semantics(
              selected: isActive,
              child: Column(
                children: [
                  SizedBox(
                    height: 22,
                    child: Center(
                      child: Container(
                        width: isReached ? 22 : 18,
                        height: isReached ? 22 : 18,
                        decoration: BoxDecoration(
                          color: isReached
                              ? _accentColor
                              : const Color(0xFFD4DCE5),
                          shape: BoxShape.circle,
                        ),
                        child: isReached
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    steps[index],
                    textAlign: TextAlign.center,
                    style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                      fontSize: 10,
                      height: 1.4,
                      color: isReached
                          ? const Color(0xFF121924)
                          : const Color(0xFF8695A8),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: result.status == ConsultaStatus.trasladando
            ? const Color(0xFFE4F4F9)
            : result.status.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: result.status == ConsultaStatus.trasladando
                  ? _accentColor
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: result.status == ConsultaStatus.trasladando
                ? SvgPicture.asset(
                    AppIcons.consultaAmbulance,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  )
                : FittedBox(child: result.status.iconWidget),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.status.title,
                  style: AppTextStyles.ESC_SemiBold_titleMedium.copyWith(
                    fontSize: 18,
                    height: 1.33,
                    color: const Color(0xFF121924),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  result.status.subtitle,
                  style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                    fontSize: 13,
                    height: 1.46,
                    color: const Color(0xFF4A5667),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalCard(BuildContext context) {
    final address = result.hospitalAddress ?? '';
    final phone = result.hospitalPhone ?? '';
    final hospitalColor = Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EBF1), width: 1.25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            result.status == ConsultaStatus.trasladando
                ? 'HOSPITAL DESTINO'
                : 'HOSPITAL ASIGNADO',
            style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
              fontSize: 11,
              height: 1.27,
              letterSpacing: 0.4,
              color: const Color(0xFF8695A8),
            ),
          ),
          const SizedBox(height: 14),
          if (!result.hasHospitalAssignment ||
              result.status == ConsultaStatus.enEspera)
            _buildUnassignedHospital()
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SvgPicture.asset(
                    AppIcons.consultaHospital,
                    colorFilter: ColorFilter.mode(
                      hospitalColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.hospitalName ?? 'Hospital asignado',
                        style: AppTextStyles.ESC_SemiBold_titleMedium.copyWith(
                          fontSize: 16,
                          height: 1.375,
                          color: const Color(0xFF121924),
                        ),
                      ),
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          address,
                          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                            fontSize: 13,
                            height: 1.46,
                            color: const Color(0xFF4A5667),
                          ),
                        ),
                      ],
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: hospitalColor,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                phone,
                                semanticsLabel: 'Número de contacto: $phone',
                                style:
                                    AppTextStyles
                                        .ESC_SemiBold_bodyMedium.copyWith(
                                      fontSize: 13,
                                      height: 1.38,
                                      color: hospitalColor,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F4F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20, color: Color(0xFF0A7EA4)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Esta consulta es limitada',
                  style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                    fontSize: 13,
                    height: 1.38,
                    color: const Color(0xFF0A7EA4),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Solo verás la información correspondiente a tu código. No se muestran datos clínicos sensibles.',
                  style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                    fontSize: 13,
                    height: 1.46,
                    color: const Color(0xFF4A5667),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnassignedHospital() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.domain_disabled_outlined,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aún no asignado',
                style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                  fontSize: 16,
                  color: const Color(0xFF7B7B7B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'El personal de emergencias está evaluando la situación para asignar el hospital destino.',
                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF7B7B7B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
