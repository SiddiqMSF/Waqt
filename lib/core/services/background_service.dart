import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:trying_flutter/core/services/home_widget_service.dart';
import 'package:trying_flutter/core/utils/date_time_utils.dart';
import 'package:trying_flutter/features/prayer/data/repositories/prayer_repository_impl.dart';
import 'package:trying_flutter/features/prayer/domain/entities/prayer_time.dart';
import 'location_service.dart';

/// Notification channel constants
const String notificationChannelId = 'prayer_times_channel';
const String notificationChannelName = 'Prayer Times';
const String notificationChannelDescription = 'Shows countdown to next prayer';
const int notificationId = 1;

/// Initialize the background service
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Create notification channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    notificationChannelName,
    description: notificationChannelDescription,
    importance: Importance.high,
    playSound: false,
    enableVibration: false,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
    androidConfiguration: AndroidConfiguration(
      autoStart: true,
      onStart: onStart,
      isForegroundMode: true,
      autoStartOnBoot: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'Prayer Times',
      initialNotificationContent: 'Initializing...',
      foregroundServiceNotificationId: notificationId,
      foregroundServiceTypes: [AndroidForegroundType.specialUse],
    ),
  );
}

/// Start the background service
Future<void> startBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.startService();
}

/// iOS background handler
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

/// Main entry point for the background service
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Get cached coordinates
  final locationService = LocationService();
  final coords = await locationService.getCachedCoordinates();

  // Use Repository directly
  final repository = PrayerRepositoryImpl();

  // Handle stop command
  service.on('stop').listen((event) {
    service.stopSelf();
  });

  // Update notification and widget every second
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // Calculate times fresh every tick (or could cache purely times list)
        final prayers = await repository.getPrayerTimes(
          latitude: coords.latitude,
          longitude: coords.longitude,
        );

        final notification = _buildNotification(prayers, repository);

        await flutterLocalNotificationsPlugin.show(
          notificationId,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              notificationChannelName,
              channelDescription: notificationChannelDescription,
              importance: Importance.high,
              priority: Priority.high,
              ongoing: true,
              autoCancel: false,
              onlyAlertOnce: true,
              showWhen: false,
              playSound: false,
              enableVibration: false,
              category: AndroidNotificationCategory.service,
              visibility: NotificationVisibility.public,
            ),
          ),
        );

        // Update Home Widget
        final now = DateTime.now();
        final nextPrayer = repository.getNextPrayer(prayers, now);
        if (nextPrayer != null) {
          final timeStr = DateTimeUtils.formatTime(nextPrayer.time);
          await HomeWidgetService.updatePrayerData(
            nextPrayer.name,
            timeStr,
            nextPrayer.time.millisecondsSinceEpoch,
          );
        }
      }
    }
  });
}

/// Build notification content based on current prayer status
_NotificationContent _buildNotification(
  List<PrayerTime> prayers,
  PrayerRepositoryImpl repo,
) {
  final now = DateTime.now();
  final nextPrayer = repo.getNextPrayer(prayers, now);
  // Need to find "current" for iqamah logic.
  // Let's assume simplest "current" is the last passed prayer.
  PrayerTime? currentPrayer;

  // Sort and find last passed
  final sorted = List<PrayerTime>.from(prayers)
    ..sort((a, b) => a.time.compareTo(b.time));
  for (final p in sorted) {
    if (p.time.isBefore(now)) {
      currentPrayer = p;
    }
  }

  String title;
  String body;

  // Re-implement basic status logic here locally for independent background service
  bool isInIqamahWindow = false;
  Duration timeUntilIqamah = Duration.zero;

  if (currentPrayer != null && currentPrayer.isPrayer) {
    isInIqamahWindow = currentPrayer.isInIqamahWindow(now);
    if (isInIqamahWindow) {
      timeUntilIqamah = currentPrayer.iqamahTime!.difference(now);
    }
  }

  if (isInIqamahWindow && currentPrayer != null) {
    // Show countdown to iqamah
    title = '🕌 ${currentPrayer.name} - Iqamah Soon';
    body = 'Iqamah in ${DateTimeUtils.formatDuration(timeUntilIqamah)}';
  } else if (nextPrayer != null) {
    // Show countdown to next prayer
    final timeToNext = nextPrayer.time.difference(now);
    final timeStr = DateTimeUtils.formatTime(nextPrayer.time);

    title = '⏱ ${nextPrayer.name} at $timeStr';
    body = 'In ${DateTimeUtils.formatDuration(timeToNext)}';
  } else {
    // End of day
    title = 'Prayer Times';
    body = 'No more prayers today';
  }

  return _NotificationContent(title: title, body: body);
}

/// Simple class to hold notification content
class _NotificationContent {
  final String title;
  final String body;

  _NotificationContent({required this.title, required this.body});
}
