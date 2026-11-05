import 'package:flutter/material.dart';

class ScheduleDateUtils {
  ScheduleDateUtils._();

  static String pad2(int n) => n.toString().padLeft(2, '0');

  /// 1: Chủ nhật, 2: Thứ 2, 3: Thứ 3, ..., 7: Thứ 7
  static int getTodayDayNum([DateTime? date]) {
    final d = date ?? DateTime.now();
    return d.weekday == 7 ? 1 : d.weekday + 1;
  }

  static String formatDateVN(DateTime d) {
    return '${pad2(d.day)}/${pad2(d.month)}/${d.year}';
  }

  static String formatDateShort(DateTime d) {
    return '${pad2(d.day)}/${pad2(d.month)}';
  }

  static DateTime? parseDateVN(String str) {
    if (str.isEmpty) return null;
    final s = str.trim();
    final m1 = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(s);
    if (m1 != null) {
      return DateTime(
        int.parse(m1.group(3)!),
        int.parse(m1.group(2)!),
        int.parse(m1.group(1)!),
        12,
      );
    }
    final m2 = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(s);
    if (m2 != null) {
      return DateTime(
        int.parse(m2.group(1)!),
        int.parse(m2.group(2)!),
        int.parse(m2.group(3)!),
        12,
      );
    }
    return null;
  }

  /// Trích xuất ngày bắt đầu và kết thúc từ chuỗi tuần:
  /// "Từ ngày dd/MM/yyyy đến ngày dd/MM/yyyy"
  static DateTimeRange? parseWeekRangeDates(String rangeText) {
    if (rangeText.isEmpty) return null;
    final reg = RegExp(
      r'Từ ngày\s+(\d{1,2})\/(\d{1,2})\/(\d{4})\s+đến ngày\s+(\d{1,2})\/(\d{1,2})\/(\d{4})',
      caseSensitive: false,
    );
    final match = reg.firstMatch(rangeText);
    if (match == null) {
      // Thử regex dạng đơn giản hơn: hai ngày phân tách
      final dates = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})').allMatches(rangeText).toList();
      if (dates.length >= 2) {
        final start = DateTime(
          int.parse(dates[0].group(3)!),
          int.parse(dates[0].group(2)!),
          int.parse(dates[0].group(1)!),
        );
        final end = DateTime(
          int.parse(dates[1].group(3)!),
          int.parse(dates[1].group(2)!),
          int.parse(dates[1].group(1)!),
          23,
          59,
          59,
        );
        return DateTimeRange(start: start, end: end);
      }
      return null;
    }

    final start = DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
    );
    final end = DateTime(
      int.parse(match.group(6)!),
      int.parse(match.group(5)!),
      int.parse(match.group(4)!),
      23,
      59,
      59,
    );
    return DateTimeRange(start: start, end: end);
  }

  /// Tính thứ 2 của tuần chứa ngày d
  static DateTime getMondayOfWeek(DateTime d) {
    final distToMon = (d.weekday - 1) % 7;
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: distToMon));
  }

  /// Sinh chuỗi: "Từ ngày dd/MM/yyyy đến ngày dd/MM/yyyy"
  static String getWeekRangeFromDate(DateTime d) {
    final mon = getMondayOfWeek(d);
    final sun = mon.add(const Duration(days: 6));
    return 'Từ ngày ${formatDateVN(mon)} đến ngày ${formatDateVN(sun)}';
  }

  /// Sinh danh sách 7 ngày trong tuần từ Thứ 2 tới Chủ nhật
  static List<Map<String, String>> generateWeekDays(DateTime mon) {
    final dayNames = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
    return List.generate(7, (i) {
      final d = mon.add(Duration(days: i));
      return {
        'day': dayNames[i],
        'date': formatDateShort(d),
        'fullDate': formatDateVN(d),
      };
    });
  }

  /// Sinh danh sách các tuần khả dụng linh hoạt quanh ngày hiện tại hoặc chuỗi mốc
  static List<Map<String, dynamic>> generateDefaultAvailableWeeks([String? baseRangeText]) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 12);
    DateTime anchorMonday = getMondayOfWeek(now);

    if (baseRangeText != null && baseRangeText.isNotEmpty) {
      final parsed = parseWeekRangeDates(baseRangeText);
      if (parsed != null) {
        anchorMonday = getMondayOfWeek(parsed.start);
      }
    }

    final offsets = [-1, 0, 1, 2, 3];
    return offsets.map((off) {
      final wMon = anchorMonday.add(Duration(days: off * 7));
      final wSun = wMon.add(const Duration(days: 6));
      final weekRange = 'Từ ngày ${formatDateVN(wMon)} đến ngày ${formatDateVN(wSun)}';

      final isCurrent = today.isAfter(wMon.subtract(const Duration(seconds: 1))) &&
          today.isBefore(wSun.add(const Duration(days: 1)));
      final isNext = !isCurrent &&
          today.isBefore(wMon) &&
          wMon.difference(today).inDays <= 7;
      final isPrev = !isCurrent &&
          today.isAfter(wSun) &&
          today.difference(wSun).inDays <= 7;

      String label;
      if (isCurrent) {
        label = 'Tuần này';
      } else if (isNext) {
        label = 'Tuần sau';
      } else if (isPrev) {
        label = 'Tuần trước';
      } else if (off == 2) {
        label = '2 tuần sau';
      } else {
        label = 'Tuần ${off + 1}';
      }

      final sStr = formatDateShort(wMon);
      final eStr = formatDateShort(wSun);

      return {
        'index': off + 1, // Tuần trước: 0, Tuần này: 1, Tuần sau: 2, 2 tuần sau: 3, ...
        'offset': off,
        'label': '$label ($sStr - $eStr)',
        'weekRange': weekRange,
        'isCurrent': isCurrent,
        'isNext': isNext,
        'startDate': wMon,
      };
    }).toList();
  }
}
