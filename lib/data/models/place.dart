
class Place {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int eventTypeId;
  final String? photoUrl;
  final List<String> types; // Added to store place types

  Place({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.eventTypeId,
    this.photoUrl,
    this.types = const [], // Default to an empty list
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      eventTypeId: json['event_type_id'],
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'event_type_id': eventTypeId,
      'photo_url': photoUrl,
    };
  }
}
