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

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isToday ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isToday ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0)),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : (isToday ? AppColors.primary : AppColors.textForeground),
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Dot chỉ báo hôm nay hoặc badge số môn học
                      if (count > 0)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFBBF24)
                                : (isToday ? AppColors.primary : const Color(0xFF0284C7)),
                            shape: BoxShape.circle,
                          ),
                        )
                      else if (isToday)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 5),
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

