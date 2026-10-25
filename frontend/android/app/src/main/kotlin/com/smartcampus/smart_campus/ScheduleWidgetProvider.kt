package com.smartcampus.smart_campus

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class ScheduleWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            try {
                val views = RemoteViews(context.packageName, R.layout.schedule_widget_layout).apply {
                    val subject = widgetData.getString("widget_subject", "Chưa có môn học") ?: "Chưa có môn học"
                    var time = widgetData.getString("widget_time", "Hôm nay nghỉ") ?: "Hôm nay nghỉ"
                    var room = widgetData.getString("widget_room", "Khuôn viên trường") ?: "Khuôn viên trường"
                    val status = widgetData.getString("widget_status", "Thứ 2 • Ngày mai") ?: "Thứ 2 • Ngày mai"
                    var countdown = widgetData.getString("widget_countdown", "Sắp diễn ra") ?: "Sắp diễn ra"
                    val lecturer = widgetData.getString("widget_lecturer", "Smart Campus TTN") ?: "Smart Campus TTN"

                    if (!time.startsWith("🕒")) {
                        time = "🕒 $time"
                    }
                    if (!room.startsWith("📍")) {
                        room = "📍 $room"
                    }
                    if (!countdown.startsWith("⏱") && !countdown.startsWith("⏳")) {
                        countdown = "⏱ $countdown"
                    }

                    setTextViewText(R.id.widget_status, status)
                    setTextViewText(R.id.widget_subject, subject)
                    setTextViewText(R.id.widget_time, time)
                    setTextViewText(R.id.widget_room, room)
                    setTextViewText(R.id.widget_countdown, countdown)
                    setTextViewText(R.id.widget_lecturer, lecturer)

                    // Click widget opens app
                    val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java
                    )
                    setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }
                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
