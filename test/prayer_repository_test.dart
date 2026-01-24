import 'package:flutter_test/flutter_test.dart';
import 'package:trying_flutter/features/prayer/data/repositories/prayer_repository_impl.dart';

void main() {
  group('PrayerRepositoryImpl', () {
    late PrayerRepositoryImpl repository;
    // Mock coordinates for Madinah (approximate) or standard test loc
    const double lat = 24.5247;
    const double lng = 39.5692;

    setUp(() {
      repository = PrayerRepositoryImpl();
    });

    test('should return prayers for a location', () async {
      final prayers = await repository.getPrayerTimes(
        latitude: lat,
        longitude: lng,
      );

      expect(prayers.isNotEmpty, true);
      // We expect at least the 5 compulsory prayers + sunrise
      expect(prayers.length, greaterThanOrEqualTo(5));

      final names = prayers.map((m) => m.name).toList();
      expect(names, contains('Fajr'));
      expect(names, contains('Dhuhr'));
      expect(names, contains('Asr'));
      expect(names, contains('Maghrib'));
      expect(names, contains('Isha'));
    });

    test('should have correct iqamah delays', () async {
      final prayers = await repository.getPrayerTimes(
        latitude: lat,
        longitude: lng,
      );
      final fajr = prayers.firstWhere((p) => p.name == 'Fajr');

      // Assuming standard 25 min for Fajr as per previous config
      expect(fajr.iqamahDelay?.inMinutes, 25);
    });

    test('should identify next prayer correctly', () async {
      final prayers = await repository.getPrayerTimes(
        latitude: lat,
        longitude: lng,
      );

      // Construct a time BEFORE Fajr
      final fajr = prayers.firstWhere((p) => p.name == 'Fajr');
      final beforeFajr = fajr.time.subtract(const Duration(minutes: 10));

      final next = repository.getNextPrayer(prayers, beforeFajr);
      expect(next, isNotNull);
      expect(next?.name, 'Fajr');
    });

    test('should identify current prayer correctly', () async {
      final prayers = await repository.getPrayerTimes(
        latitude: lat,
        longitude: lng,
      );

      final dhuhr = prayers.firstWhere((p) => p.name == 'Dhuhr');
      final asr = prayers.firstWhere((p) => p.name == 'Asr');

      // Test 1: Just after Dhuhr starts
      final afterDhuhr = dhuhr.time.add(const Duration(seconds: 1));
      final currentAtDhuhr = repository.getCurrentPrayer(prayers, afterDhuhr);
      expect(currentAtDhuhr?.name, 'Dhuhr');

      // Test 2: Middle between Dhuhr and Asr
      final midTime = dhuhr.time.add(asr.time.difference(dhuhr.time) ~/ 2);
      final currentMid = repository.getCurrentPrayer(prayers, midTime);
      expect(currentMid?.name, 'Dhuhr');

      // Test 3: Before Fajr (should be null as strictly speaking "today's" first prayer hasn't started)
      // Note: In a real app we might want to show "Esha" from yesterday, but this method operates on the passed list.
      final fajr = prayers.firstWhere((p) => p.name == 'Fajr');
      final beforeFajr = fajr.time.subtract(const Duration(minutes: 10));
      final currentBeforeFajr = repository.getCurrentPrayer(
        prayers,
        beforeFajr,
      );
      expect(currentBeforeFajr, isNull);
    });
  });
}
