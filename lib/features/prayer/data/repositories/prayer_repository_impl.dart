import 'package:adhan/adhan.dart';
import 'package:trying_flutter/features/prayer/domain/entities/prayer_time.dart';
import 'package:trying_flutter/features/prayer/domain/repositories/prayer_repository.dart';

class PrayerRepositoryImpl implements PrayerRepository {
  @override
  Future<List<PrayerTime>> getPrayerTimes({
    required double latitude,
    required double longitude,
  }) async {
    final myCoordinates = Coordinates(latitude, longitude);
    final params = CalculationMethod.umm_al_qura.getParameters();

    // Calculate for today
    final now = DateTime.now();
    final dateComponents = DateComponents.from(now);
    final prayerTimes = PrayerTimes(myCoordinates, dateComponents, params);
    final sunnahTimes = SunnahTimes(prayerTimes);

    // Calculate night duration for third calculations
    final maghribTime = prayerTimes.maghrib;
    final nextFajr = _getNextFajr(myCoordinates, params, now);
    final nightDuration = nextFajr.difference(maghribTime);
    final oneThird = Duration(microseconds: nightDuration.inMicroseconds ~/ 3);
    final firstThirdEnd = maghribTime.add(oneThird);

    return [
      PrayerTime(
        name: 'Fajr',
        arabicName: 'الفجر',
        time: prayerTimes.fajr,
        isPrayer: true,
        iqamahDelay: IqamahConfig.fajr,
      ),
      PrayerTime(
        name: 'Sunrise',
        arabicName: 'الشروق',
        time: prayerTimes.sunrise,
        isPrayer: false,
      ),
      PrayerTime(
        name: 'Dhuhr',
        arabicName: 'الظهر',
        time: prayerTimes.dhuhr,
        isPrayer: true,
        iqamahDelay: IqamahConfig.dhuhr,
      ),
      PrayerTime(
        name: 'Asr',
        arabicName: 'العصر',
        time: prayerTimes.asr,
        isPrayer: true,
        iqamahDelay: IqamahConfig.asr,
      ),
      PrayerTime(
        name: 'Maghrib',
        arabicName: 'المغرب',
        time: prayerTimes.maghrib,
        isPrayer: true,
        iqamahDelay: IqamahConfig.maghrib,
      ),
      PrayerTime(
        name: 'Isha',
        arabicName: 'العشاء',
        time: prayerTimes.isha,
        isPrayer: true,
        iqamahDelay: IqamahConfig.isha,
      ),
      PrayerTime(
        name: 'First Third',
        arabicName: 'الثلث الأول',
        time: firstThirdEnd,
        isPrayer: false,
      ),
      PrayerTime(
        name: 'Midnight',
        arabicName: 'منتصف الليل',
        time: sunnahTimes.middleOfTheNight,
        isPrayer: false,
      ),
      PrayerTime(
        name: 'Last Third',
        arabicName: 'الثلث الأخير',
        time: sunnahTimes.lastThirdOfTheNight,
        isPrayer: false,
      ),
    ];
  }

  DateTime _getNextFajr(
    Coordinates coordinates,
    CalculationParameters params,
    DateTime currentDate,
  ) {
    final nextDay = currentDate.add(const Duration(days: 1));
    final nextDateComponents = DateComponents.from(nextDay);
    final nextPrayerTimes = PrayerTimes(
      coordinates,
      nextDateComponents,
      params,
    );
    return nextPrayerTimes.fajr;
  }

  @override
  PrayerTime? getNextPrayer(List<PrayerTime> prayers, DateTime now) {
    final sorted = List<PrayerTime>.from(prayers)
      ..sort((a, b) => a.time.compareTo(b.time));

    for (final prayer in sorted) {
      if (prayer.time.isAfter(now)) {
        return prayer;
      }
    }
    // Handle "next day" logic in provider or calling code, strictly this returns null if none left today
    return null;
  }
}
