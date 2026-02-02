import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Request notification permission
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // Check if notification permission is granted
  Future<bool> isNotificationPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // Request storage permission (for Android)
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // Check if storage permission is granted
  Future<bool> isStoragePermissionGranted() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  // Check if location permission is granted
  Future<bool> isLocationPermissionGranted() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  // Open app settings
  Future<void> openAppSettings() async {
    await openAppSettings(); // This is from permission_handler package
  }

  // Request all required permissions
  Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};

    // Request notification permission
    results['notification'] = await requestNotificationPermission();

    // Request storage permission (for Android)
    results['storage'] = await requestStoragePermission();

    // Request location permission
    results['location'] = await requestLocationPermission();

    return results;
  }

  // Check all required permissions
  Future<Map<String, bool>> checkAllPermissions() async {
    final results = <String, bool>{};

    results['notification'] = await isNotificationPermissionGranted();
    results['storage'] = await isStoragePermissionGranted();
    results['location'] = await isLocationPermissionGranted();

    return results;
  }

  // Check if we need to show rationale for permission
  Future<bool> shouldShowRequestPermissionRationale(Permission permission) async {
    final status = await permission.status;
    return status.isDenied || status.isRestricted;
  }
}