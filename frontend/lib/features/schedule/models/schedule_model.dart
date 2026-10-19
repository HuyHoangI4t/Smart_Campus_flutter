class ScheduleItem {
  final int id;
  final String courseName;
  final String room;
  final String dayOfWeek;
  final String timeSlot;
  final String? lecturer;
  final bool isCustom;
  final String? code;

  String get subject => courseName;
  String get courseCode => code ?? 'HP${id.toString().padLeft(3, '0')}';

  const ScheduleItem({
    required this.id,
    required this.courseName,
    required this.room,
    required this.dayOfWeek,
    required this.timeSlot,
    this.lecturer,
    this.isCustom = false,
    this.code,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      courseName: json['course_name'] ?? json['subject'] ?? json['courseName'] ?? '',
      room: json['room'] ?? '',
      dayOfWeek: json['day_of_week'] ?? json['dayOfWeek'] ?? 'Thứ 2',
      timeSlot: json['time_slot'] ?? json['timeSlot'] ?? '07:00 - 09:15',
      lecturer: json['lecturer'] ?? json['teacher'],
      isCustom: json['is_custom'] == 1 || json['isCustom'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_name': courseName,
      'room': room,
      'day_of_week': dayOfWeek,
      'time_slot': timeSlot,
      'lecturer': lecturer,
      'is_custom': isCustom ? 1 : 0,
    };
  }

  /// Phân tích giờ bắt đầu và kết thúc (ví dụ: '07:00 - 09:15' -> 7*60 = 420 phút)
  int get startMinutes {
    try {
      final parts = timeSlot.split('-');
      if (parts.isNotEmpty) {
        final timeParts = parts[0].trim().split(':');
        if (timeParts.length >= 2) {
          final h = int.parse(timeParts[0]);
          final m = int.parse(timeParts[1]);
          return h * 60 + m;
        }
      }
    } catch (_) {}
    return 7 * 60; // Mặc định 07:00
  }

  int get endMinutes {
    try {
      final parts = timeSlot.split('-');
      if (parts.length >= 2) {
        final timeParts = parts[1].trim().split(':');
        if (timeParts.length >= 2) {
          final h = int.parse(timeParts[0]);
          final m = int.parse(timeParts[1]);
          return h * 60 + m;
        }
      }
    } catch (_) {}
    return startMinutes + 135; // Mặc định 2h15p
  }
}

