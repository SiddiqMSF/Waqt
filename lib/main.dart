import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
import 'services/prayer_time_service.dart';
import 'services/location_service.dart';
import 'services/background_service.dart';
import 'services/home_widget_service.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service (only on mobile)
  if (!kIsWeb) {
    await initializeBackgroundService();
  }

  runApp(const PrayerTimesApp());
}

class PrayerTimesApp extends StatefulWidget {
  const PrayerTimesApp({super.key});

  @override
  State<PrayerTimesApp> createState() => _PrayerTimesAppState();
}

class _PrayerTimesAppState extends State<PrayerTimesApp> {
  PrayerTimeService? _prayerService;
  String _status = 'Initializing...';
  bool _hasError = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to defer initialization after first build
    Future.microtask(() => _initialize());
  }

  Future<void> _initialize() async {
    try {
      double latitude = LocationService.defaultLatitude;
      double longitude = LocationService.defaultLongitude;

      // Only request permissions on mobile platforms
      if (!kIsWeb) {
        // Request notification permission (Android 13+)
        if (mounted) {
          setState(() => _status = 'Requesting permissions...');
        }
        await Permission.notification.request();

        // Get location
        if (mounted) {
          setState(() => _status = 'Getting location...');
        }
        final locationService = LocationService();
        final coords = await locationService.getCoordinates();
        latitude = coords.latitude;
        longitude = coords.longitude;
      } else {
        if (mounted) {
          setState(() => _status = 'Using default location (web)...');
        }
        // Small delay for web to show loading screen
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Initialize prayer service
      if (mounted) {
        setState(() => _status = 'Calculating prayer times...');
      }
      final prayerService = PrayerTimeService(
        latitude: latitude,
        longitude: longitude,
      );

      // Start background service (only on mobile)
      if (!kIsWeb) {
        if (mounted) {
          setState(() => _status = 'Starting background service...');
        }
        await startBackgroundService();
      }

      // Update state to show home screen (no navigation)
      if (mounted) {
        setState(() {
          _prayerService = prayerService;
          _isLoading = false;
        });
        _updateHomeWidget(prayerService);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error: $e';
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateHomeWidget(PrayerTimeService service) async {
    try {
      final now = DateTime.now();
      final status = service.getCurrentStatus(now);
      final nextPrayer = status.nextMarker;

      if (nextPrayer != null) {
        final timeStr = DateFormat.jm().format(nextPrayer.time);
        await HomeWidgetService.updatePrayerData(
          nextPrayer.name,
          timeStr,
          nextPrayer.time.millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      debugPrint('Failed to update home widget: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prayer Times',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: _isLoading || _hasError
          ? _buildLoadingScreen()
          : HomeScreen(prayerService: _prayerService!),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🕌', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 32),
            const Text(
              'Prayer Times',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 48),
            if (!_hasError) ...[
              const CircularProgressIndicator(color: Colors.cyanAccent),
              const SizedBox(height: 24),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _hasError
                      ? Colors.redAccent
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
            if (_hasError) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isLoading = true;
                    _status = 'Retrying...';
                  });
                  _initialize();
                },
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
