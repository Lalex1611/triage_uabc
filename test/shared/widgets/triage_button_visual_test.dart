// Sandbox visual de TriageButton: flutter run -t test/shared/widgets/triage_button_visual_test.dart
import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_button_widget.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: TriageColors.canvas,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final variant in TriageButtonVariant.values) ...[
                Text(variant.name, style: TriageTextStyles.labelSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TriageButton(
                      label: 'Acción',
                      variant: variant,
                      onPressed: () {},
                    ),
                    TriageButton(
                      label: 'Acción',
                      variant: variant,
                      size: TriageButtonSize.medium,
                      onPressed: () {},
                    ),
                    TriageButton(
                      label: 'Deshabilitado',
                      variant: variant,
                      onPressed: null,
                    ),
                    TriageButton(
                      label: 'Cargando',
                      variant: variant,
                      isLoading: true,
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              Text('Ancho completo', style: TriageTextStyles.labelSmall),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TriageButton(
                  label: 'Registrar paciente',
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
