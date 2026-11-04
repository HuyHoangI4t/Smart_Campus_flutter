import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_campus/core/storage/secure_storage_service.dart';
import 'package:smart_campus/features/grades/models/grade_model.dart';
import 'package:smart_campus/features/home/models/news_model.dart';
import 'package:smart_campus/features/schedule/models/schedule_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Cache Serialization & Storage Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('StorageService saves and retrieves cache correctly', () async {
      final storage = StorageService();
      await storage.saveCache('test_key', jsonEncode({'hello': 'world'}));

      final cached = await storage.getCache('test_key');
      expect(cached, isNotNull);
      final decoded = jsonDecode(cached!) as Map<String, dynamic>;
      expect(decoded['hello'], equals('world'));
    });

    test('NewsModel toJson & fromJson roundtrip for offline caching', () {
      const model = NewsModel(
        id: 'ann-123',
        title: 'Thông báo thi học kỳ',
        summary: 'Nội dung thông báo tóm tắt',
        category: 'Thông báo sinh viên',
        publishedAt: '04/11/2026',
      );

      final json = model.toJson();
      final roundtrip = NewsModel.fromJson(json);

      expect(roundtrip.id, equals('ann-123'));
      expect(roundtrip.title, equals('Thông báo thi học kỳ'));
      expect(roundtrip.category, equals('Thông báo sinh viên'));
    });

    test('GradeItem toJson & fromJson roundtrip for offline caching', () {
      const item = GradeItem(
        id: 101,
        courseCode: 'TIN101',
        courseName: 'Lập trình ứng dụng di động',
        credits: 3,
        scoreOverall: 8.5,
        letter: 'A',
      );

      final json = item.toJson();
      final roundtrip = GradeItem.fromJson(json);

      expect(roundtrip.id, equals(101));
      expect(roundtrip.courseCode, equals('TIN101'));
      expect(roundtrip.scoreOverall, equals(8.5));
      expect(roundtrip.letter, equals('A'));
    });

    test('ScheduleItem toJson & fromJson roundtrip for offline caching', () {
      final schedule = ScheduleItem(
        id: 202,
        courseName: 'Kiến trúc máy tính',
        room: 'GD3-204',
        timeSlot: 'Tiết 1-2',
        dayOfWeek: 'Thứ 2',
        dayNum: 2,
      );

      final json = schedule.toJson();
      final roundtrip = ScheduleItem.fromJson(json);

      expect(roundtrip.id, equals(202));
      expect(roundtrip.courseName, equals('Kiến trúc máy tính'));
      expect(roundtrip.room, equals('GD3-204'));
      expect(roundtrip.dayNum, equals(2));
    });
  });
}
