import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/shared/widgets/app_header.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';

/*
  COMANDO PARA PROBAR: 
  flutter run -t test/shared/widgets/app_header_visual_test.dart
*/
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AppHeaderVisualTest(),
    ),
  );
}

class AppHeaderVisualTest extends StatefulWidget {
  const AppHeaderVisualTest({super.key});

  @override
  State<AppHeaderVisualTest> createState() => _AppHeaderVisualTestState();
}

class _AppHeaderVisualTestState extends State<AppHeaderVisualTest> {
  HeaderType _type = HeaderType.home;
  bool _isConnected = true;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        appBar: AppHeader(
          type: _type,
          color: AppColors.triagePre_rojo,
          isConnected: _isConnected,
          hasNotifications: true,
          subtitle: 'Cruz Roja - Delegación Tijuana',
          backLabel: 'Regresar a la lista',
          actionLabel: 'INICIAR',
          onBack: () => print('Back pressed'),
          onAction: () => print('Action pressed'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'PROBADOR DE HEADERS',
                style: AppTextStyles.ESC_Bold_displaySmall,
              ),
              const SizedBox(height: 20),
              DropdownButton<HeaderType>(
                value: _type,
                items: HeaderType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              SwitchListTile(
                title: const Text('Conexión WiFi'),
                value: _isConnected,
                onChanged: (v) => setState(() => _isConnected = v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
