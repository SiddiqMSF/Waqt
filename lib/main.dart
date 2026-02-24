import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trying_flutter/core/services/background_service.dart';
import 'package:trying_flutter/core/theme/app_theme.dart';
import 'package:trying_flutter/features/alarm/data/services/alarm_service.dart';
import 'package:trying_flutter/features/alarm/presentation/providers/alarm_provider.dart';
import 'package:trying_flutter/features/alarm/presentation/screens/alarm_ring_screen.dart';
import 'package:trying_flutter/features/prayer/presentation/screens/home_screen.dart';
import 'package:alarm/alarm.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final sharedPrefs = await SharedPreferences.getInstance();

  // Initialize alarm service (before ProviderScope so it's ready for providers)
  if (!kIsWeb) {
    await AlarmService.initialize();
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(sharedPrefs)],
      child: const PrayerTimesApp(),
    ),
  );
}

class PrayerTimesApp extends StatefulWidget {
  const PrayerTimesApp({super.key});

  @override
  State<PrayerTimesApp> createState() => _PrayerTimesAppState();
}

class _PrayerTimesAppState extends State<PrayerTimesApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    _listenToAlarmRing();
  }

  void _listenToAlarmRing() {
    Alarm.ringStream.stream.listen((alarmSettings) {
      debugPrint('Alarm ringing: ${alarmSettings.id}');
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => AlarmRingScreen(alarmSettings: alarmSettings),
        ),
      );
    });
  }

  Future<void> _initialize() async {
    if (kIsWeb) {
      if (mounted) setState(() => _isInitialized = true);
      return;
    }

    await Permission.notification.request();

    if (mounted) {
      setState(() => _isInitialized = true);
    }

    // Start background service AFTER the first frame is rendered
    // This ensures we're fully in foreground state for Android 12+
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _startBackgroundServiceSafely();
    });
  }

  /// Safely start background service with error handling for Android 12+ restrictions
  Future<void> _startBackgroundServiceSafely() async {
    try {
      await initializeBackgroundService();
      debugPrint('Background service started successfully');
    } catch (e) {
      // On Android 12+, this may fail if the app is not truly in foreground
      // The service will be started on next app open or by the BootReceiver
      debugPrint(
        'Background service start failed (expected on Android 12+): $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(backgroundColor: Color(0xFF1a1a2e)),
      );
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Prayer Times',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
