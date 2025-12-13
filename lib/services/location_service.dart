import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling location permissions and retrieval.
class LocationService {
  // Default coordinates (Madinah)
  static const double defaultLatitude = 24.48;
  static const double defaultLongitude = 39.55;

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

  /// Get coordinates, falling back to default if location unavailable
  Future<({double latitude, double longitude})> getCoordinates() async {
    final position = await getCurrentPosition();
    if (position != null) {
      return (latitude: position.latitude, longitude: position.longitude);
    }
    return (latitude: defaultLatitude, longitude: defaultLongitude);
  }
}
