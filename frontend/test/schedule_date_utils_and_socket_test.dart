import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus/features/schedule/utils/schedule_date_utils.dart';
import 'package:smart_campus/core/services/socket_service.dart';

void main() {
  group('ScheduleDateUtils Tests', () {
    test('getTodayDayNum maps weekdays correctly', () {
      // 2026-11-02 là Thứ 2
      final mon = DateTime(2026, 11, 2);
      expect(ScheduleDateUtils.getTodayDayNum(mon), 2);

      // 2026-11-08 là Chủ nhật
      final sun = DateTime(2026, 11, 8);
      expect(ScheduleDateUtils.getTodayDayNum(sun), 1);
    });

    test('parseWeekRangeDates parses standard Vietnamese week string', () {
      const rangeStr = 'Từ ngày 02/11/2026 đến ngày 08/11/2026';
      final range = ScheduleDateUtils.parseWeekRangeDates(rangeStr);
      expect(range, isNotNull);
      expect(range!.start.year, 2026);
      expect(range.start.month, 11);
      expect(range.start.day, 2);
      expect(range.end.day, 8);
    });

    test('generateWeekDays creates 7 continuous days starting from Monday', () {
      final mon = DateTime(2026, 11, 2);
      final days = ScheduleDateUtils.generateWeekDays(mon);
      expect(days.length, 7);
      expect(days[0]['day'], 'Thứ 2');
      expect(days[0]['date'], '02/11');
      expect(days[6]['day'], 'CN');
      expect(days[6]['date'], '08/11');
    });

    test('generateDefaultAvailableWeeks returns active weeks including Tuần này', () {
      final weeks = ScheduleDateUtils.generateDefaultAvailableWeeks();
      expect(weeks.length, greaterThanOrEqualTo(4));
      final hasCurrent = weeks.any((w) => w['isCurrent'] == true || (w['label'] as String).contains('Tuần này'));
      expect(hasCurrent, isTrue);
    });
  });

  group('SocketService SOS Self-Sent Filter Tests', () {
    test('isSelfSentSos filters out alerts from own deviceId', () {
      final socket = SocketService.instance;
      final myId = socket.deviceId;

      // Nhận alert từ chính client_id này
      final selfAlert = {
        'id': 101,
        'client_id': myId,
        'incidentType': 'Y tế',
        'location': 'Nhà 7',
      };
      expect(socket.isSelfSentSos(selfAlert), isTrue);

      // Nhận alert từ thiết bị khác
      final otherAlert = {
        'id': 102,
        'client_id': 'other_device_999',
        'incidentType': 'Hỏa hoạn',
        'location': 'Nhà 2',
      };
      expect(socket.isSelfSentSos(otherAlert), isFalse);
    });

    test('markSosAsSelfSent records sent SOS id and filters it out', () {
      final socket = SocketService.instance;
      socket.markSosAsSelfSent(555);

      final alert = {
        'id': 555,
        'client_id': 'unknown_or_null',
        'incidentType': 'An ninh',
        'location': 'Ký túc xá 2',
      };
      expect(socket.isSelfSentSos(alert), isTrue);
    });
  });
}
