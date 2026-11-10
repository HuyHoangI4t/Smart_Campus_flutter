import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../models/schedule_model.dart';

class ScheduleDayBar extends StatelessWidget {
  final int selectedDay;
  final int todayDayNum;
  final bool isViewingCurrentWeek;
  final List<Map<String, String>> days;
  final Map<int, int> classCountPerDay;
  final ValueChanged<int> onSelectDay;

  const ScheduleDayBar({
    super.key,
    required this.selectedDay,
    required this.todayDayNum,
    required this.isViewingCurrentWeek,
    required this.days,
    this.classCountPerDay = const {},
    required this.onSelectDay,
  });

  String _getShortDay(String fullDay) {
    final lower = fullDay.toLowerCase().trim();
    if (lower.contains('thứ 2') || lower.contains('thứ hai')) return 'T2';
    if (lower.contains('thứ 3') || lower.contains('thứ ba')) return 'T3';
    if (lower.contains('thứ 4') || lower.contains('thứ tư')) return 'T4';
    if (lower.contains('thứ 5') || lower.contains('thứ năm')) return 'T5';
    if (lower.contains('thứ 6') || lower.contains('thứ sáu')) return 'T6';
    if (lower.contains('thứ 7') || lower.contains('thứ bảy')) return 'T7';
    if (lower.contains('cn') || lower.contains('chủ nhật')) return 'CN';
    return fullDay;
  }

  String _extractDayNumber(String dateStr) {
    if (dateStr.isEmpty) return '';
    final parts = dateStr.split('/');
    if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
      return parts[0].trim();
    }
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: List.generate(days.length, (idx) {
          final d = days[idx];
          final rawDay = d['day'] ?? 'Thứ ${idx + 2}';
          final dayNum = ScheduleItem.dayStrToNum(rawDay);
          final shortDay = _getShortDay(rawDay);
          final dateNum = _extractDayNumber(d['date'] ?? '');
          final isSelected = selectedDay == dayNum;
          final isToday = isViewingCurrentWeek && todayDayNum == dayNum;
          final count = classCountPerDay[dayNum] ?? 0;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: idx < days.length - 1 ? 4 : 0),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSelectDay(dayNum);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isToday ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isToday ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0)),
                      width: isToday && !isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.28),
                              offset: const Offset(0, 3),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Thứ (T2, T3, CN...) - Cố định baseline thẳng hàng
                      Text(
                        shortDay,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.85)
                              : (isToday ? AppColors.primary : const Color(0xFF64748B)),
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Ngày trong tháng (02, 03...) - Cố định baseline thẳng hàng tuyệt đối
                      Text(
                        dateNum.isNotEmpty ? dateNum : '—',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : (isToday ? AppColors.primary : const Color(0xFF0F172A)),
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Slot indicator - Luôn cố định chiều cao 12px để số ngày không bị giật baseline
                      SizedBox(
                        height: 12,
                        child: Center(
                          child: count > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 0.5),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFF59E0B)
                                        : (isToday ? AppColors.primary : const Color(0xFF0284C7)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                  ),
                                )
                              : (isToday
                                  ? Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.white : AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : const SizedBox(height: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

