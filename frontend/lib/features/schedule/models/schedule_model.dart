import 'room_direction_model.dart';
import '../utils/room_directions.dart';

enum ScheduleStatus {
  ongoing,
  upcoming,
  completed,
}

class ScheduleItem {
  final int id;
  final String courseName;
  final String room;
  final String dayOfWeek;
  final String timeSlot;
  final String? lecturer;
  final bool isCustom;
  final String? code;
  final String? note;
  final String? type;
  final RoomDirectionInfo? direction;

  final int dayNum;
  final String? date;
  final String? dateShort;
  final String? status;
  final String? statusLabel;
  final int? startMinutesRaw;
  final int? endMinutesRaw;

  String get subject => courseName;
  String get courseCode => code ?? 'HP${id.toString().padLeft(3, '0')}';
  RoomDirectionInfo get roomDirection => direction ?? parseRoomDirections(room);

  static int dayStrToNum(String dayStr) {
    final lower = dayStr.toLowerCase().trim();
    if (lower.contains('thứ 3') || lower.contains('thứ ba') || lower == '3') return 3;
    if (lower.contains('thứ 4') || lower.contains('thứ tư') || lower == '4') return 4;
    if (lower.contains('thứ 5') || lower.contains('thứ năm') || lower == '5') return 5;
    if (lower.contains('thứ 6') || lower.contains('thứ sáu') || lower == '6') return 6;
    if (lower.contains('thứ 7') || lower.contains('thứ bảy') || lower == '7') return 7;
    if (lower.contains('cn') || lower.contains('chủ nhật') || lower == '1' || lower == '8') return 1;
    return 2;
  }

  String get cleanDay {
    final lower = dayOfWeek.toLowerCase().trim();
    if (lower.contains('thứ 2') || lower.contains('thứ hai')) return 'Thứ 2';
    if (lower.contains('thứ 3') || lower.contains('thứ ba')) return 'Thứ 3';
    if (lower.contains('thứ 4') || lower.contains('thứ tư')) return 'Thứ 4';
    if (lower.contains('thứ 5') || lower.contains('thứ năm')) return 'Thứ 5';
    if (lower.contains('thứ 6') || lower.contains('thứ sáu')) return 'Thứ 6';
    if (lower.contains('thứ 7') || lower.contains('thứ bảy')) return 'Thứ 7';
    if (lower.contains('cn') || lower.contains('chủ nhật')) return 'CN';
    if (dayNum == 3) return 'Thứ 3';
    if (dayNum == 4) return 'Thứ 4';
    if (dayNum == 5) return 'Thứ 5';
    if (dayNum == 6) return 'Thứ 6';
    if (dayNum == 7) return 'Thứ 7';
    if (dayNum == 1) return 'CN';
    return 'Thứ 2';
  }

  bool matchesDay(String day) {
    final target = day.trim().toLowerCase();
    final cDay = cleanDay.toLowerCase();
    if (target == cDay) return true;
    if ((target == 'chủ nhật' || target == 'cn') && (cDay == 'cn' || cDay == 'chủ nhật')) return true;
    if (dayOfWeek.toLowerCase().contains(target)) return true;
    if (target.contains(cDay)) return true;
    return false;
  }

  const ScheduleItem({
    required this.id,
    required this.courseName,
    required this.room,
    required this.dayOfWeek,
    this.dayNum = 2,
    required this.timeSlot,
    this.lecturer,
    this.isCustom = false,
    this.code,
    this.note,
    this.type,
    this.direction,
    this.date,
    this.dateShort,
    this.status,
    this.statusLabel,
    this.startMinutesRaw,
    this.endMinutesRaw,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    final rawDayNum = json['dayNum'] ?? json['day_num'];
    int parsedDayNum = 2;
    if (rawDayNum is int) {
      parsedDayNum = rawDayNum;
    } else if (rawDayNum != null) {
      parsedDayNum = int.tryParse(rawDayNum.toString()) ?? 2;
    } else {
      final rawDay = (json['day'] ?? json['thu'] ?? '').toString().toLowerCase();
      if (rawDay.contains('thứ 3')) {
        parsedDayNum = 3;
      } else if (rawDay.contains('thứ 4')) {
        parsedDayNum = 4;
      } else if (rawDay.contains('thứ 5')) {
        parsedDayNum = 5;
      } else if (rawDay.contains('thứ 6')) {
        parsedDayNum = 6;
      } else if (rawDay.contains('thứ 7')) {
        parsedDayNum = 7;
      } else if (rawDay.contains('cn') || rawDay.contains('chủ nhật')) {
        parsedDayNum = 1;
      } else {
        parsedDayNum = 2;
      }
    }

    return ScheduleItem(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      courseName: json['course'] ??
          json['course_name'] ??
          json['subject'] ??
          json['ten_hp'] ??
          json['courseName'] ??
          '',
      room: json['room'] ?? json['phong'] ?? '',
      dayOfWeek: json['day'] ??
          json['day_of_week'] ??
          json['dayOfWeek'] ??
          json['thu'] ??
          'Thứ 2',
      dayNum: parsedDayNum,
      timeSlot: json['time'] ??
          json['time_slot'] ??
          json['timeSlot'] ??
          json['tiet'] ??
          '07:00 - 09:15',
      lecturer: json['lecturer'] ?? json['teacher'] ?? json['giang_vien'],
      isCustom: json['is_custom'] == 1 ||
          json['is_custom'] == true ||
          json['isCustom'] == true,
      code: json['code'] ?? json['ma_hp'],
      note: json['note']?.toString() ?? json['ghi_chu']?.toString(),
      type: json['type']?.toString() ?? json['loai_lich']?.toString(),
      direction: json['direction'] != null && json['direction'] is Map<String, dynamic>
          ? RoomDirectionInfo.fromJson(json['direction'])
          : parseRoomDirections(json['room'] ?? json['phong'] ?? ''),
      date: json['date']?.toString(),
      dateShort: json['dateShort']?.toString() ?? json['date_short']?.toString(),
      status: json['status']?.toString(),
      statusLabel: json['statusLabel']?.toString() ?? json['status_label']?.toString(),
      startMinutesRaw: json['startMinutes'] is int
          ? json['startMinutes'] as int
          : (json['start_minutes'] is int ? json['start_minutes'] as int : null),
      endMinutesRaw: json['endMinutes'] is int
          ? json['endMinutes'] as int
          : (json['end_minutes'] is int ? json['end_minutes'] as int : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_name': courseName,
      'ten_hp': courseName,
      'subject': courseName,
      'course': courseName,
      'room': room,
      'phong': room,
      'day_of_week': dayOfWeek,
      'thu': dayOfWeek,
      'day': dayOfWeek,
      'time_slot': timeSlot,
      'tiet': timeSlot,
      'time': timeSlot,
      'lecturer': lecturer,
      'giang_vien': lecturer,
      'is_custom': isCustom ? 1 : 0,
      'note': note,
      'ghi_chu': note,
      'type': type ?? 'dot_xuat',
      'loai_lich': type ?? 'dot_xuat',
    };
  }

  /// Phân tích giờ bắt đầu và kết thúc theo chuẩn tiết học TTN
  int get startMinutes {
    if (startMinutesRaw != null && startMinutesRaw! > 0) return startMinutesRaw!;
    return _calculatePeriodMinutes(timeSlot).start;
  }

  int get endMinutes {
    if (endMinutesRaw != null && endMinutesRaw! > 0) return endMinutesRaw!;
    return _calculatePeriodMinutes(timeSlot).end;
  }

  String get startTime {
    final h = (startMinutes ~/ 60).toString().padLeft(2, '0');
    final m = (startMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  static ({int start, int end}) _calculatePeriodMinutes(String timeStr) {
    final str = timeStr.trim();
    final timeMatch = RegExp(r'(\d{1,2}):(\d{2})\s*[-–—]\s*(\d{1,2}):(\d{2})').firstMatch(str);
    if (timeMatch != null) {
      final s = int.parse(timeMatch.group(1)!) * 60 + int.parse(timeMatch.group(2)!);
      final e = int.parse(timeMatch.group(3)!) * 60 + int.parse(timeMatch.group(4)!);
      return (start: s, end: e);
    }
    final rangeMatch = RegExp(r'(\d+)\s*[-–—]\s*(\d+)').firstMatch(str);
    if (rangeMatch != null) {
      final s = int.parse(rangeMatch.group(1)!);
      final e = int.parse(rangeMatch.group(2)!);
      return (
        start: _periodStart(s),
        end: _periodEnd(e),
      );
    }
    final singleMatch = RegExp(r'tiết\s*(\d+)', caseSensitive: false).firstMatch(str);
    if (singleMatch != null) {
      final p = int.parse(singleMatch.group(1)!);
      return (
        start: _periodStart(p),
        end: _periodEnd(p),
      );
    }
    return (start: 6 * 60 + 45, end: 10 * 60 + 30);
  }

  static int _periodStart(int p) {
    switch (p) {
      case 1:
        return 6 * 60 + 45; // 06:45
      case 2:
        return 7 * 60 + 40; // 07:40
      case 3:
        return 8 * 60 + 40; // 08:40
      case 4:
        return 9 * 60 + 35; // 09:35
      case 5:
        return 10 * 60 + 35; // 10:35
      case 6:
        return 12 * 60 + 50; // 12:50
      case 7:
        return 13 * 60 + 45; // 13:45
      case 8:
        return 14 * 60 + 40; // 14:40
      case 9:
        return 15 * 60 + 40; // 15:40
      case 10:
        return 16 * 60 + 35; // 16:35
      case 11:
        return 17 * 60 + 30; // 17:30
      case 12:
        return 18 * 60 + 25; // 18:25
      case 13:
        return 19 * 60 + 20; // 19:20
      default:
        return p >= 6 ? 13 * 60 + 45 : 6 * 60 + 45;
    }
  }

  static int _periodEnd(int p) {
    switch (p) {
      case 1:
        return 7 * 60 + 35;
      case 2:
        return 8 * 60 + 30;
      case 3:
        return 9 * 60 + 30;
      case 4:
        return 10 * 60 + 30; // 10:30 kết thúc
      case 5:
        return 11 * 60 + 25;
      case 6:
        return 13 * 60 + 40;
      case 7:
        return 14 * 60 + 35;
      case 8:
        return 15 * 60 + 30;
      case 9:
        return 16 * 60 + 30; // 16:30 kết thúc
      case 10:
        return 17 * 60 + 25;
      case 11:
        return 18 * 60 + 20;
      case 12:
        return 19 * 60 + 15;
      case 13:
        return 20 * 60 + 10;
      default:
        return p >= 6 ? 16 * 60 + 30 : 10 * 60 + 30;
    }
  }

  ScheduleStatus getScheduleStatus({String? targetDateStr, DateTime? nowTime}) {
    final now = nowTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? classDate;
    final dateToParse = targetDateStr ?? date;
    if (dateToParse != null && dateToParse.isNotEmpty) {
      final parts = dateToParse.trim().split('/');
      if (parts.length >= 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          classDate = DateTime(y, m, d);
        }
      } else if (parts.length == 2) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (d != null && m != null) {
          classDate = DateTime(now.year, m, d);
        }
      }
    }

    if (classDate != null) {
      if (classDate.isBefore(today)) {
        return ScheduleStatus.completed;
      }
      if (classDate.isAfter(today)) {
        return ScheduleStatus.upcoming;
      }
    }

    final currentMinutes = now.hour * 60 + now.minute;
    if (currentMinutes < startMinutes) {
      return ScheduleStatus.upcoming;
    } else if (currentMinutes <= endMinutes) {
      return ScheduleStatus.ongoing;
    } else {
      return ScheduleStatus.completed;
    }
  }
}

