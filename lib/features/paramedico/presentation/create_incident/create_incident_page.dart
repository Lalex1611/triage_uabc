import 'package:flutter/material.dart';
import 'package:sistema_triage/shared/widgets/app_header.dart';

class CreateIncidentPage extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final List<Widget> children;
  final Widget? stickyActionBar;

  const CreateIncidentPage({
    super.key,
    this.appBar,
    this.children = const [],
    this.stickyActionBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar:
          appBar ??
          AppHeader(
            type: HeaderType.paramedicoFlow,
            color: const Color(0xFFCE1125),
            isConnected: true,
            hasNotifications: false,
            toolbarTitle: 'Nuevo incidente',
            onBack: () => Navigator.of(context).maybePop(),
          ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
          if (stickyActionBar != null)
            Align(alignment: Alignment.bottomCenter, child: stickyActionBar),
        ],
      ),
    );
  }
}
