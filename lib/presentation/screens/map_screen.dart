import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:movidapp/data/models/place.dart'; // Added import for Place model
import 'package:movidapp/presentation/screens/account_page.dart';

class MapScreen extends StatefulWidget {
  final Position? initialPosition;
  const MapScreen({super.key, this.initialPosition});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Position? _currentPosition;
  final Set<Marker> _markers = {};

  // --- API Key Management ---
  final String _placesApiKey = 'AIzaSyDCEdEbmfkTDnkx4OFocZw6CHIKO0L-6Lw';

  static const List<String> _defaultPlaceTypes = [
    'amusement_park',
    'bar',
    'cafe',
    'campground',
    'casino',
    'lodging',
    'night_club',
    'park',
    'restaurant',
    'shopping_mall',
    'spa',
    'stadium',
    'store',
    'university',
  ];

  String get _apiKey {
    if (Platform.isAndroid) {
      return 'AIzaSyCXoTGE6dDpxApC4jsDHhep3-ym9ipCphg'; // Android Key
    } else if (Platform.isIOS) {
      return 'AIzaSyCv00ZO1lG2lfyaFFTvXnjdbSBjNXKgMNg'; // iOS Key
    } else {
      // Fallback or error case
      throw UnsupportedError('Platform not supported');
    }
  }
  // ------------------------

  // Search field focus
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
    if (_currentPosition != null) {
      _goToCurrentLocation();
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
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

  Future<void> _onMapTapped(LatLng latLng) async {
    setState(() {
      _markers.clear();
      _markers.add(Marker(
        markerId: MarkerId(latLng.toString()),
        position: latLng,
      ));
    });

    final String placeUrl =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${latLng.latitude},${latLng.longitude}&radius=1000&type=${_defaultPlaceTypes.join('|')}&key=$_placesApiKey';

    try {
      final response = await http.get(Uri.parse(placeUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          List<Place> placesWithPhotos = [];
          for (var placeData in data['results']) {
            String? photoUrl;
            if (placeData['photos'] != null && placeData['photos'].isNotEmpty) {
              final photoReference = placeData['photos'][0]['photo_reference'];
              photoUrl = 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$_placesApiKey';
            }

            placesWithPhotos.add(Place(
              id: placeData['place_id'].hashCode, // Using hashCode as a simple ID for now
              name: placeData['name'] ?? 'N/A',
              address: placeData['vicinity'] ?? 'N/A',
              latitude: placeData['geometry']['location']['lat'],
              longitude: placeData['geometry']['location']['lng'],
              eventTypeId: 0, // Placeholder, as eventTypeId is not in nearbysearch response
              photoUrl: photoUrl,
            ));
          }
          _showPlacesListModal(placesWithPhotos);
        } else {
          _showPlaceInfo('No places found nearby.');
        }
      } else {
        _showPlaceInfo('Network Error: ${response.body}');
      }
    } catch (e) {
      _showPlaceInfo('Error finding places: $e');
    }
  }

  void _showPlacesListModal(List<Place> places) { // Changed type to List<Place>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Nearby Places',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: places.length,
                    itemBuilder: (context, index) {
                      final place = places[index];
                      // Removed old dynamic access
                      // final name = place['name'] ?? 'N/A';
                      // final address = place['vicinity'] ?? 'N/A';
                      // final lat = place['geometry']['location']['lat'];
                      // final lng = place['geometry']['location']['lng'];

                      return ListTile(
                        leading: SizedBox(
                          width: 50,
                          height: 50,
                          child: place.photoUrl != null
                              ? Image.network(
                                  place.photoUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image_not_supported),
                                )
                              : const Icon(Icons.image_not_supported),
                        ),
                        title: Text(place.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(place.address),
                            const SizedBox(height: 4),
                            Text('Coords: ${place.latitude.toStringAsFixed(6)}, ${place.longitude.toStringAsFixed(6)}'),
                          ],
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPlaceInfo(String message) {
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
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    zoom: 14.5,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  onTap: _onMapTapped,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
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
      floatingActionButton: CupertinoButton.filled(
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}