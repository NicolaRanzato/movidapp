
class SignalReview {
  final int id;
  final int signalId;
  final int rating;
  final DateTime timestamp;

  SignalReview({
    required this.id,
    required this.signalId,
    required this.rating,
    required this.timestamp,
  });

  factory SignalReview.fromJson(Map<String, dynamic> json) {
    return SignalReview(
      id: json['id'],
      signalId: json['signal_id'],
      rating: json['rating'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'signal_id': signalId,
      'rating': rating,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
