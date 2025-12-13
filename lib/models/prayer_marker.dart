/// Represents a prayer or time marker with its associated data.
class PrayerMarker {
  final String name;
  final String arabicName;
  final DateTime time;
  final bool isPrayer; // true for prayers, false for markers like sunrise
  final Duration? iqamahDelay; // Only for prayers that have iqamah

  const PrayerMarker({
    required this.name,
    required this.arabicName,
    required this.time,
    required this.isPrayer,
    this.iqamahDelay,
  });

  /// Get iqamah time if applicable
  DateTime? get iqamahTime {
    if (iqamahDelay == null) return null;
    return time.add(iqamahDelay!);
  }

  /// Check if current time is within this prayer's adhan-to-iqamah window
  bool isInIqamahWindow(DateTime now) {
    if (iqamahDelay == null) return false;
    return now.isAfter(time) && now.isBefore(iqamahTime!);
  }

  /// Check if this prayer/marker has passed
  bool hasPassed(DateTime now) => now.isAfter(time);

  @override
  String toString() => '$name: $time';
}

/// Iqamah delay configuration for each prayer
class IqamahConfig {
  static const Duration fajr = Duration(minutes: 25);
  static const Duration dhuhr = Duration(minutes: 20);
  static const Duration asr = Duration(minutes: 20);
  static const Duration maghrib = Duration(minutes: 10);
  static const Duration isha = Duration(minutes: 20);

  static Duration? forPrayer(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return fajr;
      case 'dhuhr':
        return dhuhr;
      case 'asr':
        return asr;
      case 'maghrib':
        return maghrib;
      case 'isha':
        return isha;
      default:
        return null;
    }
  }
}
