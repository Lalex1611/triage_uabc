import 'package:flutter/material.dart';

// Cascarón Mudo (Dumb Shell) para Start Triage
class StartTriagePage extends StatelessWidget {
  final List<Widget> children;

  const StartTriagePage({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          // Eliminamos el padding aquí porque cada widget interno puede manejar sus propios márgenes
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
