import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/session/auth_gate.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/auth/domain/user_role.dart';
import 'package:sistema_triage/features/consulta_externa/data/repositories/consulta_repository.dart';
import 'package:sistema_triage/features/consulta_externa/presentation/widgets/consulta_info_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsultaInputScreen extends StatefulWidget {
  const ConsultaInputScreen({super.key});

  @override
  State<ConsultaInputScreen> createState() => _ConsultaInputScreenState();
}

class _ConsultaInputScreenState extends State<ConsultaInputScreen> {
  final _controller = TextEditingController();
  final _repo = ConsultaRepository();
  bool _busy = false;

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
    if (!SupabaseEnv.isConfigured) {
      showAppSnackBar(
        context,
        'Supabase no está configurado. Define SUPABASE_URL y SUPABASE_ANON_KEY.',
      );
      return;
    }

    final code = _controller.text.trim().toUpperCase();
    if (code.replaceAll(RegExp(r'\s+'), '').length < 4) {
      showAppSnackBar(context, 'Ingresa el código completo.');
      return;
    }

    setState(() => _busy = true);

    try {
      final result = await _repo.lookupByCode(code);
      if (!mounted) return;
      context.push('/consulta-status', extra: result);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      final msg = e.message.contains('not_found') || e.code == 'P0001'
          ? 'Código no válido o expirado.'
          : _postgrestDebugMessage(e);
      showAppSnackBar(context, msg, isError: true);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, '$e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInputCard(context),
                    const SizedBox(height: 16),
                    const ConsultaInfoCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFCE1125),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(AppIcons.logoBase, height: 40),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sistema de emergencias',
                      style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Cruz Roja - Tijuana',
                      style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sistema de Consulta de Pacientes',
                      style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
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
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '¿Eres paciente o quieres saber el estado de tu familiar?',
            style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
              color: Colors.white,
              fontSize: 16,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ingresa el código que te proporcionó el personal de Cruz Roja o Hospitalario para consultar tu estado o el estado de tu familiar/allegado.',
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEAEA),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Código de consulta',
            style: AppTextStyles.ESC_Bold_titleSmall.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            'Alfanumérico (guiones permitidos). Escribe el código completo.',
            style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
              fontSize: 12,
              color: const Color(0xFF7B7B7B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD9D9D9),
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    textAlign: TextAlign.center,
                    maxLength: 64,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9\-]'),
                      ),
                    ],
                    style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                      fontSize: 24,
                      letterSpacing: 12,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      hintText: 'A B 3 K 7 X',
                      hintStyle: TextStyle(color: Color(0xFFCCCCCC)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD9D9D9), width: 2),
                ),
                child: IconButton(
                  onPressed: () {
                    showAppSnackBar(
                      context,
                      'Escaneo QR disponible en una futura versión.',
                    );
                  },
                  icon: SvgPicture.asset(AppIcons.consultaQr, width: 32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 220,
              height: 48,
              child: ElevatedButton(
                onPressed: _busy ? null : _consultar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDF7E8A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search, color: Colors.white),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Consultar estado',
                                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 12,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'del paciente',
                                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 12,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '¿Tienes un QR? Toca el ícono para escanearlo',
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                fontSize: 10,
                color: const Color(0xFF999A9D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
