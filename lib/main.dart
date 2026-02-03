import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trying_flutter/core/services/background_service.dart';
import 'package:trying_flutter/core/theme/app_theme.dart';
import 'package:trying_flutter/features/prayer/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

    await Permission.notification.request();

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(backgroundColor: Color(0xFF1a1a2e)),
      );
    }

    // Use DynamicColorBuilder to get wallpaper colors on Android 12+
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Prayer Times',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(lightDynamic),
          darkTheme: AppTheme.darkTheme(darkDynamic),
          themeMode: ThemeMode.dark,
          home: const HomeScreen(),
        );
      },
    );
  }
}
