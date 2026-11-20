import 'package:flutter/foundation.dart';

@immutable
class MedicoQueueRoleTitleData {
  final String roleLabel;
  final String userName;
  final int currentPatientCount;

  const MedicoQueueRoleTitleData({
    required this.roleLabel,
    required this.userName,
    required this.currentPatientCount,
  });
}
