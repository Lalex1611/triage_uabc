import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';

enum ConsultaStatus {
  registrado,
  enEspera,
  trasladando,
  recibido,
  alta;

  String get title {
    switch (this) {
      case ConsultaStatus.registrado:
        return 'Paciente Registrado';
      case ConsultaStatus.enEspera:
        return 'Siendo atendido en escena';
      case ConsultaStatus.trasladando:
        return 'En camino al hospital';
      case ConsultaStatus.recibido:
        return 'Recibido en hospital';
      case ConsultaStatus.alta:
        return 'Alta médica';
    }
  }

  String get subtitle {
    switch (this) {
      case ConsultaStatus.registrado:
        return 'El paciente ha sido ingresado al sistema.';
      case ConsultaStatus.enEspera:
        return 'El personal de emergencias está evaluando al paciente.';
      case ConsultaStatus.trasladando:
        return 'Estado actualizándose en tiempo real.';
      case ConsultaStatus.recibido:
        return 'El paciente ha llegado y fue recibido por el hospital.';
      case ConsultaStatus.alta:
        return 'El paciente ha sido dado de alta exitosamente.';
    }
  }

  Color get color {
    switch (this) {
      case ConsultaStatus.registrado:
        return const Color(0xFFF39B27); // Naranja
      case ConsultaStatus.enEspera:
        return const Color(
          0xFFD4AC0D,
        ); // Amarillo más oscuro/ámbar para mejor legibilidad en blanco
      case ConsultaStatus.trasladando:
        return const Color(0xFF3B82F6); // Azul
      case ConsultaStatus.recibido:
        return const Color(0xFF00E676); // Verde fosforescente
      case ConsultaStatus.alta:
        return const Color(0xFF999A9D); // Gris
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ConsultaStatus.registrado:
        return const Color(0xFFFFF4E5);
      case ConsultaStatus.enEspera:
        return const Color(0xFFFFFDE7); // Amarillo muy claro
      case ConsultaStatus.trasladando:
        return const Color(0xFFEBF5FF); // Azul claro
      case ConsultaStatus.recibido:
        return const Color(0xFFE9F7EF); // Verde claro
      case ConsultaStatus.alta:
        return const Color(0xFFF5F5F5); // Gris claro
    }
  }

  Widget get iconWidget {
    switch (this) {
      case ConsultaStatus.registrado:
        return Icon(Icons.person_add_alt_1_outlined, color: color, size: 40);
      case ConsultaStatus.enEspera:
        return Icon(
          Icons.monitor_heart_outlined,
          color: const Color(0xFFF39B27),
          size: 40,
        ); // El ícono naranja contrasta mejor que el amarillo brillante en fondo blanco
      case ConsultaStatus.trasladando:
        return SvgPicture.asset(
          AppIcons.consultaAmbulance,
          width: 44,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );
      case ConsultaStatus.recibido:
        return Icon(Icons.check_circle_outline, color: color, size: 40);
      case ConsultaStatus.alta:
        return Icon(
          Icons.assignment_turned_in_outlined,
          color: color,
          size: 40,
        );
    }
  }
}
