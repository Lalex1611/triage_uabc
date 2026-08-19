import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/presentation/home/widgets/app_search_bar_widget.dart';

/*
  COMANDO PARA PROBAR: 
  flutter run -t test/features/paramedico/presentation/home/widgets/app_search_bar_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AppSearchBarVisualTest(),
    ),
  );
}

class AppSearchBarVisualTest extends StatelessWidget {
  const AppSearchBarVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [AppSearchBar()],
          ),
        ),
      ),
    );
  }
}
