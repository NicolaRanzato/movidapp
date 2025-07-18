
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ActivePlace {
  final int placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int affluenceId;
  final String affluenceDescription;

  ActivePlace({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.affluenceId,
    required this.affluenceDescription,
  });

  factory ActivePlace.fromJson(Map<String, dynamic> json) {
    return ActivePlace(
      placeId: json['place_id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      affluenceId: json['affluence_id'],
      affluenceDescription: json['affluence_description'],
    );
  }

  LatLng get latLng => LatLng(latitude, longitude);
}
