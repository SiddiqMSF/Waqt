import 'package:equatable/equatable.dart';

/// Represents a user-configured prayer alarm.
///
/// Alarms are scheduled relative to prayer times using an offset.
/// Negative offset = before prayer time, positive = after.
class PrayerAlarm extends Equatable {
  /// Unique identifier for this alarm (used by alarm package)
  final int id;

  /// The prayer/marker name this alarm is relative to (e.g., "Fajr", "Last Third")
  final String prayerName;

  /// Offset from prayer time. Negative = before, positive = after.
  /// Example: Duration(minutes: -30) means 30 minutes before prayer.
  final Duration offset;

  /// Label for display (e.g., "30 min before Fajr")
  final String label;

  /// Whether this alarm is currently enabled
  final bool isEnabled;

  /// Whether to vibrate when alarm triggers
  final bool vibrate;

  /// Volume level (0.0 to 1.0)
  final double volume;

  const PrayerAlarm({
    required this.id,
    required this.prayerName,
    required this.offset,
    required this.label,
    this.isEnabled = true,
    this.vibrate = true,
    this.volume = 0.8,
  });

  /// Creates a copy with updated fields
  PrayerAlarm copyWith({
    int? id,
    String? prayerName,
    Duration? offset,
    String? label,
    bool? isEnabled,
    bool? vibrate,
    double? volume,
  }) {
    return PrayerAlarm(
      id: id ?? this.id,
      prayerName: prayerName ?? this.prayerName,
      offset: offset ?? this.offset,
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
      vibrate: vibrate ?? this.vibrate,
      volume: volume ?? this.volume,
    );
  }

  /// Calculate the actual alarm DateTime given a prayer time
  DateTime calculateAlarmTime(DateTime prayerTime) {
    return prayerTime.add(offset);
  }

  /// Generate a human-readable label from offset and prayer name
  static String generateLabel(String prayerName, Duration offset) {
    final minutes = offset.inMinutes.abs();
    final direction = offset.isNegative ? 'before' : 'after';

    if (minutes == 0) {
      return 'At $prayerName';
    } else if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours hr $direction $prayerName';
      }
      return '$hours hr $remainingMinutes min $direction $prayerName';
    } else {
      return '$minutes min $direction $prayerName';
    }
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prayerName': prayerName,
      'offsetMinutes': offset.inMinutes,
      'label': label,
      'isEnabled': isEnabled,
      'vibrate': vibrate,
      'volume': volume,
    };
  }

  /// Create from JSON
  factory PrayerAlarm.fromJson(Map<String, dynamic> json) {
    return PrayerAlarm(
      id: json['id'] as int,
      prayerName: json['prayerName'] as String,
      offset: Duration(minutes: json['offsetMinutes'] as int),
      label: json['label'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      vibrate: json['vibrate'] as bool? ?? true,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.8,
    );
  }

  @override
  List<Object?> get props => [
    id,
    prayerName,
    offset,
    label,
    isEnabled,
    vibrate,
    volume,
  ];
}
