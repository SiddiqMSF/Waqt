import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling location permissions and retrieval.
class LocationService {
  // Default coordinates (Madinah)
  static const double defaultLatitude = 24.48;
  static const double defaultLongitude = 39.55;

  static const String _keyLatitude = 'latitude';
  static const String _keyLongitude = 'longitude';

  final SharedPreferences? _prefs;

  /// Creates a LocationService. If [prefs] is provided, it will be used
  /// instead of fetching a new instance.
  LocationService([this._prefs]);

  /// Request location permission and get current position
  Future<Position?> getCurrentPosition() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // Request permission
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Get coordinates, falling back to cached or default if location unavailable
  Future<({double latitude, double longitude})> getCoordinates() async {
    final position = await getCurrentPosition();
    if (position != null) {
      // Save to shared_preferences
      await _saveCoordinates(position.latitude, position.longitude);
      return (latitude: position.latitude, longitude: position.longitude);
    }

    // Try to get cached
    return await getCachedCoordinates();
  }

  /// Get cached coordinates or default
  Future<({double latitude, double longitude})> getCachedCoordinates() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_keyLatitude);
      final lng = prefs.getDouble(_keyLongitude);

      if (lat != null && lng != null) {
        return (latitude: lat, longitude: lng);
      }
    } catch (e) {
      // Ignore errors in background/init
    }

    return (latitude: defaultLatitude, longitude: defaultLongitude);
  }

  Future<void> _saveCoordinates(double latitude, double longitude) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setDouble(_keyLatitude, latitude);
      await prefs.setDouble(_keyLongitude, longitude);
    } catch (e) {
      // Ignore errors
    }
  }
}
