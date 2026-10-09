import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/consulta_externa/domain/constants/consulta_status.dart';
import 'package:sistema_triage/features/consulta_externa/domain/consulta_lookup_result.dart';
import 'package:sistema_triage/features/consulta_externa/presentation/widgets/consulta_info_card.dart';

class ConsultaStatusScreen extends StatelessWidget {
  final ConsultaLookupResult result;

  const ConsultaStatusScreen({super.key, required this.result});

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
                    _buildProgressBar(result.status),
                    const SizedBox(height: 16),
                    _buildStatusCard(result),
                    const SizedBox(height: 16),
                    const ConsultaInfoCard(),
                    const SizedBox(height: 40),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
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

  Widget _buildProgressBar(ConsultaStatus status) {
    final steps = [
      'En espera',
      'Trasladando',
      'Recibido',
      'Alta médica',
    ];
    int currentIndex = 0;
    if (status == ConsultaStatus.enEspera) currentIndex = 0;
    if (status == ConsultaStatus.trasladando) currentIndex = 1;
    if (status == ConsultaStatus.recibido) currentIndex = 2;
    if (status == ConsultaStatus.alta) currentIndex = 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEAEA),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(steps.length * 2 - 1, (index) {
          if (index % 2 != 0) {
            return Icon(
              Icons.chevron_right,
              color: status.color,
              size: 12,
            ); // Flecha más pequeña
          }
          final stepIndex = index ~/ 2;
          final isActive = stepIndex == currentIndex;

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 4,
            ), // Menos padding para que quepan 5
            decoration: BoxDecoration(
              color: (() {
                Color tabColor = Colors.white;
                if (isActive) {
                  tabColor = status.color;
                }
                return tabColor;
              })(),
              borderRadius: BorderRadius.circular(12),
              border: (() {
                BoxBorder? tabBorder = Border.all(
                  color: const Color(0xFFD9D9D9),
                );
                if (isActive) {
                  tabBorder = null;
                }
                return tabBorder;
              })(),
            ),
            child: Text(
              steps[stepIndex],
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                fontSize: 8.5, // Texto más pequeño para acomodar las 5 píldoras
                color: isActive
                    ? (status == ConsultaStatus.enEspera
                          ? Colors.black
                          : Colors.white)
                    : const Color(0xFF999A9D),
              ),
            ),
          );
          }),
        ),
      ),
    );
  }

  Widget _buildStatusCard(ConsultaLookupResult result) {
    final status = result.status;
    return Container(
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
        children: [
          // Header parte colorida
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: status.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                status.iconWidget,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.title,
                        style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                          fontSize: 20,
                          color: status.color,
                        ),
                      ),
                      Text(
                        status.subtitle,
                        style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                          fontSize: 12,
                          color: const Color(0xFF7B7B7B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body parte info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hospital asignado',
                  style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Divider(color: status.color, thickness: 1), // Línea dinámica
                const SizedBox(height: 12),

                if (!result.hasHospitalAssignment ||
                    status == ConsultaStatus.enEspera)
                  _buildUnassignedHospital()
                else
                  _buildAssignedHospital(result),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedHospital(ConsultaLookupResult result) {
    final status = result.status;
    final name = result.hospitalName ?? 'Hospital asignado';
    final address = result.hospitalAddress ?? '';
    final phone = result.hospitalPhone ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD9D9D9)),
          ),
          child: SvgPicture.asset(
            AppIcons.consultaHospital,
            width: 50,
            colorFilter: ColorFilter.mode(
              status.color,
              BlendMode.srcIn,
            ), // SVG dinámico
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTextStyles.ESC_Bold_titleSmall.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              if (address.isNotEmpty)
                Text(
                  address,
                  style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF7B7B7B),
                  ),
                ),
              const SizedBox(height: 8),
              if (phone.isNotEmpty)
                Row(
                  children: [
                    Text(
                      'Número de contacto: ',
                      style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      phone,
                      style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                        fontSize: 12,
                        color: status.color,
                        decoration: TextDecoration.underline,
                        decorationColor: status.color,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnassignedHospital() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.domain_disabled_outlined,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aún no asignado',
                style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                  fontSize: 16,
                  color: const Color(0xFF7B7B7B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'El personal de emergencias está evaluando la situación para asignar el hospital destino.',
                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF7B7B7B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
