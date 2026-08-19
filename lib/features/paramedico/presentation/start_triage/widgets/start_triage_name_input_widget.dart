import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/start_triage_name_input_data.dart';

class StartTriageNameInputWidget extends StatefulWidget {
  final StartTriageNameInputData data;

  const StartTriageNameInputWidget({super.key, required this.data});

  @override
  State<StartTriageNameInputWidget> createState() =>
      _StartTriageNameInputWidgetState();
}

class _StartTriageNameInputWidgetState
    extends State<StartTriageNameInputWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.data.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.625, // 0.5 * 1.25
        child: TextField(
          controller: _controller,
          onChanged: widget.data.onChanged,
          maxLength: 30,
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            color: Colors.white,
            fontSize: 15, // 12 * 1.25
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.all(12.5), // 10 * 1.25
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: 'Nombre (opcional):',
            labelStyle: AppTextStyles.ESC_Light_bodyMedium.copyWith(
              color: const Color(0xFFB3B3B3),
              fontSize: 12.5, // 10 * 1.25
            ),
            hintText: 'Alberto Pérez...',
            hintStyle: AppTextStyles.ESC_Light_bodyMedium.copyWith(
              color: const Color(0xFF4A4A4A),
              fontSize: 12.5, // 10 * 1.25
            ),
            counterStyle: AppTextStyles.ESC_Light_bodyMedium.copyWith(
              color: const Color(0xFFB3B3B3),
              fontSize: 11.25, // 9 * 1.25
            ),
            filled: true,
            fillColor: Colors.transparent,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(
                color: Color(0xFF4A4A4A),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.white, width: 1.0),
            ),
          ),
        ),
      ),
    );
  }
}
