import 'package:flutter_test/flutter_test.dart';
import 'package:trying_flutter/features/alarm/domain/entities/prayer_alarm.dart';

void main() {
  group('PrayerAlarm', () {
    group('calculateAlarmTime', () {
      test('should calculate alarm time 30 minutes before prayer', () {
        final fajrTime = DateTime(2026, 2, 3, 5, 30);
        const alarm = PrayerAlarm(
          id: 1,
          prayerName: 'Fajr',
          offset: Duration(minutes: -30),
          label: '30 min before Fajr',
        );

        final result = alarm.calculateAlarmTime(fajrTime);

        expect(result, DateTime(2026, 2, 3, 5, 0));
      });

      test('should calculate alarm time 10 minutes after prayer', () {
        final lastThird = DateTime(2026, 2, 3, 3, 0);
        const alarm = PrayerAlarm(
          id: 2,
          prayerName: 'Last Third',
          offset: Duration(minutes: 10),
          label: '10 min after Last Third',
        );

        final result = alarm.calculateAlarmTime(lastThird);

        expect(result, DateTime(2026, 2, 3, 3, 10));
      });

      test(
        'should calculate alarm at exact prayer time when offset is zero',
        () {
          final dhuhrTime = DateTime(2026, 2, 3, 12, 15);
          const alarm = PrayerAlarm(
            id: 3,
            prayerName: 'Dhuhr',
            offset: Duration.zero,
            label: 'At Dhuhr',
          );

          final result = alarm.calculateAlarmTime(dhuhrTime);

          expect(result, DateTime(2026, 2, 3, 12, 15));
        },
      );

      test('should calculate alarm time 1 hour before prayer', () {
        final asrTime = DateTime(2026, 2, 3, 15, 30);
        const alarm = PrayerAlarm(
          id: 4,
          prayerName: 'Asr',
          offset: Duration(hours: -1),
          label: '1 hr before Asr',
        );

        final result = alarm.calculateAlarmTime(asrTime);

        expect(result, DateTime(2026, 2, 3, 14, 30));
      });
    });

    group('generateLabel', () {
      test('should generate label for time before prayer', () {
        final label = PrayerAlarm.generateLabel(
          'Fajr',
          const Duration(minutes: -30),
        );

        expect(label, '30 min before Fajr');
      });

      test('should generate label for time after prayer', () {
        final label = PrayerAlarm.generateLabel(
          'Last Third',
          const Duration(minutes: 10),
        );

        expect(label, '10 min after Last Third');
      });

      test('should generate label for exact prayer time', () {
        final label = PrayerAlarm.generateLabel('Maghrib', Duration.zero);

        expect(label, 'At Maghrib');
      });

      test('should generate label with hours for longer durations', () {
        final label = PrayerAlarm.generateLabel(
          'Isha',
          const Duration(minutes: -90),
        );

        expect(label, '1 hr 30 min before Isha');
      });

      test('should generate label with just hours when divisible', () {
        final label = PrayerAlarm.generateLabel(
          'Asr',
          const Duration(hours: -2),
        );

        expect(label, '2 hr before Asr');
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        const alarm = PrayerAlarm(
          id: 42,
          prayerName: 'Fajr',
          offset: Duration(minutes: -30),
          label: '30 min before Fajr',
          isEnabled: true,
          vibrate: false,
          volume: 0.5,
        );

        final json = alarm.toJson();

        expect(json['id'], 42);
        expect(json['prayerName'], 'Fajr');
        expect(json['offsetMinutes'], -30);
        expect(json['label'], '30 min before Fajr');
        expect(json['isEnabled'], true);
        expect(json['vibrate'], false);
        expect(json['volume'], 0.5);
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 42,
          'prayerName': 'Fajr',
          'offsetMinutes': -30,
          'label': '30 min before Fajr',
          'isEnabled': true,
          'vibrate': false,
          'volume': 0.5,
        };

        final alarm = PrayerAlarm.fromJson(json);

        expect(alarm.id, 42);
        expect(alarm.prayerName, 'Fajr');
        expect(alarm.offset, const Duration(minutes: -30));
        expect(alarm.label, '30 min before Fajr');
        expect(alarm.isEnabled, true);
        expect(alarm.vibrate, false);
        expect(alarm.volume, 0.5);
      });

      test('should handle missing optional fields with defaults', () {
        final json = {
          'id': 1,
          'prayerName': 'Dhuhr',
          'offsetMinutes': 0,
          'label': 'At Dhuhr',
        };

        final alarm = PrayerAlarm.fromJson(json);

        expect(alarm.isEnabled, true);
        expect(alarm.vibrate, true);
        expect(alarm.volume, 0.8);
      });
    });

    group('copyWith', () {
      test('should create a copy with updated fields', () {
        const original = PrayerAlarm(
          id: 1,
          prayerName: 'Fajr',
          offset: Duration(minutes: -30),
          label: '30 min before Fajr',
          isEnabled: true,
        );

        final updated = original.copyWith(isEnabled: false, volume: 0.5);

        expect(updated.id, 1);
        expect(updated.prayerName, 'Fajr');
        expect(updated.isEnabled, false);
        expect(updated.volume, 0.5);
        expect(original.isEnabled, true); // Original unchanged
      });
    });
  });
}
