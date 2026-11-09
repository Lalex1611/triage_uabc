import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Vista A03. El envío de enlaces queda pendiente de integración.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void returnToLogin() => Navigator.of(context).pop();

    return Scaffold(
      backgroundColor: TriageColors.surface,
      appBar: AppBar(
        backgroundColor: TriageColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: TriageSizes.touchTarget,
        leading: TriageIconButton(
          icon: TriageIcons.arrowLeft,
          tooltip: 'Regresar',
          variant: TriageIconButtonVariant.plain,
          onPressed: returnToLogin,
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            primary: false,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: context.horizontalPadding,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 560,
                  minHeight: viewport.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: TriageSpacing.lg),
                      Text(
                        'Recupera tu acceso',
                        style: TriageTextStyles.screenTitle.copyWith(
                          color: TriageColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: TriageSpacing.lg),
                      Text(
                        'Enviaremos un enlace al correo institucional con el '
                        'que te dieron de alta. Si no lo recuerdas, pídelo a '
                        'tu coordinador de turno.',
                        style: TriageTextStyles.bodyMedium.copyWith(
                          color: TriageColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: TriageSpacing.xxl),
                      const TriageField(
                        label: 'Correo institucional',
                        hint: 'nombre@cruzroja.org.mx',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: TriageSpacing.xl),
                      TriageButton(
                        label: 'Enviar enlace',
                        onPressed: () => showAppSnackBar(
                          context,
                          'La recuperación de contraseña aún no está disponible.',
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: TriageSpacing.xxl),
                      TriageButton(
                        label: 'Volver a iniciar sesión',
                        variant: TriageButtonVariant.subtle,
                        size: TriageButtonSize.medium,
                        onPressed: returnToLogin,
                      ),
                      const SizedBox(height: TriageSpacing.sm),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
