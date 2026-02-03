import 'package:trying_flutter/features/alarm/domain/entities/prayer_alarm.dart';

/// Abstract repository for alarm CRUD operations.
abstract class AlarmRepository {
  /// Get all configured alarms
  Future<List<PrayerAlarm>> getAlarms();

  /// Save an alarm (create or update)
  Future<void> saveAlarm(PrayerAlarm alarm);

  /// Delete an alarm by ID
  Future<void> deleteAlarm(int id);

  /// Toggle alarm enabled state
  Future<void> toggleAlarm(int id, bool isEnabled);

  /// Generate a unique ID for a new alarm
  int generateAlarmId();
}
