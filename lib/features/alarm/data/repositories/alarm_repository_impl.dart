import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:trying_flutter/features/alarm/domain/entities/prayer_alarm.dart';
import 'package:trying_flutter/features/alarm/domain/repositories/alarm_repository.dart';

/// SharedPreferences-based implementation of AlarmRepository.
class AlarmRepositoryImpl implements AlarmRepository {
  static const String _alarmsKey = 'prayer_alarms';

  final SharedPreferences _prefs;

  AlarmRepositoryImpl(this._prefs);

  @override
  Future<List<PrayerAlarm>> getAlarms() async {
    final jsonString = _prefs.getString(_alarmsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((j) => PrayerAlarm.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If parsing fails, return empty list
      return [];
    }
  }

  @override
  Future<void> saveAlarm(PrayerAlarm alarm) async {
    final alarms = await getAlarms();

    // Check if alarm with same ID exists
    final existingIndex = alarms.indexWhere((a) => a.id == alarm.id);
    if (existingIndex != -1) {
      alarms[existingIndex] = alarm;
    } else {
      alarms.add(alarm);
    }

    await _saveAlarms(alarms);
  }

  @override
  Future<void> deleteAlarm(int id) async {
    final alarms = await getAlarms();
    alarms.removeWhere((a) => a.id == id);
    await _saveAlarms(alarms);
  }

  @override
  Future<void> toggleAlarm(int id, bool isEnabled) async {
    final alarms = await getAlarms();
    final index = alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      alarms[index] = alarms[index].copyWith(isEnabled: isEnabled);
      await _saveAlarms(alarms);
    }
  }

  @override
  int generateAlarmId() {
    // Generate a unique ID based on current timestamp
    // Using modulo to keep it in a reasonable range
    return DateTime.now().millisecondsSinceEpoch % 100000;
  }

  Future<void> _saveAlarms(List<PrayerAlarm> alarms) async {
    final jsonList = alarms.map((a) => a.toJson()).toList();
    await _prefs.setString(_alarmsKey, json.encode(jsonList));
  }
}
