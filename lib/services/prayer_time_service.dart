import 'package:adhan/adhan.dart';
import '../models/prayer_marker.dart';

/// Service for calculating prayer times using the adhan package.
class PrayerTimeService {
  // Default coordinates (Madinah)
  static const double defaultLatitude = 24.48;
  static const double defaultLongitude = 39.55;

  late Coordinates _coordinates;
  late CalculationParameters _params;

  PrayerTimeService({double? latitude, double? longitude}) {
    _coordinates = Coordinates(
      latitude ?? defaultLatitude,
      longitude ?? defaultLongitude,
    );
    // Using Umm Al-Qura calculation method
    _params = CalculationMethod.umm_al_qura.getParameters();
  }

  /// Update coordinates (e.g., after getting user location)
  void updateCoordinates(double latitude, double longitude) {
    _coordinates = Coordinates(latitude, longitude);
  }

  /// Get all prayer times and markers for a specific date
  List<PrayerMarker> getMarkersForDate(DateTime date) {
    final dateComponents = DateComponents.from(date);
    final prayerTimes = PrayerTimes(_coordinates, dateComponents, _params);
    final sunnahTimes = SunnahTimes(prayerTimes);

    // Calculate night duration for third calculations
    final maghribTime = prayerTimes.maghrib;
    final nextFajr = _getNextFajr(date);
    final nightDuration = nextFajr.difference(maghribTime);
    final oneThird = Duration(microseconds: nightDuration.inMicroseconds ~/ 3);
    final firstThirdEnd = maghribTime.add(oneThird);

    return [
      PrayerMarker(
        name: 'Fajr',
        arabicName: 'الفجر',
        time: prayerTimes.fajr,
        isPrayer: true,
        iqamahDelay: IqamahConfig.fajr,
      ),
      PrayerMarker(
        name: 'Sunrise',
        arabicName: 'الشروق',
        time: prayerTimes.sunrise,
        isPrayer: false,
      ),
      PrayerMarker(
        name: 'Dhuhr',
        arabicName: 'الظهر',
        time: prayerTimes.dhuhr,
        isPrayer: true,
        iqamahDelay: IqamahConfig.dhuhr,
      ),
      PrayerMarker(
        name: 'Asr',
        arabicName: 'العصر',
        time: prayerTimes.asr,
        isPrayer: true,
        iqamahDelay: IqamahConfig.asr,
      ),
      PrayerMarker(
        name: 'Maghrib',
        arabicName: 'المغرب',
        time: prayerTimes.maghrib,
        isPrayer: true,
        iqamahDelay: IqamahConfig.maghrib,
      ),
      PrayerMarker(
        name: 'Isha',
        arabicName: 'العشاء',
        time: prayerTimes.isha,
        isPrayer: true,
        iqamahDelay: IqamahConfig.isha,
      ),
      PrayerMarker(
        name: 'First Third',
        arabicName: 'الثلث الأول',
        time: firstThirdEnd,
        isPrayer: false,
      ),
      PrayerMarker(
        name: 'Midnight',
        arabicName: 'منتصف الليل',
        time: sunnahTimes.middleOfTheNight,
        isPrayer: false,
      ),
      PrayerMarker(
        name: 'Last Third',
        arabicName: 'الثلث الأخير',
        time: sunnahTimes.lastThirdOfTheNight,
        isPrayer: false,
      ),
    ];
  }

  /// Get next Fajr time (for night calculations)
  DateTime _getNextFajr(DateTime currentDate) {
    final nextDay = currentDate.add(const Duration(days: 1));
    final nextDateComponents = DateComponents.from(nextDay);
    final nextPrayerTimes = PrayerTimes(
      _coordinates,
      nextDateComponents,
      _params,
    );
    return nextPrayerTimes.fajr;
  }

  /// Get the current prayer status - which prayer period we're in
  /// and the next upcoming prayer/marker
  PrayerStatus getCurrentStatus(DateTime now) {
    final todayMarkers = getMarkersForDate(now);
    final yesterdayMarkers = getMarkersForDate(
      now.subtract(const Duration(days: 1)),
    );

    // Combine today's and yesterday's night markers for proper night handling
    final allMarkers = [...yesterdayMarkers, ...todayMarkers];
    allMarkers.sort((a, b) => a.time.compareTo(b.time));

    // Find the current and next marker
    PrayerMarker? current;
    PrayerMarker? next;

    for (int i = 0; i < allMarkers.length; i++) {
      if (allMarkers[i].time.isAfter(now)) {
        next = allMarkers[i];
        if (i > 0) {
          current = allMarkers[i - 1];
        }
        break;
      }
    }

    // Handle case where we're past all markers (use first of tomorrow)
    if (next == null && allMarkers.isNotEmpty) {
      final tomorrowMarkers = getMarkersForDate(
        now.add(const Duration(days: 1)),
      );
      next = tomorrowMarkers.first;
      current = allMarkers.last;
    }

    return PrayerStatus(currentMarker: current, nextMarker: next, now: now);
  }
}

/// Represents the current prayer status
class PrayerStatus {
  final PrayerMarker? currentMarker;
  final PrayerMarker? nextMarker;
  final DateTime now;

  PrayerStatus({this.currentMarker, this.nextMarker, required this.now});

  /// Time since current marker started
  Duration get timeSinceCurrent {
    if (currentMarker == null) return Duration.zero;
    return now.difference(currentMarker!.time);
  }

  /// Time until next marker
  Duration get timeUntilNext {
    if (nextMarker == null) return Duration.zero;
    return nextMarker!.time.difference(now);
  }

  /// Check if we're in the countup period (prayer just passed, within 1 hour)
  bool get isInCountupPeriod {
    if (currentMarker == null || !currentMarker!.isPrayer) return false;
    return timeSinceCurrent.inMinutes < 60;
  }

  /// Check if we're in the iqamah countdown period
  bool get isInIqamahPeriod {
    if (currentMarker == null) return false;
    return currentMarker!.isInIqamahWindow(now);
  }

  /// Time until iqamah (if in iqamah period)
  Duration get timeUntilIqamah {
    if (!isInIqamahPeriod || currentMarker?.iqamahTime == null) {
      return Duration.zero;
    }
    return currentMarker!.iqamahTime!.difference(now);
  }
}
