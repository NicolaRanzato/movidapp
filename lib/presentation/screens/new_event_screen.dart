import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NewEventScreen extends StatelessWidget {
  final LatLng coordinates;

  const NewEventScreen({super.key, required this.coordinates});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Event'),
      ),
      body: Center(
        child: Text(
          'Coordinates: ${coordinates.latitude}, ${coordinates.longitude}',
        ),
      ),
    );
  }
}
