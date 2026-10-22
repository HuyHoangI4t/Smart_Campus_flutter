package com.smartcampus.smart_campus

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ScheduleWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.schedule_widget_layout).apply {
                val subject = widgetData.getString("widget_subject", "LS Đảng CS VN") ?: "LS Đảng CS VN"
                val time = widgetData.getString("widget_time", "Tiết 1-4") ?: "Tiết 1-4"
                val room = widgetData.getString("widget_room", "2.21 (CLC)") ?: "2.21 (CLC)"
                val status = widgetData.getString("widget_status", "LỚP HỌC HÔM NAY") ?: "LỚP HỌC HÔM NAY"
                val gpa = widgetData.getString("widget_gpa", "3.25") ?: "3.25"
                val credits = widgetData.getString("widget_credits", "85 TC") ?: "85 TC"
                val rank = widgetData.getString("widget_rank", "Khá") ?: "Khá"

                setTextViewText(R.id.widget_status, status)
                setTextViewText(R.id.widget_subject, subject)
                setTextViewText(R.id.widget_time, time)
                setTextViewText(R.id.widget_room, room)
                setTextViewText(R.id.widget_gpa, gpa)
                setTextViewText(R.id.widget_credits, credits)
                setTextViewText(R.id.widget_rank, rank)

                // Click widget opens app
                val intent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_MAIN
                    addCategory(Intent.CATEGORY_LAUNCHER)
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

