import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:movidapp/presentation/screens/map_screen.dart';
import 'package:movidapp/presentation/screens/account_page.dart'; // Import AccountPage
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  _checkAuthAndNavigate() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        // User is logged in, proceed to MapScreen after getting location
        try {
          final position = await _determinePosition();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MapScreen(initialPosition: position),
            ),
          );
        } catch (e) {
          print("Error getting location: $e");
          // Fallback to MapScreen without initial position or show an error screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MapScreen()),
          );
        }
      } else {
        // User is not logged in, navigate to AccountPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AccountPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
