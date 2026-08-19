import 'package:flutter/material.dart';

// Contenedor modular genérico para botones de envío de formulario
class FormActions extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onCreate;

  const FormActions({
    super.key,
    required this.onCancel,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
