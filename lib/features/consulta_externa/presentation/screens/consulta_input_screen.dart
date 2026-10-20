import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/session/auth_gate.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/auth/domain/user_role.dart';
import 'package:sistema_triage/features/consulta_externa/data/repositories/consulta_repository.dart';
import 'package:sistema_triage/features/consulta_externa/domain/consulta_code.dart';
import 'package:sistema_triage/features/consulta_externa/presentation/screens/consulta_qr_screen.dart';
import 'package:sistema_triage/features/consulta_externa/presentation/widgets/consulta_code_input.dart';
import 'package:sistema_triage/features/consulta_externa/presentation/widgets/consulta_info_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsultaInputScreen extends StatefulWidget {
  final ConsultaRepository? repository;

  const ConsultaInputScreen({super.key, this.repository});

  @override
  State<ConsultaInputScreen> createState() => _ConsultaInputScreenState();
}

class _ConsultaInputScreenState extends State<ConsultaInputScreen> {
  final _controller = TextEditingController();
  late final ConsultaRepository _repo;
  bool _busy = false;
  bool _codeInvalid = false;
  bool _scannerOpen = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ConsultaRepository();
  }

  /// Incluye code/details de PostgREST para diagnosticar fallos de API
  String _postgrestDebugMessage(PostgrestException e) {
    final buf = StringBuffer(e.message);
    if (e.code != null && e.code!.isNotEmpty) {
      buf.write(' [code=${e.code}]');
    }
    if (e.details != null) {
      buf.write(' ${e.details}');
    }
    return buf.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _consultar() async {
    if (_busy) return;
    if (!SupabaseEnv.isConfigured) {
      showAppSnackBar(
        context,
        'Supabase no está configurado. Define SUPABASE_URL y SUPABASE_ANON_KEY.',
      );
      return;
    }

    final code = ConsultaCode.normalize(_controller.text);
    if (!ConsultaCode.isValid(code)) {
      showAppSnackBar(context, 'Ingresa el código completo.');
      return;
    }

    setState(() {
      _busy = true;
      _codeInvalid = false;
    });

    try {
      final result = await _repo.lookupByCode(code);
      if (!mounted) return;
      context.push('/consulta-status', extra: result);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      if (e.message.contains('not_found') || e.code == 'P0001') {
        setState(() => _codeInvalid = true);
      } else {
        showAppSnackBar(context, _postgrestDebugMessage(e), isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, '$e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openScanner() async {
    if (_busy || _scannerOpen) return;
    FocusScope.of(context).unfocus();
    setState(() => _scannerOpen = true);
    try {
      final code = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const ConsultaQrScreen()),
      );
      if (!mounted || code == null) return;
      _controller.value = TextEditingValue(
        text: code,
        selection: TextSelection.collapsed(offset: code.length),
      );
      await _consultar();
    } finally {
      if (mounted) setState(() => _scannerOpen = false);
    }
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
        child: ColoredBox(
          color: const Color(0xFFF1F5F9),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        _buildHeader(context),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            22,
                            horizontalPadding,
                            0,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: _buildInputCard(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        32,
                        horizontalPadding,
                        30 + MediaQuery.paddingOf(context).bottom,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: const ConsultaInfoCard(outlined: true),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              final session = Supabase.instance.client.auth.currentSession;
              final role = AuthGate.instance.role;
              if (session != null &&
                  role != null &&
                  role != AppUserRole.consultaExterna) {
                context.go(role.homePath);
                return;
              }
              context.go('/auth');
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF121924),
              size: 22,
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consulta de paciente',
                  style: AppTextStyles.ESC_SemiBold_titleMedium.copyWith(
                    fontSize: 18,
                    height: 1.33,
                    color: const Color(0xFF121924),
                  ),
                ),
                Text(
                  'Sin iniciar sesión',
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

  Widget _buildInputCard(BuildContext context) {
    final actionStyle = AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
      fontSize: 15,
      height: 1.33,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_codeInvalid)
          _buildInvalidCodeNotice()
        else ...[
          Text(
            'Escribe el código de consulta',
            style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
              fontSize: 22,
              height: 1.27,
              color: const Color(0xFF121924),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Son 6 caracteres en mayúsculas. Te lo entregó el paramédico o el hospital.',
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              fontSize: 15,
              height: 1.47,
              color: const Color(0xFF4A5667),
            ),
          ),
        ],
        SizedBox(height: _codeInvalid ? 18 : 20),
        ConsultaCodeInput(
          controller: _controller,
          hasError: _codeInvalid,
          onRejectedInput: () => showAppSnackBar(
            context,
            'Usa seis letras o números. El contenido no se recorta.',
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: _busy ? null : _consultar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            textStyle: actionStyle,
          ),
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_codeInvalid ? 'Intentar de nuevo' : 'Consultar estado'),
        ),
        const SizedBox(height: 18),
        if (!_codeInvalid) ...[
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFD4DCE5))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'o',
                  style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF8695A8),
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFD4DCE5))),
            ],
          ),
          const SizedBox(height: 18),
        ],
        OutlinedButton(
          onPressed: _busy || _scannerOpen ? null : _openScanner,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF121924),
            minimumSize: const Size.fromHeight(54),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            side: const BorderSide(color: Color(0xFFD4DCE5), width: 1.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: actionStyle,
          ),
          child: const Text('Escanear código QR'),
        ),
      ],
    );
  }

  Widget _buildInvalidCodeNotice() {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.cancel_outlined,
              size: 20,
              color: Color(0xFFC30508),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'El código no existe o ya venció',
                    style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                      fontSize: 13,
                      height: 1.38,
                      color: const Color(0xFFC30508),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Revisa que esté escrito igual, con mayúsculas. Si sigue sin funcionar, pídelo de nuevo en el hospital.',
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
      ),
    );
  }
}
