package com.example.trying_flutter

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.home_widget_layout).apply {
                val prayerName = widgetData.getString("prayer_name", "Waiting...")
                val prayerTime = widgetData.getString("prayer_time", "--:--")
                val prayerTimeMillis = widgetData.getLong("prayer_time_millis", 0)

                setTextViewText(R.id.prayer_name, prayerName)
                setTextViewText(R.id.prayer_time, prayerTime)

                if (prayerTimeMillis > 0) {
                    // Set chronometer base to the target time
                    // For countdown, we need to set base relative to realtime
                    val timeDiff = prayerTimeMillis - System.currentTimeMillis()
                    if (timeDiff > 0) {
                        setChronometer(R.id.prayer_timer, android.os.SystemClock.elapsedRealtime() + timeDiff, null, true)
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                            setChronometerCountDown(R.id.prayer_timer, true)
                        }
                    } else {
                         setTextViewText(R.id.prayer_timer, "Now")
                    }
                } else {
                    setTextViewText(R.id.prayer_timer, "")
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
