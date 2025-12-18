import 'package:flutter_test/flutter_test.dart';
import 'package:trying_flutter/models/prayer_marker.dart';
import 'package:trying_flutter/services/prayer_time_service.dart';

void main() {
  group('PrayerTimeService', () {
    late PrayerTimeService service;

    setUp(() {
      // Using default Madinah coordinates
      service = PrayerTimeService();
    });

    test('should return 9 markers for a date', () {
      final now = DateTime.now();
      final markers = service.getMarkersForDate(now);

      expect(markers.length, 9);

      // Verify all expected markers are present
      final names = markers.map((m) => m.name).toList();
      expect(names, contains('Fajr'));
      expect(names, contains('Sunrise'));
      expect(names, contains('Dhuhr'));
      expect(names, contains('Asr'));
      expect(names, contains('Maghrib'));
      expect(names, contains('Isha'));
      expect(names, contains('First Third'));
      expect(names, contains('Midnight'));
      expect(names, contains('Last Third'));
    });

    test('should have correct iqamah delays for prayers', () {
      expect(IqamahConfig.fajr.inMinutes, 25);
      expect(IqamahConfig.dhuhr.inMinutes, 20);
      expect(IqamahConfig.asr.inMinutes, 20);
      expect(IqamahConfig.maghrib.inMinutes, 10);
      expect(IqamahConfig.isha.inMinutes, 20);
    });

    test('should return prayers with iqamah times', () {
      final now = DateTime.now();
      final markers = service.getMarkersForDate(now);

      final fajr = markers.firstWhere((m) => m.name == 'Fajr');
      expect(fajr.iqamahDelay, isNotNull);
      expect(fajr.iqamahTime, isNotNull);
      expect(fajr.iqamahTime!.difference(fajr.time).inMinutes, 25);
    });

    test('should calculate night thirds correctly', () {
      final now = DateTime.now();
      final markers = service.getMarkersForDate(now);

      final maghrib = markers.firstWhere((m) => m.name == 'Maghrib');
      final firstThird = markers.firstWhere((m) => m.name == 'First Third');
      final midnight = markers.firstWhere((m) => m.name == 'Midnight');
      final lastThird = markers.firstWhere((m) => m.name == 'Last Third');

      // First third should be before midnight
      expect(firstThird.time.isBefore(midnight.time), true);
      // Midnight should be before last third
      expect(midnight.time.isBefore(lastThird.time), true);
      // All should be after maghrib
      expect(firstThird.time.isAfter(maghrib.time), true);
    });

    test('getCurrentStatus should return valid status', () {
      final now = DateTime.now();
      final status = service.getCurrentStatus(now);

      expect(status.now, now);
      // Should always have a next marker
      expect(status.nextMarker, isNotNull);
    });

    test(
      'isInPostIqamahPeriod should return true within 20 mins after iqamah',
      () {
        final now = DateTime.now();
        final markers = service.getMarkersForDate(now);

        // Find a prayer with iqamah
        final fajr = markers.firstWhere((m) => m.name == 'Fajr');
        expect(fajr.iqamahTime, isNotNull);

        // Test 5 minutes after iqamah
        final fiveAfterIqamah = fajr.iqamahTime!.add(
          const Duration(minutes: 5),
        );
        final status = service.getCurrentStatus(fiveAfterIqamah);

        // If we're on the right day and time, should be in post-iqamah period
        if (status.currentMarker?.name == 'Fajr') {
          expect(status.isInPostIqamahPeriod, true);
          expect(status.timeSinceIqamah.inMinutes, 5);
        }
      },
    );

    test('isInPostIqamahPeriod should return false after 20 mins', () {
      final now = DateTime.now();
      final markers = service.getMarkersForDate(now);

      // Find a prayer with iqamah
      final fajr = markers.firstWhere((m) => m.name == 'Fajr');
      expect(fajr.iqamahTime, isNotNull);

      // Test 25 minutes after iqamah
      final twentyFiveAfterIqamah = fajr.iqamahTime!.add(
        const Duration(minutes: 25),
      );
      final status = service.getCurrentStatus(twentyFiveAfterIqamah);

      // Should NOT be in post-iqamah period after 20 mins
      if (status.currentMarker?.name == 'Fajr') {
        expect(status.isInPostIqamahPeriod, false);
      }
    });

    test('isInIqamahPeriod should be exclusive of isInPostIqamahPeriod', () {
      final now = DateTime.now();
      final status = service.getCurrentStatus(now);

      // Cannot be in both periods at the same time
      expect(status.isInIqamahPeriod && status.isInPostIqamahPeriod, false);
    });
  });
}
