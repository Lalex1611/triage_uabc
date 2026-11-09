import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/session/auth_gate.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/auth/domain/constants/auth_role_type.dart';
import 'package:sistema_triage/features/auth/domain/user_role.dart';
import 'package:sistema_triage/features/auth/presentation/login/widgets/auth_text_field.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthRoleType _currentRole = AuthRoleType.none;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  bool _hasCredentialError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!SupabaseEnv.isConfigured) {
      showAppSnackBar(
        context,
        'Supabase no está configurado. '
        'Hay algún error en la config de la base de datos',
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _hasCredentialError = true);
      showAppSnackBar(context, 'Ingresa correo y contraseña.');
      return;
    }

    setState(() {
      _busy = true;
      _hasCredentialError = false;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await AuthGate.instance.syncFromSession();

      if (!mounted) return;

      if (AuthGate.instance.takeConsultaExternaStaffBlock()) {
        if (!mounted) return;
        showAppSnackBar(
          context,
          'Tu cuenta no tiene un rol de la salud asignado. Si eres paramédico o médico, '
          'pide a un administrador que lo active. Para consultar el estado de un '
          'paciente, toca «Consultar a un paciente» abajo e ingresa el código.',
          isError: true,
        );
        return;
      }

      final AppUserRole? role = AuthGate.instance.role;

      if (role == null) {
        await AuthGate.instance.signOut();
        if (!mounted) return;
        showAppSnackBar(
          context,
          'No se encontró el perfil de usuario en la base de datos.',
          isError: true,
        );
        return;
      }

      if (!mounted) return;
      context.go(role.homePath);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _hasCredentialError = true);
      showAppSnackBar(context, e.message, isError: true);
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
      backgroundColor: TriageColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            context.horizontalPadding,
            TriageSpacing.xxl,
            context.horizontalPadding,
            TriageSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: TriageSpacing.xxl,
                      bottom: TriageSpacing.xxl,
                    ),
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.5,
                        child: SvgPicture.asset(
                          _currentRole.logoAsset,
                          semanticsLabel: 'Sistema TRIAGE',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Inicia tu turno',
                    style: TriageTextStyles.screenTitle.copyWith(
                      color: TriageColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: TriageSpacing.lg),
                  Text(
                    'El sistema reconoce tu rol al entrar. No necesitas elegirlo.',
                    style: TriageTextStyles.bodyMedium.copyWith(
                      color: TriageColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: TriageSpacing.xxl),
                  AuthTextField(
                    label: 'Correo institucional',
                    hint: 'nombre@cruzroja.org.mx',
                    roleType: _currentRole,
                    controller: _emailController,
                    hasError: _hasCredentialError,
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: TriageSpacing.xl),
                  AuthTextField(
                    label: 'Contraseña',
                    hint: 'Escribe tu contraseña',
                    roleType: _currentRole,
                    isPassword: true,
                    controller: _passwordController,
                    hasError: _hasCredentialError,
                    onChanged: (_) {},
                    onForgotPassword: () {},
                  ),
                  const SizedBox(height: TriageSpacing.sm),
                  TriageButton(
                    label: 'Entrar',
                    isLoading: _busy,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: TriageSpacing.xl),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: TriageColors.sunken,
                      borderRadius: BorderRadius.circular(TriageRadii.xxl),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(TriageSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const TriageIcon(
                                TriageIcons.qr,
                                color: TriageColors.textSecondary,
                              ),
                              const SizedBox(width: TriageSpacing.md),
                              Expanded(
                                child: Text(
                                  '¿Buscas a un familiar? Consulta su estado con '
                                  'el código que te dieron, sin crear cuenta.',
                                  style: TriageTextStyles.bodySmall.copyWith(
                                    color: TriageColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: TriageSpacing.md),
                          TriageButton(
                            label: 'Consultar a un paciente',
                            variant: TriageButtonVariant.secondary,
                            size: TriageButtonSize.medium,
                            onPressed: () => context.go('/consulta-externa'),
                          ),
                        ],
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
}
