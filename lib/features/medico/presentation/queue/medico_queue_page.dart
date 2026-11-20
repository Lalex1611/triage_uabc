import 'package:flutter/material.dart';

class MedicoQueuePage extends StatelessWidget {
  final PreferredSizeWidget? appHeader;
  final List<Widget> fixedSection;
  final Widget scrollableSection;
  final Widget bottomNavbar;

  const MedicoQueuePage({
    super.key,
    required this.fixedSection,
    required this.scrollableSection,
    required this.bottomNavbar,
    this.appHeader,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appHeader,
      body: Column(
        children: [
          ...fixedSection,
          Expanded(child: scrollableSection),
        ],
      ),
      bottomNavigationBar: bottomNavbar,
    );
  }
}
