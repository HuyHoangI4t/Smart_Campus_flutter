package com.smartcampus.smart_campus

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class GpaWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            try {
                val views = RemoteViews(context.packageName, R.layout.gpa_widget_layout).apply {
                    val gpa = widgetData.getString("widget_gpa", "0.00") ?: "0.00"
                    val gpa10 = widgetData.getString("widget_gpa10", "Thang 10: --") ?: "Thang 10: --"
                    val credits = widgetData.getString("widget_credits", "0") ?: "0"
                    var rank = widgetData.getString("widget_rank", "Chưa xét") ?: "Chưa xét"
                    val progressText = widgetData.getString("widget_progress_text", "Chương trình đào tạo") ?: "Chương trình đào tạo"
                    val syncTime = widgetData.getString("widget_sync_time", "✓ Vừa xong") ?: "✓ Vừa xong"

                    val gpaValue = gpa.toDoubleOrNull() ?: 0.0

                    // Logic: Neu diem 0.00 hoac chua co du lieu -> 'Chua xet' voi background xam
                    if (gpaValue <= 0.0 || rank == "Chưa xét" || rank == "Chưa xếp loại" || rank.isEmpty()) {
                        rank = "Chưa xét"
                        setInt(R.id.widget_rank, "setBackgroundResource", R.drawable.widget_tonal_gray_pill)
                        setTextColor(R.id.widget_rank, Color.parseColor("#94A3B8"))
                    } else {
                        setInt(R.id.widget_rank, "setBackgroundResource", R.drawable.widget_tonal_amber_pill)
                        setTextColor(R.id.widget_rank, Color.parseColor("#F59E0B"))
                    }

                    setTextViewText(R.id.widget_rank, rank)
                    setTextViewText(R.id.widget_gpa, gpa)
                    setTextViewText(R.id.widget_gpa10, gpa10)
                    setTextViewText(R.id.widget_credits, credits)
                    setTextViewText(R.id.widget_progress_text, progressText)
                    setTextViewText(R.id.widget_sync_time, syncTime)

                    // Click widget opens app
                    val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java
                    )
                    setOnClickPendingIntent(R.id.widget_gpa_root, pendingIntent)
                }
                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
