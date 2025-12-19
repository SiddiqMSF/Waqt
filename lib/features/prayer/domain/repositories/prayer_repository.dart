import 'package:trying_flutter/features/prayer/domain/entities/prayer_time.dart';

abstract class PrayerRepository {
  Future<List<PrayerTime>> getPrayerTimes({
    required double latitude,
    required double longitude,
  });

  PrayerTime? getNextPrayer(List<PrayerTime> prayers, DateTime now);
}
