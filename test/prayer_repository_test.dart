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
  });
}
