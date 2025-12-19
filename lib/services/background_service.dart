import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/date_time_utils.dart';
import 'prayer_time_service.dart';
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

  // Create prayer service with cached coordinates
  final prayerService = PrayerTimeService(
    latitude: coords.latitude,
    longitude: coords.longitude,
  );

  // Handle stop command
  service.on('stop').listen((event) {
    service.stopSelf();
  });

  // Update notification every second
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        final notification = _buildNotification(prayerService);

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
      }
    }
  });
}

/// Build notification content based on current prayer status
_NotificationContent _buildNotification(PrayerTimeService prayerService) {
  final now = DateTime.now();
  final status = prayerService.getCurrentStatus(now);

  String title;
  String body;

  if (status.isInIqamahPeriod) {
    // Show countdown to iqamah
    final timeToIqamah = status.timeUntilIqamah;
    title = '🕌 ${status.currentMarker!.name} - Iqamah Soon';
    body = 'Iqamah in ${DateTimeUtils.formatDuration(timeToIqamah)}';
  } else if (status.isInPostIqamahPeriod) {
    // Show elapsed time since iqamah (up to 20 minutes)
    final timeSince = status.timeSinceIqamah;
    title = '🕌 ${status.currentMarker!.name} - Iqamah Started';
    body =
        '${DateTimeUtils.formatDuration(timeSince)} since Iqamah • Next: ${status.nextMarker?.name ?? ""}';
  } else if (status.isInCountupPeriod) {
    // Show countup (time since prayer started)
    final timeSince = status.timeSinceCurrent;
    title = '🕌 ${status.currentMarker!.name}';
    body =
        '${DateTimeUtils.formatDuration(timeSince)} since Adhan • Next: ${status.nextMarker?.name ?? ""}';
  } else {
    // Show countdown to next prayer
    final timeToNext = status.timeUntilNext;
    final nextName = status.nextMarker?.name ?? 'Next Prayer';
    final nextTime = status.nextMarker?.time;
    final timeStr = nextTime != null ? DateTimeUtils.formatTime(nextTime) : '';

    title = '⏱ $nextName at $timeStr';
    body = 'In ${DateTimeUtils.formatDuration(timeToNext)}';
  }

  return _NotificationContent(title: title, body: body);
}

/// Simple class to hold notification content
class _NotificationContent {
  final String title;
  final String body;

  _NotificationContent({required this.title, required this.body});
}
