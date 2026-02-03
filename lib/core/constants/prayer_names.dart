/// Centralized prayer name constants to prevent typos and enable refactoring.
abstract class PrayerNames {
  // Compulsory prayers
  static const String fajr = 'Fajr';
  static const String dhuhr = 'Dhuhr';
  static const String asr = 'Asr';
  static const String maghrib = 'Maghrib';
  static const String isha = 'Isha';

  // Additional markers
  static const String sunrise = 'Sunrise';
  static const String firstThird = 'First Third';
  static const String midnight = 'Midnight';
  static const String lastThird = 'Last Third';

  /// List of the 5 compulsory prayers
  static const List<String> compulsoryPrayers = [
    fajr,
    dhuhr,
    asr,
    maghrib,
    isha,
  ];

  /// All time markers including prayers and non-prayer times
  static const List<String> allMarkers = [
    fajr,
    sunrise,
    dhuhr,
    asr,
    maghrib,
    isha,
    firstThird,
    midnight,
    lastThird,
  ];
}
