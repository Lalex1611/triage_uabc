import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/session/auth_gate.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/auth/domain/constants/auth_role_type.dart';
import 'package:sistema_triage/features/auth/domain/user_role.dart';
import 'package:sistema_triage/features/auth/presentation/login/widgets/auth_text_field.dart';
import 'package:sistema_triage/features/auth/presentation/login/widgets/auth_action_button.dart';
import 'package:sistema_triage/features/auth/presentation/login/widgets/auth_consult_button.dart';
import 'package:sistema_triage/features/auth/presentation/login/widgets/auth_partner_logos_footer.dart';
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
      showAppSnackBar(context, 'Ingresa correo y contraseña.');
      return;
    }

    setState(() => _busy = true);

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
          'Tu cuenta aún no tiene un rol asignado. Si eres paramédico o médico, '
          'pide a un administrador que lo active. Para consultar el estado de un '
          'paciente, toca «Consultar estado» abajo e ingresa el código.',
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 130),
                SvgPicture.asset(
                  _currentRole.logoAsset,
                  height: 224,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 70),
                const SizedBox(height: 35),
                SizedBox(
                  width: 270,
                  child: Column(
                    children: [
                      AuthTextField(
                        label: 'Correo electrónico',
                        hint: 'usuario@ejemplo.com',
                        roleType: _currentRole,
                        controller: _emailController,
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 20),
                      AuthTextField(
                        label: 'Contraseña',
                        hint: '#@8mds!...',
                        roleType: _currentRole,
                        isPassword: true,
                        controller: _passwordController,
                        onChanged: (_) {},
                        onForgotPassword: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 27),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  AuthActionButton(roleType: _currentRole, onTap: _submit),
                const SizedBox(height: 47),
                Text(
                  '¿Eres paciente o quieres saber el estado de tu familiar?',
                  style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                    fontSize: 10,
                    color: const Color(0xFF999A9D),
                  ),
                ),
                const SizedBox(height: 4),
                AuthConsultButton(onTap: () => context.go('/consulta-externa')),
                const SizedBox(height: 28),
                const AuthPartnerLogosFooter(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
