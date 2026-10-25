// Catálogo visual de TriageIcons: flutter run -t test/shared/widgets/triage_icon_visual_test.dart
import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: TriageColors.canvas,
        body: SafeArea(
          child: GridView.extent(
            maxCrossAxisExtent: 96,
            padding: const EdgeInsets.all(16),
            children: [
              for (final asset in TriageIcons.all)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TriageIcon(asset),
                    const SizedBox(height: 6),
                    Text(
                      asset.split('/').last.replaceAll('.svg', ''),
                      style: TriageTextStyles.labelSmall.copyWith(
                        color: TriageColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
