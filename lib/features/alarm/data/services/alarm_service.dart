import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:trying_flutter/features/alarm/domain/entities/prayer_alarm.dart';
import 'package:trying_flutter/features/prayer/domain/entities/prayer_time.dart';

/// Service for scheduling and managing alarms using the alarm package.
class AlarmService {
  static const String _audioPath = 'assets/alarm.mp3';

  /// Initialize the alarm service
  static Future<void> initialize() async {
    await Alarm.init();
  }

  /// Schedule an alarm for a specific prayer time
  Future<bool> scheduleAlarm(
    PrayerAlarm prayerAlarm,
    DateTime targetTime,
  ) async {
    // Don't schedule if alarm is disabled
    if (!prayerAlarm.isEnabled) {
      return false;
    }

    // Don't schedule if target time is in the past
    if (targetTime.isBefore(DateTime.now())) {
      return false;
    }

    final alarmSettings = AlarmSettings(
      id: prayerAlarm.id,
      dateTime: targetTime,
      assetAudioPath: _audioPath,
      loopAudio: true,
      vibrate: prayerAlarm.vibrate,
      warningNotificationOnKill: Platform.isIOS,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        volume: prayerAlarm.volume,
        fadeDuration: const Duration(seconds: 3),
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: prayerAlarm.label,
        body: _getNotificationBody(prayerAlarm.prayerName),
        stopButton: 'Stop',
        icon: 'notification_icon',
        iconColor: const Color(0xFF6750A4),
      ),
    );

    return Alarm.set(alarmSettings: alarmSettings);
  }

  /// Cancel a specific alarm
  Future<bool> cancelAlarm(int alarmId) async {
    return Alarm.stop(alarmId);
  }

  /// Reschedule all enabled alarms based on current prayer times
  Future<void> rescheduleAllAlarms(
    List<PrayerAlarm> alarms,
    List<PrayerTime> prayerTimes,
  ) async {
    for (final alarm in alarms) {
      // First cancel existing alarm
      await cancelAlarm(alarm.id);

      if (!alarm.isEnabled) continue;

      // Find matching prayer time
      final prayerTime = prayerTimes.firstWhere(
        (p) => p.name == alarm.prayerName,
        orElse: () => prayerTimes.first,
      );

      // Calculate target time
      final targetTime = alarm.calculateAlarmTime(prayerTime.time);

      // Schedule if in the future
      if (targetTime.isAfter(DateTime.now())) {
        await scheduleAlarm(alarm, targetTime);
      }
    }
  }

  /// Get all currently scheduled alarms
  Future<List<AlarmSettings>> getScheduledAlarms() async {
    return Alarm.getAlarms();
  }

  /// Check if an alarm is scheduled
  Future<bool> isAlarmScheduled(int alarmId) async {
    final alarms = await Alarm.getAlarms();
    return alarms.any((a) => a.id == alarmId);
  }

  String _getNotificationBody(String prayerName) {
    switch (prayerName) {
      case 'Fajr':
        return 'Time to prepare for Fajr prayer';
      case 'Dhuhr':
        return 'Time to prepare for Dhuhr prayer';
      case 'Asr':
        return 'Time to prepare for Asr prayer';
      case 'Maghrib':
        return 'Time to prepare for Maghrib prayer';
      case 'Isha':
        return 'Time to prepare for Isha prayer';
      case 'Sunrise':
        return 'Sunrise is approaching';
      case 'First Third':
        return 'End of first third of the night';
      case 'Midnight':
        return 'Islamic midnight is here';
      case 'Last Third':
        return 'Last third of the night - blessed time for prayer';
      default:
        return 'Prayer reminder';
    }
  }
}
