
class Affluence {
  final int id;
  final String description;

  Affluence({
    required this.id,
    required this.description,
  });

  factory Affluence.fromJson(Map<String, dynamic> json) {
    return Affluence(
      id: json['id'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
    };
  }
}
