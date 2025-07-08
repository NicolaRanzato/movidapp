import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:movidapp/presentation/screens/new_event_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer();
  Position? _currentPosition;
  final Set<Marker> _markers = {};

  // Animation state
  Offset? _longPressPosition;
  late AnimationController _animationController;

  // Search field focus
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchFocusNode.dispose(); // Dispose the focus node
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // TODO: Handle service disabled
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // TODO: Handle permission denied
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // TODO: Handle permission permanently denied
      return;
    }

    _currentPosition = await Geolocator.getCurrentPosition();
    setState(() {});
    _goToCurrentLocation();
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

  void _onLongPressStart(LongPressStartDetails details) {
    setState(() {
      _longPressPosition = details.localPosition;
    });
    _animationController.forward();
  }

  void _onLongPressEnd(LongPressEndDetails details) async {
    _animationController.reverse();
    final GoogleMapController controller = await _controller.future;
    final LatLng latLng = await controller.getLatLng(
      ScreenCoordinate(
        x: details.localPosition.dx.round(),
        y: details.localPosition.dy.round(),
      ),
    );
    setState(() {
      _markers.clear(); // No more markers
      _longPressPosition = null;
    });
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewEventScreen(coordinates: latLng)),
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
              // TODO: Navigate to Account screen
            },
            child: const Text('Account'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to Settings screen
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
                GestureDetector(
                  onLongPressStart: _onLongPressStart,
                  onLongPressEnd: _onLongPressEnd,
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      zoom: 14.5,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false, // Using a custom button
                  ),
                ),
                if (_longPressPosition != null)
                  Positioned(
                    left: _longPressPosition!.dx - 40,
                    top: _longPressPosition!.dy - 40,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.0, end: 1.0).animate(_animationController),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoSearchTextField(
                            focusNode: _searchFocusNode, // Assign the focus node
                            placeholder: 'Search',
                            backgroundColor: CupertinoColors.systemGrey5.withOpacity(0.8),
                            onTap: () {
                              _searchFocusNode.requestFocus(); // Request focus explicitly
                            },
                            onSubmitted: (value) {
                              _searchFocusNode.unfocus(); // Dismiss keyboard using its own focus node
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

