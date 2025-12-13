import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'prayer_time_service.dart';

/// Service for managing persistent notifications with prayer countdown/countup.
class NotificationService {
  static const int _notificationId = 1;
  static const String _channelId = 'prayer_times_channel';
  static const String _channelName = 'Prayer Times';
  static const String _channelDescription = 'Shows countdown to next prayer';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final PrayerTimeService _prayerService;

  Timer? _updateTimer;
  bool _isRunning = false;

  NotificationService(this._prayerService);

  /// Initialize the notification service
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initSettings);

    // Create notification channel for Android 8.0+
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: false,
        enableVibration: false,
      );
      await androidImplementation.createNotificationChannel(androidChannel);
    }
  }

  /// Start the persistent notification and update timer
  Future<void> startService() async {
    if (_isRunning) return;
    _isRunning = true;

    // Start timer to update notification every second
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateNotification();
    });

    // Initial update
    _updateNotification();
  }

  /// Stop the notification service
  Future<void> stopService() async {
    _updateTimer?.cancel();
    _updateTimer = null;
    _isRunning = false;

    await _notificationsPlugin.cancel(_notificationId);
  }

  /// Update the notification with current prayer status
  void _updateNotification() {
    final now = DateTime.now();
    final status = _prayerService.getCurrentStatus(now);

    String title;
    String body;

    if (status.isInIqamahPeriod) {
      // Show countdown to iqamah
      final timeToIqamah = status.timeUntilIqamah;
      title = '🕌 ${status.currentMarker!.name} - Iqamah Soon';
      body = 'Iqamah in ${_formatDuration(timeToIqamah)}';
    } else if (status.isInCountupPeriod) {
      // Show countup (time since prayer started)
      final timeSince = status.timeSinceCurrent;
      title = '🕌 ${status.currentMarker!.name}';
      body =
          '${_formatDuration(timeSince)} since Adhan • Next: ${status.nextMarker?.name ?? ""}';
    } else {
      // Show countdown to next prayer
      final timeToNext = status.timeUntilNext;
      final nextName = status.nextMarker?.name ?? 'Next Prayer';
      final nextTime = status.nextMarker?.time;
      final timeStr = nextTime != null ? _formatTime(nextTime) : '';

      title = '⏱ $nextName at $timeStr';
      body = 'In ${_formatDuration(timeToNext)}';
    }

    _showNotification(title, body);
  }

  /// Show/update the persistent notification
  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      ongoing: true, // Makes it persistent
      autoCancel: false,
      onlyAlertOnce: true, // Prevents constant buzzing/sound
      showWhen: false,
      playSound: false,
      enableVibration: false,
      category: AndroidNotificationCategory.service,
      visibility: NotificationVisibility.public,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(_notificationId, title, body, details);
  }

  /// Format duration as HH:MM:SS or MM:SS
  String _formatDuration(Duration duration) {
    // Handle negative durations
    if (duration.isNegative) {
      return '00:00';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format time as HH:MM
  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
