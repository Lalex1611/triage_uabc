import 'package:flutter/foundation.dart';

@immutable
class MedicoDetailsAppBarData {
  final VoidCallback onBackTap;
  final String backLabel;

  const MedicoDetailsAppBarData({
    required this.onBackTap,
    this.backLabel = 'Regresar al inicio',
  });
}
