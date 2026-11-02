import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_campus/features/schedule/models/schedule_model.dart';
import 'package:smart_campus/features/schedule/providers/schedule_provider.dart';
import 'package:smart_campus/features/home/providers/home_provider.dart';

void main() {
  test('Home nextClassProvider priority uses serverNextClass and preserves it when browsing weeks', () {
    final container = ProviderContainer(
      overrides: [
        scheduleProvider.overrideWith(() => MockScheduleNotifier()),
      ],
    );

    // Initial check: server nextClass should be used
    final nextClass = container.read(nextClassProvider);
    expect(nextClass.subject, equals('Lập trình thiết bị di động (TH)'));
    expect(nextClass.capsuleLabel, equals('NGÀY MAI'));
    expect(nextClass.room, equals('Phòng máy 9.1'));

    // Now simulate user browsing "Tuần trước"
    container.read(scheduleProvider.notifier).selectWeek(0);

    // Home nextClass must NOT change to last week's classes!
    final nextClassAfterBrowse = container.read(nextClassProvider);
    expect(nextClassAfterBrowse.subject, equals('Lập trình thiết bị di động (TH)'));
    expect(nextClassAfterBrowse.capsuleLabel, equals('NGÀY MAI'));
  });
}

class MockScheduleNotifier extends ScheduleNotifier {
  @override
  ScheduleState build() {
    final mockItem = ScheduleItem(
      id: 1,
      courseName: 'Lập trình thiết bị di động (TH)',
      room: 'Phòng máy 9.1',
      dayOfWeek: 'Thứ 2 26/10',
      timeSlot: 'Tiết 7-10',
      statusLabel: 'NGÀY MAI',
    );

    return ScheduleState(
      nextClassItem: mockItem,
      nextClassLabel: 'NGÀY MAI',
      nextClassStatus: 'Lớp học tiếp theo',
      nextClassCountdown: '13:45 • Thứ 2',
      currentWeekIndex: 1,
      selectedWeekIndex: 2,
      isSunday: true,
      currentWeekItems: [mockItem],
      items: [mockItem],
    );
  }

  @override
  Future<void> selectWeek(int weekIndex) async {
    // Simulate changing items to past week
    final pastItem = ScheduleItem(
      id: 99,
      courseName: 'Môn tuần trước đã kết thúc',
      room: 'Phòng cũ',
      dayOfWeek: 'Thứ 2 12/10',
      timeSlot: 'Tiết 1-4',
    );
    state = state.copyWith(
      selectedWeekIndex: weekIndex,
      items: [pastItem],
    );
  }
}

