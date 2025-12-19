import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';

class HomeWidgetService {
  static const String appGroupId = 'group.com.example.trying_flutter';
  static const String androidWidgetName = 'PrayerWidgetProvider';

  static Future<void> updatePrayerData(
    String prayerName,
    String time,
    int nextPrayerTimeMillis,
  ) async {
    try {
      await HomeWidget.saveWidgetData<String>('prayer_name', prayerName);
      await HomeWidget.saveWidgetData<String>('prayer_time', time);
      await HomeWidget.saveWidgetData<int>(
        'prayer_time_millis',
        nextPrayerTimeMillis,
      );
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: 'PrayerWidget', // Placeholder for iOS
      );
    } catch (e) {
      debugPrint('Error updating home widget: $e');
    }
  }
}
