import 'package:equatable/equatable.dart';

class PrayerTime extends Equatable {
  final String name;
  final String arabicName;
  final DateTime time;
  final bool isPrayer;
  final Duration? iqamahDelay;

  final String? description;

  const PrayerTime({
    required this.name,
    required this.arabicName,
    required this.time,
    required this.isPrayer,
    this.iqamahDelay,
    this.description,
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
  List<Object?> get props => [
    name,
    arabicName,
    time,
    isPrayer,
    iqamahDelay,
    description,
  ];
}

/// Iqamah delay configuration
class IqamahConfig {
  static const Duration fajr = Duration(minutes: 25);
  static const Duration dhuhr = Duration(minutes: 20);
  static const Duration asr = Duration(minutes: 20);
  static const Duration maghrib = Duration(minutes: 10);
  static const Duration isha = Duration(minutes: 20);
}
