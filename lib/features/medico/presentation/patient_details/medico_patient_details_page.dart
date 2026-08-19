import 'package:flutter/material.dart';

class MedicoPatientDetailsPage extends StatelessWidget {
  final PreferredSizeWidget appBar;
  final List<Widget> bodyChildren;
  final Widget? bottomActions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const MedicoPatientDetailsPage({
    super.key,
    required this.appBar,
    required this.bodyChildren,
    this.bottomActions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
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
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation:
          floatingActionButton != null
              ? (floatingActionButtonLocation ??
                  FloatingActionButtonLocation.endFloat)
              : null,
      bottomNavigationBar: bottomActions,
    );
  }
}
