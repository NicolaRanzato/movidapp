
class Signal {
  final int id;
  final int placeId;
  final int affluenceId;
  final String user;
  final DateTime timestamp;

  Signal({
    required this.id,
    required this.placeId,
    required this.affluenceId,
    required this.user,
    required this.timestamp,
  });

  factory Signal.fromJson(Map<String, dynamic> json) {
    return Signal(
      id: json['id'],
      placeId: json['place_id'],
      affluenceId: json['affluence_id'],
      user: json['user'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'place_id': placeId,
      'affluence_id': affluenceId,
      'user': user,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
