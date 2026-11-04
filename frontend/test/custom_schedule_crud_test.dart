import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus/features/schedule/models/schedule_model.dart';

void main() {
  group('ScheduleItem CRUD & Custom Features', () {
    test('ScheduleItem supports custom flag, weekRange, and copyWith', () {
      const item = ScheduleItem(
        id: 101,
        courseName: 'Thực hành Mạng máy tính',
        room: 'Lab 3 - Nhà 7',
        dayOfWeek: 'Thứ 3',
        dayNum: 3,
        timeSlot: 'Tiết 7-10',
        lecturer: 'ThS. Nguyễn Văn A',
        isCustom: true,
        type: 'dot_xuat',
        note: 'Mang theo laptop',
        date: '27/10/2026',
        dateShort: '27/10',
        weekRange: '26/10/2026 - 01/11/2026',
      );

      expect(item.id, 101);
      expect(item.isCustom, isTrue);
      expect(item.weekRange, '26/10/2026 - 01/11/2026');

      final json = item.toJson();
      expect(json['is_custom'], 1);
      expect(json['course_name'], 'Thực hành Mạng máy tính');
      expect(json['room'], 'Lab 3 - Nhà 7');
      expect(json['week_range'], '26/10/2026 - 01/11/2026');

      // Test copyWith (Update)
      final updated = item.copyWith(
        courseName: 'Thực hành Mạng máy tính (Bổ sung)',
        room: 'Lab 5 - Nhà 7',
        timeSlot: 'Tiết 1-4',
      );

      expect(updated.id, 101); // ID preserved
      expect(updated.courseName, 'Thực hành Mạng máy tính (Bổ sung)');
      expect(updated.room, 'Lab 5 - Nhà 7');
      expect(updated.timeSlot, 'Tiết 1-4');
      expect(updated.isCustom, isTrue);
      expect(updated.weekRange, '26/10/2026 - 01/11/2026');
    });

    test('ScheduleItem parses from json including server response with isCustom', () {
      final json = {
        'id': 202,
        'course': 'Kiểm tra Giữa kỳ CSDL',
        'code': 'Thứ 4',
        'time': 'Tiết 1-2',
        'room': 'P.302 - Nhà 6',
        'day': 'Thứ 4',
        'dayNum': 4,
        'lecturer': 'TS. Trần Thị B',
        'isCustom': true,
        'note': 'Thi trắc nghiệm 45 phút',
        'type': 'kiem_tra',
        'date': '28/10/2026',
        'week_range': '26/10/2026 - 01/11/2026',
      };

      final parsed = ScheduleItem.fromJson(json);
      expect(parsed.id, 202);
      expect(parsed.courseName, 'Kiểm tra Giữa kỳ CSDL');
      expect(parsed.isCustom, isTrue);
      expect(parsed.type, 'kiem_tra');
      expect(parsed.dayNum, 4);
      expect(parsed.date, '28/10/2026');
      expect(parsed.weekRange, '26/10/2026 - 01/11/2026');
    });

    test('ScheduleItem.isSameId compares int and String IDs correctly', () {
      const itemInt = ScheduleItem(
        id: 43,
        courseName: 'Test Môn Học',
        room: '2.21',
        dayOfWeek: 'Thứ 2',
        timeSlot: 'Tiết 1-4',
      );

      expect(itemInt.isSameId(43), isTrue);
      expect(itemInt.isSameId('43'), isTrue);
      expect(itemInt.isSameId(44), isFalse);
      expect(itemInt.isSameId('44'), isFalse);
      expect(itemInt.isSameId(null), isFalse);
    });
  });
}

