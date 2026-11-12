import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_campus/features/schedule/models/schedule_model.dart';
import 'package:smart_campus/features/schedule/providers/schedule_provider.dart';
import 'package:smart_campus/features/home/providers/home_provider.dart';

class MockTodayScheduleNotifier extends ScheduleNotifier {
  final List<ScheduleItem> mockItems;
  final ScheduleItem? mockNextClass;
  final String mockNextLabel;
  final bool mockIsOngoing;

  MockTodayScheduleNotifier({
    required this.mockItems,
    this.mockNextClass,
    this.mockNextLabel = 'LỊCH HỌC',
    this.mockIsOngoing = false,
  });

  @override
  ScheduleState build() {
    return ScheduleState(
      items: mockItems,
      currentWeekItems: mockItems,
      nextClassItem: mockNextClass,
      nextClassLabel: mockNextLabel,
      nextClassIsOngoing: mockIsOngoing,
      currentWeekIndex: 1,
      selectedWeekIndex: 1,
    );
  }
}

void main() {
  group('Home Screen Next Class - 3 Trạng thái Lịch học', () {
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = T2, 7 = CN
    final currentDayNum = currentWeekday == 7 ? 1 : currentWeekday + 1;
    final currentMins = now.hour * 60 + now.minute;

    test('Trạng thái 1: ĐANG HỌC khi giờ hiện tại nằm trong tiết học của ngày hôm nay', () {
      final ongoingClass = ScheduleItem(
        id: 101,
        courseName: 'Cơ sở dữ liệu',
        room: 'B101',
        dayOfWeek: 'Thứ $currentDayNum',
        dayNum: currentDayNum,
        timeSlot: '07:00 - 11:30',
        startMinutesRaw: currentMins - 15,
        endMinutesRaw: currentMins + 45,
      );

      final container = ProviderContainer(
        overrides: [
          scheduleProvider.overrideWith(
            () => MockTodayScheduleNotifier(mockItems: [ongoingClass]),
          ),
        ],
      );

      final nextClass = container.read(nextClassProvider);
      expect(nextClass.stateType, equals(NextClassState.ongoing));
      expect(nextClass.isOngoing, isTrue);
      expect(nextClass.capsuleLabel, equals('ĐANG HỌC'));
      expect(nextClass.statusText, equals('Đang diễn ra'));
      expect(nextClass.countdownText, contains('Còn'));
    });

    test('Trạng thái 2: SẮP TỚI khi lớp học diễn ra hôm nay nhưng chưa đến giờ', () {
      final upcomingClass = ScheduleItem(
        id: 102,
        courseName: 'Mạng máy tính',
        room: 'A203',
        dayOfWeek: 'Thứ $currentDayNum',
        dayNum: currentDayNum,
        timeSlot: '13:00 - 15:30',
        startMinutesRaw: currentMins + 60,
        endMinutesRaw: currentMins + 180,
      );

      final container = ProviderContainer(
        overrides: [
          scheduleProvider.overrideWith(
            () => MockTodayScheduleNotifier(mockItems: [upcomingClass]),
          ),
        ],
      );

      final nextClass = container.read(nextClassProvider);
      expect(nextClass.stateType, equals(NextClassState.upcoming));
      expect(nextClass.isUpcoming, isTrue);
      expect(nextClass.isOngoing, isFalse);
      expect(nextClass.capsuleLabel, equals('SẮP TỚI'));
      expect(nextClass.statusText, equals('Sắp diễn ra'));
      expect(nextClass.countdownText, contains('Bắt đầu sau'));
    });

    test('Trạng thái 3a: NGÀY MAI khi hôm nay không có lớp và lớp gần nhất là ngày mai', () {
      final tomorrowWeekday = ((currentWeekday - 1 + 1) % 7) + 1;
      final tomorrowDayNum = tomorrowWeekday == 7 ? 1 : tomorrowWeekday + 1;

      final tomorrowClass = ScheduleItem(
        id: 103,
        courseName: 'Lập trình di động',
        room: 'PM 9.1',
        dayOfWeek: 'Thứ $tomorrowDayNum',
        dayNum: tomorrowDayNum,
        timeSlot: '07:00 - 09:15',
        startMinutesRaw: 420,
        endMinutesRaw: 555,
      );

      final container = ProviderContainer(
        overrides: [
          scheduleProvider.overrideWith(
            () => MockTodayScheduleNotifier(mockItems: [tomorrowClass]),
          ),
        ],
      );

      final nextClass = container.read(nextClassProvider);
      expect(nextClass.stateType, equals(NextClassState.nextDay));
      expect(nextClass.capsuleLabel, equals('NGÀY MAI'));
      expect(nextClass.statusText, contains('ngày mai'));
    });

    test('Lớp học Online: Trạng thái 1 ĐANG HỌC', () {
      final onlineClass = ScheduleItem(
        id: 201,
        courseName: 'An toàn thông tin',
        room: 'Online',
        dayOfWeek: 'Thứ $currentDayNum',
        dayNum: currentDayNum,
        timeSlot: 'Tiết 1-4',
        note: 'PM: Google Meet, mã: fve-nero-roo',
        startMinutesRaw: currentMins - 30,
        endMinutesRaw: currentMins + 60,
      );

      final container = ProviderContainer(
        overrides: [
          scheduleProvider.overrideWith(
            () => MockTodayScheduleNotifier(mockItems: [onlineClass]),
          ),
        ],
      );

      final nextClass = container.read(nextClassProvider);
      expect(nextClass.item?.isOnline, isTrue);
      expect(nextClass.stateType, equals(NextClassState.ongoing));
      expect(nextClass.capsuleLabel, equals('ĐANG HỌC'));
      expect(nextClass.isOngoing, isTrue);
    });

    test('Lớp học Online: Trạng thái 2 SẮP TỚI', () {
      final onlineClass = ScheduleItem(
        id: 202,
        courseName: 'PP NC khoa học',
        room: 'Online',
        dayOfWeek: 'Thứ $currentDayNum',
        dayNum: currentDayNum,
        timeSlot: 'Tiết 13-15',
        note: 'PM: MS Teams, mã: https://teams',
        startMinutesRaw: currentMins + 45,
        endMinutesRaw: currentMins + 180,
      );

      final container = ProviderContainer(
        overrides: [
          scheduleProvider.overrideWith(
            () => MockTodayScheduleNotifier(mockItems: [onlineClass]),
          ),
        ],
      );

      final nextClass = container.read(nextClassProvider);
      expect(nextClass.item?.isOnline, isTrue);
      expect(nextClass.stateType, equals(NextClassState.upcoming));
      expect(nextClass.capsuleLabel, equals('SẮP TỚI'));
      expect(nextClass.isUpcoming, isTrue);
    });

    test('Lớp học Online: Trạng thái 3 NGÀY MAI khi diễn ra vào ngày mai', () {
      final tomorrowWeekday = ((currentWeekday - 1 + 1) % 7) + 1;
      final tomorrowDayNum = tomorrowWeekday == 7 ? 1 : tomorrowWeekday + 1;

      final onlineClassTomorrow = ScheduleItem(
        id: 203,
        courseName: 'An toàn thông tin',
        room: 'Online',
        dayOfWeek: 'Thứ $tomorrowDayNum',
        dayNum: tomorrowDayNum,
        timeSlot: 'Tiết 1-4',
        note: 'PM: Google Meet, mã: fve-nero-roo',
        startMinutesRaw: 405,
        endMinutesRaw: 630,
      );

      final container = ProviderContainer(
        overrides: [
          scheduleProvider.overrideWith(
            () => MockTodayScheduleNotifier(mockItems: [onlineClassTomorrow]),
          ),
        ],
      );

      final nextClass = container.read(nextClassProvider);
      expect(nextClass.item?.isOnline, isTrue);
      expect(nextClass.stateType, equals(NextClassState.nextDay));
      expect(nextClass.capsuleLabel, equals('NGÀY MAI'));
    });

    test('Tự động chuyển sang NGÀY MAI khi tất cả các lớp hôm nay đã học xong', () {
      final pastClassToday = ScheduleItem(
        id: 204,
        courseName: 'Cơ sở dữ liệu',
        room: 'A101',
        dayOfWeek: 'Thứ $currentDayNum',
        dayNum: currentDayNum,
        timeSlot: '07:00 - 09:15',
        startMinutesRaw: currentMins - 180,
        endMinutesRaw: currentMins - 60,
      );

      final tomorrowWeekday = ((currentWeekday - 1 + 1) % 7) + 1;
      final tomorrowDayNum = tomorrowWeekday == 7 ? 1 : tomorrowWeekday + 1;

      final classTomorrow = ScheduleItem(
        id: 205,
        courseName: 'Lập trình di động',
        room: 'B202',
        dayOfWeek: 'Thứ $tomorrowDayNum',
        dayNum: tomorrowDayNum,
        timeSlot: '07:00 - 09:15',
        startMinutesRaw: 420,
        endMinutesRaw: 555,
      );

      final container = ProviderContainer(
        overrides: [
          scheduleProvider.overrideWith(
            () => MockTodayScheduleNotifier(mockItems: [pastClassToday, classTomorrow]),
          ),
        ],
      );

      final nextClass = container.read(nextClassProvider);
      expect(nextClass.stateType, equals(NextClassState.nextDay));
      expect(nextClass.capsuleLabel, equals('NGÀY MAI'));
      expect(nextClass.item?.id, equals(205));
    });
  });
}
