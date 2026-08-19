import 'package:flutter/material.dart';

class MedicoRegisterPatientPage extends StatelessWidget {
  final PreferredSizeWidget appBar;
  final List<Widget> bodyChildren;
  final Widget bottomActions;

  const MedicoRegisterPatientPage({
    super.key,
    required this.appBar,
    required this.bodyChildren,
    required this.bottomActions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: bodyChildren,
          ),
        ),
      ),
      bottomNavigationBar: bottomActions,
    );
  }
}
