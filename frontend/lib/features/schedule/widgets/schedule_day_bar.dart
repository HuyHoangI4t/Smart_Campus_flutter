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

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSelectDay(dayNum);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isToday ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(14),
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
                              offset: const Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Thứ (T2, T3, CN...)
                      Text(
                        shortDay,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.85)
                              : (isToday ? AppColors.primary : AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Ngày trong tháng (e.g. 19, 20, 21...)
                      Text(
                        dateNum.isNotEmpty ? dateNum : '—',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : (isToday ? AppColors.primary : AppColors.textForeground),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Badge số môn học hoặc Dot chỉ báo hôm nay
                      if (count > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF59E0B)
                                : (isToday ? AppColors.primary : const Color(0xFF0284C7)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        )
                      else if (isToday)
                        Container(
                          width: 4.5,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 12),
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

