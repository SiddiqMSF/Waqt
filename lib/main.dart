import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trying_flutter/core/services/background_service.dart';
import 'package:trying_flutter/core/theme/app_theme.dart';
import 'package:trying_flutter/features/prayer/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service (only on mobile)
  if (!kIsWeb) {
    await initializeBackgroundService();
  }

  runApp(const ProviderScope(child: PrayerTimesApp()));
}

class PrayerTimesApp extends StatefulWidget {
  const PrayerTimesApp({super.key});

  @override
  State<PrayerTimesApp> createState() => _PrayerTimesAppState();
}

class _PrayerTimesAppState extends State<PrayerTimesApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (kIsWeb) {
      if (mounted) setState(() => _isInitialized = true);
      return;
    }

    // minimal startup logic: permissions
    await Permission.notification.request();
    // Location permissions are handled by LocationService when requested by Provider

    // Tiny delay to ensure smooth startup
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If not initialized, show simple splash (or just LoadingScreen from HomeScreen handles loading state effectively)
    // But we want to ensure background service & permissions are at least attempted.

    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(backgroundColor: Color(0xFF1a1a2e)),
      );
    }

    return MaterialApp(
      title: 'Prayer Times',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark, // Default to dark as per original design
      home: const HomeScreen(),
    );
  }
}
