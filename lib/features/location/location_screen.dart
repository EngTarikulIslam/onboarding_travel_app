import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../helpers/notification_service.dart';
import '../home/home_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _isLoading = false;
  String _locationStatus = 'Detecting your location...';
  String _selectedLocation = 'Not detected yet';
  bool _locationGranted = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _locationStatus = 'Getting your location...';
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _locationStatus = 'Location services are disabled.';
      });
      _showLocationServiceDialog();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _locationStatus = 'Location permission denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _locationStatus = 'Location permission permanently denied';
      });
      _openAppSettingsDialog();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      if (!mounted) return;

      setState(() {
        _selectedLocation =
        "${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
        _locationStatus = 'Location access granted! Ready to proceed.';
        _locationGranted = true;
        _isLoading = false;
      });

      // Notification permission request
      bool notificationGranted = await NotificationService().requestAllPermissions(); // ← updated method name

      if (!notificationGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications are required for alarms to work'),
            backgroundColor: AppColors.primaryPurple,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationStatus = 'Error fetching location: $e';
        _isLoading = false;
      });
    }
  }

  void _showLocationServiceDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _openAppSettingsDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Denied'),
        content: const Text(
            'Location permission is permanently denied. Please enable it in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings(); // from permission_handler
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _navigateToHome() {
    if (_locationGranted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please allow location access first',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryPurple,
          duration: const Duration(seconds: 2),
        ),
      );
      _getCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppColors.backgroundGradient,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.locationTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.locationSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        height: 1.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                Container(
                  width: 305,
                  height: 215,
                  margin: const EdgeInsets.only(top: 40),
                  child: ClipRRect(
                    child: Image.asset(
                      'assets/location.jpg',
                      width: 305,
                      height: 215,
                      fit: BoxFit.cover,
                      opacity: const AlwaysStoppedAnimation(1.0),
                    ),
                  ),
                ),

                const Spacer(),

                Container(
                  width: 327,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(57),
                    border: Border.all(
                      color: const Color(0xFFFFFFFF).withOpacity(0.36),
                      width: 1,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _getCurrentLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(57),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Use Current Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Image.asset(
                          'assets/icons/location_icon.png',
                          width: 24,
                          height: 24,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: 327,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(57),
                    color: const Color(0xFF5200FF),
                  ),
                  child: ElevatedButton(
                    onPressed: _navigateToHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(57),
                      ),
                    ),
                    child: const Text(
                      'Home',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                if (_locationStatus.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}