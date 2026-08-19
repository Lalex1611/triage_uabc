class IncidentForCards {
  final String id, name_card;
  final DateTime dateTime;
  final double latitude, longitude;
  final int red, yellow, green, black, totalVictims;
  final bool isMine;

  IncidentForCards({
    required this.id,
    required this.name_card,
    required this.dateTime,
    required this.latitude,
    required this.longitude,
    required this.red,
    required this.yellow,
    required this.green,
    required this.black,
    required this.totalVictims,
    required this.isMine,
  });
}
