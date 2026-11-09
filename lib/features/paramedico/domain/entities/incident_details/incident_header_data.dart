class IncidentHeaderData {
  final String id;
  final String title;
  final String gpsCoordinates;

  /// Quién lo registró y cuándo ("Carlos Vera · hace 18 minutos · 14:32")
  final String authorLine;
  final bool isClosed;
  final int redCount;
  final int yellowCount;
  final int greenCount;
  final int blackCount;
  final int totalPatients;

  const IncidentHeaderData({
    required this.id,
    required this.title,
    required this.gpsCoordinates,
    required this.authorLine,
    required this.redCount,
    required this.yellowCount,
    required this.greenCount,
    required this.blackCount,
    required this.totalPatients,
    this.isClosed = false,
  });
}
