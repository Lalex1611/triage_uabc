import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

// Área de texto de formato libre para captura de notas adicionales sobre la escena
class IncidentDescriptionSection extends StatelessWidget {
  final TextEditingController? controller;

  const IncidentDescriptionSection({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Descripción (opcional) :',
            style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
              fontSize: 15,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 139,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFD9D9D9),
              ), // Asumiendo gris estándar
            ),
            child: TextField(
              controller: controller,
              maxLines: null, // Permite infinitas líneas
              keyboardType:
                  TextInputType.multiline, // Activa el enter en el teclado
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                fontSize: 14,
                color: Colors.black,
              ),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
