import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:custom_map_markers/custom_map_markers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:movidapp/data/models/active_place.dart';
import 'package:movidapp/data/models/event_type.dart';
import 'package:movidapp/data/models/place.dart';
import 'package:movidapp/presentation/screens/account_page.dart';
import 'package:movidapp/presentation/widgets/pulsating_dot_marker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapScreen extends StatefulWidget {
  final Position? initialPosition;
  const MapScreen({super.key, this.initialPosition});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Position? _currentPosition;
  List<MarkerData> _customMarkers = [];
  MapType _currentMapType = MapType.normal;

  // Search field focus
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
    if (_currentPosition != null) {
      _goToCurrentLocation();
      _refreshMapMarkers();
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _refreshMapMarkers() async {
    try {
      // Fetch active and all places in parallel
      final results = await Future.wait([
        Supabase.instance.client.rpc('get_active_map_places'),
        Supabase.instance.client.from('place').select(),
      ]);

      final activePlacesData = results[0] as List<dynamic>;
      final allPlacesData = results[1] as List<dynamic>;

      final activePlaces = activePlacesData.map((item) => ActivePlace.fromJson(item)).toList();
      final allPlaces = allPlacesData.map((item) => Place.fromJson(item)).toList();

      final Set<int> activePlaceIds = activePlaces.map((p) => p.placeId).toSet();
      final List<MarkerData> markers = [];

      // Create markers for active places (pulsating dots)
      for (final activePlace in activePlaces) {
        markers.add(
          MarkerData(
            marker: Marker(
              markerId: MarkerId('active_place_${activePlace.placeId}'),
              position: activePlace.latLng,
              onTap: () => _showSignalDetailsModal(activePlace),
            ),
            child: PulsatingDotMarker(color: _getMarkerColorForAffluence(activePlace.affluenceId)),
          ),
        );
      }

      // Create markers for inactive places (standard icons)
      for (final place in allPlaces) {
        if (!activePlaceIds.contains(place.id)) {
          markers.add(
            MarkerData(
              marker: Marker(
                markerId: MarkerId('place_${place.id}'),
                position: LatLng(place.latitude, place.longitude),
                onTap: () => _showPlaceDetailsModal(place),
              ),
              child: const Icon(Icons.location_pin, color: Colors.grey, size: 40),
            ),
          );
        }
      }

      setState(() {
        _customMarkers = markers;
      });
    } catch (e) {
      _showInfo('Error refreshing map markers: $e');
    }
  }

  Color _getMarkerColorForAffluence(int affluenceId) {
    switch (affluenceId) {
      case 1: // low
        return Colors.yellow;
      case 2: // medium
        return Colors.orange;
      case 3: // high
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Future<void> _goToCurrentLocation() async {
    if (_currentPosition == null) return;
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 14.5,
      ),
    ));
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      _showInfo('Please enter a location to search.');
      return;
    }

    try {
      List<Location> locations = await geocoding.locationFromAddress(query);

      if (locations.isNotEmpty) {
        Location firstLocation = locations.first;
        final GoogleMapController controller = await _controller.future;
        controller.moveCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(firstLocation.latitude, firstLocation.longitude),
            zoom: 14.5,
          ),
        ));
        _showInfo('Map moved to ${firstLocation.latitude}, ${firstLocation.longitude}');
      } else {
        _showInfo('No coordinates found for the given address.');
      }
    } catch (e) {
      _showInfo('Error geocoding address: $e');
    }
  }

  Future<void> _onMapLongPress(LatLng latLng) async {
    try {
      // 1. Reverse Geocoding
      final placemarks = await geocoding.placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      final address = placemarks.isNotEmpty ? placemarks.first.street : 'Unknown address';

      // 2. Fetch Event Types from Supabase
      final response = await Supabase.instance.client.from('event_type').select();
      final eventTypes = (response as List).map((e) => EventType.fromJson(e)).toList();

      // 3. Show Modal
      _showCreatePlaceModal(latLng, address ?? "Unknown address", eventTypes);

    } catch (e) {
      _showInfo('Error during reverse geocoding: $e');
    }
  }

  void _showSignalDetailsModal(ActivePlace activePlace) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(activePlace.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Current Affluence: ', style: TextStyle(fontSize: 16)),
                  Text(
                    activePlace.affluenceDescription,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getMarkerColorForAffluence(activePlace.affluenceId),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Last report at: ${activePlace.timestamp}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showPlaceDetailsModal(Place place) {
    double affluence = 1; // Default to low

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(place.address, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 24),
                    const Text('Report Affluence', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    Slider(
                      value: affluence,
                      min: 1,
                      max: 3,
                      divisions: 2,
                      label: affluence == 1 ? 'Low' : affluence == 2 ? 'Medium' : 'High',
                      onChanged: (value) {
                        setModalState(() {
                          affluence = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        child: const Text('Submit Report'),
                        onPressed: () async {
                          try {
                            final user = Supabase.instance.client.auth.currentUser;
                            if (user == null) {
                              _showInfo('You must be logged in to report.');
                              return;
                            }

                            await Supabase.instance.client.from('signal').insert({
                              'place_id': place.id,
                              'affluence_id': affluence.round(),
                              'user': user.id, // Using user.id as per schema
                            });

                            Navigator.pop(context); // Close modal
                            _showInfo('Report submitted successfully!');
                            _refreshMapMarkers(); // Refresh map to show the new active place

                          } catch (e) {
                            Navigator.pop(context);
                            _showInfo('Error submitting report: $e');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreatePlaceModal(LatLng latLng, String address, List<EventType> eventTypes) {
    final nameController = TextEditingController();
    EventType? selectedEventType = eventTypes.isNotEmpty ? eventTypes.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create New Place', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Place Name'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<EventType>(
                      value: selectedEventType,
                      items: eventTypes.map((type) {
                        return DropdownMenuItem<EventType>(
                          value: type,
                          child: Text(type.description),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedEventType = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        child: const Text('Create Place'),
                        onPressed: () async {
                          if (nameController.text.isEmpty || selectedEventType == null) {
                            _showInfo('Please fill all fields.');
                            return;
                          }
                          
                          try {
                            // Insert into place table
                            await Supabase.instance.client.from('place').insert({
                              'name': nameController.text,
                              'address': address,
                              'latitude': latLng.latitude,
                              'longitude': latLng.longitude,
                              'event_type_id': selectedEventType!.id,
                            });

                            Navigator.pop(context); // Close modal
                            _showInfo('Place created successfully!');
                            // We should refresh all places here, not just active ones
                            // This will be implemented in the next step.
                            _refreshMapMarkers(); // Placeholder refresh

                          } catch (e) {
                            Navigator.pop(context);
                            _showInfo('Error creating place: $e');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showMenu(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountPage()));
            },
            child: const Text('Account'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Settings'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CustomGoogleMapMarkerBuilder(
                  customMarkers: _customMarkers,
                  builder: (BuildContext context, Set<Marker>? markers) {
                    return GoogleMap(
                      mapType: _currentMapType,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        zoom: 14.5,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                      },
                      onLongPress: _onMapLongPress,
                      markers: markers ?? {},
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                    );
                  },
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoSearchTextField(
                            focusNode: _searchFocusNode,
                            placeholder: 'Search',
                            backgroundColor: CupertinoColors.systemGrey5.withOpacity(1.0),
                            onTap: () {
                              _searchFocusNode.requestFocus();
                            },
                            onSubmitted: (value) {
                              _searchFocusNode.unfocus();
                              _searchLocation(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _showMenu(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.ellipsis,
                              color: CupertinoColors.black,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoButton.filled(
              onPressed: _goToCurrentLocation,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(CupertinoIcons.location_solid),
                  SizedBox(width: 8.0),
                  Text('My Location'),
                ],
              ),
            ),
            const SizedBox(width: 10),
            CupertinoButton.filled(
              onPressed: _toggleMapType,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(_currentMapType == MapType.normal ? CupertinoIcons.globe : CupertinoIcons.map),
                  SizedBox(width: 8.0),
                  Text(_currentMapType == MapType.normal ? 'Satellite' : 'Normal'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
