import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus/core/utils/url_launcher_helper.dart';
import 'package:smart_campus/features/schedule/models/schedule_model.dart';
import 'package:smart_campus/features/schedule/utils/room_directions.dart';
import 'package:smart_campus/features/schedule/widgets/schedule_card.dart';

void main() {
  group('Kiểm tra logic Lịch học Online', () {
    test('parseRoomDirections nhận diện lớp Online và bóc tách link Google Meet', () {
      final direction = parseRoomDirections(
        'Online',
        extraNote: 'PM: Google Meet, mã: fve-nero-roo',
      );

      expect(direction.isOnline, isTrue);
      expect(direction.buildingCode, 'Online');
      expect(direction.building, 'Lớp học trực tuyến (Online)');
      expect(direction.floor, 'Học từ xa');
      expect(direction.meetingCode, 'fve-nero-roo');
      expect(direction.meetingUrl, 'https://meet.google.com/fve-nero-roo');
      expect(direction.steps, isEmpty); // Không có lộ trình đi bộ
      expect(direction.building, isNot(contains('Nhà học số 2')));
    });

    test('ScheduleItem getter isOnline, onlineMeetingCode, onlineMeetingUrl hoạt động chính xác', () {
      final item = ScheduleItem(
        id: 1,
        courseName: 'An toàn thông tin',
        room: 'Online',
        dayOfWeek: 'Thứ 2',
        timeSlot: '07:00 - 10:30',
        note: 'PM: Google Meet, mã: abc-defg-hij',
      );

      expect(item.isOnline, isTrue);
      expect(item.onlineMeetingCode, 'abc-defg-hij');
      expect(item.onlineMeetingUrl, 'https://meet.google.com/abc-defg-hij');
    });

    testWidgets('ScheduleCard hiển thị nút "Mở Meet" thay vì "Chỉ đường" đối với lớp Online', (tester) async {
      final item = ScheduleItem(
        id: 1,
        courseName: 'An toàn thông tin',
        room: 'Online',
        dayOfWeek: 'Thứ 2',
        timeSlot: '07:00 - 10:30',
        note: 'PM: Google Meet, mã: fve-nero-roo',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleCard(
              item: item,
              onSelectDirection: (_) {},
            ),
          ),
        ),
      );

      // Phải có nút Mở Meet chứa mã phòng
      expect(find.text('Mở Google Meet (fve-nero-roo)'), findsOneWidget);
      // Không được hiển thị "Chỉ đường tới phòng"
      expect(find.text('Chỉ đường tới phòng'), findsNothing);
      // Icon video phải xuất hiện
      expect(find.byIcon(Icons.videocam), findsOneWidget);
    });

    test('AppUrlLauncher.openGoogleMeet trả về false an toàn và sao chép mã khi không có ứng dụng', () async {
      final res = await AppUrlLauncher.openGoogleMeet(
        code: 'fve-nero-roo',
      );
      // Trên môi trường test không có app bên thứ ba, hàm không crash và sao chép vào bộ nhớ tạm
      expect(res, isFalse);
    });
  });
}
