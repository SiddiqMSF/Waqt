import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trying_flutter/features/alarm/data/repositories/alarm_repository_impl.dart';
import 'package:trying_flutter/features/alarm/data/services/alarm_service.dart';
import 'package:trying_flutter/features/alarm/domain/entities/prayer_alarm.dart';
import 'package:trying_flutter/features/alarm/domain/repositories/alarm_repository.dart';
import 'package:trying_flutter/features/prayer/presentation/providers/prayer_provider.dart';

/// SharedPreferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

/// Alarm repository provider
final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AlarmRepositoryImpl(prefs);
});

/// Alarm service provider
final alarmServiceProvider = Provider<AlarmService>((ref) {
  return AlarmService();
});

/// State notifier for managing alarms
class AlarmsNotifier extends StateNotifier<AsyncValue<List<PrayerAlarm>>> {
  final AlarmRepository _repository;
  final AlarmService _service;
  final Ref _ref;

  AlarmsNotifier(this._repository, this._service, this._ref)
    : super(const AsyncValue.loading()) {
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    try {
      final alarms = await _repository.getAlarms();
      state = AsyncValue.data(alarms);
      // Schedule all alarms after loading
      await _rescheduleAlarms(alarms);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addAlarm(PrayerAlarm alarm) async {
    try {
      await _repository.saveAlarm(alarm);
      await _scheduleAlarm(alarm);
      await _loadAlarms();
    } catch (e) {
      // Reload to ensure consistent state
      await _loadAlarms();
    }
  }

  Future<void> updateAlarm(PrayerAlarm alarm) async {
    try {
      // Cancel old alarm first
      await _service.cancelAlarm(alarm.id);
      await _repository.saveAlarm(alarm);
      await _scheduleAlarm(alarm);
      await _loadAlarms();
    } catch (e) {
      await _loadAlarms();
    }
  }

  Future<void> deleteAlarm(int id) async {
    try {
      await _service.cancelAlarm(id);
      await _repository.deleteAlarm(id);
      await _loadAlarms();
    } catch (e) {
      await _loadAlarms();
    }
  }

  Future<void> toggleAlarm(int id, bool isEnabled) async {
    try {
      await _repository.toggleAlarm(id, isEnabled);
      final alarms = await _repository.getAlarms();
      final alarm = alarms.firstWhere((a) => a.id == id);

      if (isEnabled) {
        await _scheduleAlarm(alarm);
      } else {
        await _service.cancelAlarm(id);
      }

      state = AsyncValue.data(alarms);
    } catch (e) {
      await _loadAlarms();
    }
  }

  Future<void> _scheduleAlarm(PrayerAlarm alarm) async {
    if (!alarm.isEnabled) return;

    final prayersAsync = _ref.read(prayerTimesProvider);
    await prayersAsync.whenOrNull(
      data: (prayers) async {
        final prayerTime = prayers.firstWhere(
          (p) => p.name == alarm.prayerName,
          orElse: () => prayers.first,
        );
        final targetTime = alarm.calculateAlarmTime(prayerTime.time);
        await _service.scheduleAlarm(alarm, targetTime);
      },
    );
  }

  Future<void> _rescheduleAlarms(List<PrayerAlarm> alarms) async {
    final prayersAsync = _ref.read(prayerTimesProvider);
    await prayersAsync.whenOrNull(
      data: (prayers) async {
        await _service.rescheduleAllAlarms(alarms, prayers);
      },
    );
  }

  /// Reschedule all alarms (call when prayer times update)
  Future<void> rescheduleAll() async {
    final currentState = state;
    if (currentState is AsyncData<List<PrayerAlarm>>) {
      await _rescheduleAlarms(currentState.value);
    }
  }

  int generateId() {
    return _repository.generateAlarmId();
  }
}

/// Provider for alarms state notifier
final alarmsNotifierProvider =
    StateNotifierProvider<AlarmsNotifier, AsyncValue<List<PrayerAlarm>>>((ref) {
      final repository = ref.watch(alarmRepositoryProvider);
      final service = ref.watch(alarmServiceProvider);
      return AlarmsNotifier(repository, service, ref);
    });

/// Convenience provider for just the list of alarms
final alarmsProvider = Provider<List<PrayerAlarm>>((ref) {
  final state = ref.watch(alarmsNotifierProvider);
  return state.valueOrNull ?? [];
});

/// Provider to check if a specific prayer has an alarm configured
final prayerHasAlarmProvider = Provider.family<bool, String>((ref, prayerName) {
  final alarms = ref.watch(alarmsProvider);
  return alarms.any((a) => a.prayerName == prayerName && a.isEnabled);
});
