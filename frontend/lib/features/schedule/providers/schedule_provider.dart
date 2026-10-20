import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/schedule_model.dart';

class ScheduleState {
  final List<ScheduleItem> items;
  final String selectedDay;
  final String weekRange;
  final int selectedWeekIndex;
  final int currentWeekIndex;
  final bool isSunday;
  final List<Map<String, dynamic>> availableWeeks;
  final List<Map<String, String>> days;
  final bool isLoading;
  final String? error;

  const ScheduleState({
    this.items = const [],
    this.selectedDay = 'Thứ 2',
    this.weekRange = '',
    this.selectedWeekIndex = 0,
    this.currentWeekIndex = 0,
    this.isSunday = false,
    this.availableWeeks = const [],
    this.days = const [],
    this.isLoading = false,
    this.error,
  });

  List<ScheduleItem> get filteredItems {
    return items.where((item) => item.matchesDay(selectedDay)).toList();
  }

  ScheduleState copyWith({
    List<ScheduleItem>? items,
    String? selectedDay,
    String? weekRange,
    int? selectedWeekIndex,
    int? currentWeekIndex,
    bool? isSunday,
    List<Map<String, dynamic>>? availableWeeks,
    List<Map<String, String>>? days,
    bool? isLoading,
    String? error,
  }) {
    return ScheduleState(
      items: items ?? this.items,
      selectedDay: selectedDay ?? this.selectedDay,
      weekRange: weekRange ?? this.weekRange,
      selectedWeekIndex: selectedWeekIndex ?? this.selectedWeekIndex,
      currentWeekIndex: currentWeekIndex ?? this.currentWeekIndex,
      isSunday: isSunday ?? this.isSunday,
      availableWeeks: availableWeeks ?? this.availableWeeks,
      days: days ?? this.days,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ScheduleNotifier extends Notifier<ScheduleState> {
  Dio get _dio => ref.read(dioProvider);

  @override
  ScheduleState build() {
    final now = DateTime.now();
    final weekdayMap = {
      1: 'Thứ 2',
      2: 'Thứ 3',
      3: 'Thứ 4',
      4: 'Thứ 5',
      5: 'Thứ 6',
      6: 'Thứ 7',
      7: 'CN',
    };
    final initialDay = weekdayMap[now.weekday] ?? 'Thứ 2';

    final distToMon = (now.weekday - 1) % 7;
    final mon = now.subtract(Duration(days: distToMon));
    final defaultDays = _generateDefaultDays(mon);
    final defaultWeeks = _generateDefaultWeeks(mon);

    Future.microtask(() => fetchSchedule());

    return ScheduleState(
      selectedDay: initialDay,
      weekRange: defaultWeeks.isNotEmpty ? defaultWeeks[0]['weekRange'] : '',
      availableWeeks: defaultWeeks,
      days: defaultDays,
      isLoading: true,
    );
  }

  static List<Map<String, dynamic>> _generateDefaultWeeks(DateTime mon) {
    final weeks = <Map<String, dynamic>>[];
    String pad(int n) => n.toString().padLeft(2, '0');
    for (int i = 0; i < 4; i++) {
      final wMon = mon.add(Duration(days: i * 7));
      final wSun = wMon.add(const Duration(days: 6));
      final sStr = '${pad(wMon.day)}/${pad(wMon.month)}';
      final eStr = '${pad(wSun.day)}/${pad(wSun.month)}';
      final label = i == 0
          ? 'Tuần này ($sStr - $eStr)'
          : (i == 1 ? 'Tuần sau ($sStr - $eStr)' : 'Tuần ${pad(i + 1)} ($sStr - $eStr)');
      weeks.add({
        'index': i,
        'label': label,
        'weekRange': 'Từ ngày ${pad(wMon.day)}/${pad(wMon.month)}/${wMon.year} đến ngày ${pad(wSun.day)}/${pad(wSun.month)}/${wSun.year}',
        'isCurrent': i == 0,
        'isNext': i == 1,
      });
    }
    return weeks;
  }

  static List<Map<String, String>> _generateDefaultDays(DateTime mon) {
    final dayNames = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
    String pad(int n) => n.toString().padLeft(2, '0');
    return List.generate(7, (i) {
      final d = mon.add(Duration(days: i));
      return {
        'day': dayNames[i],
        'date': '${pad(d.day)}/${pad(d.month)}',
        'fullDate': '${pad(d.day)}/${pad(d.month)}/${d.year}',
      };
    });
  }

  void selectDay(String day) {
    state = state.copyWith(selectedDay: day);
  }

  Future<void> selectWeek(int weekIndex) async {
    state = state.copyWith(selectedWeekIndex: weekIndex);
    await fetchSchedule(weekIndex: weekIndex);
  }

  Future<void> fetchSchedule({int? weekIndex}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = ref.read(authProvider).user;
      final mssv = (user != null && !user.isGuest) ? user.studentId : null;

      final Map<String, dynamic> query = {};
      if (mssv != null) query['mssv'] = mssv;
      final targetWeek = weekIndex ?? state.selectedWeekIndex;
      if (targetWeek > 0) {
        query['weekIndex'] = targetWeek;
      }

      final response = await _dio.get(
        ApiEndpoints.schedule,
        queryParameters: query.isNotEmpty ? query : null,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['schedules'] ?? response.data['data'] ?? [];
        final items = list.map((item) => ScheduleItem.fromJson(item)).toList();

        final String weekRange = response.data['weekRange'] ?? state.weekRange;
        final int selWeekIdx = response.data['selectedWeekIndex'] ?? targetWeek;
        final int curWeekIdx = response.data['currentWeekIndex'] ?? 0;
        final bool isSunday = response.data['isSunday'] == true;

        List<Map<String, dynamic>> weeks = state.availableWeeks;
        if (response.data['availableWeeks'] is List && (response.data['availableWeeks'] as List).isNotEmpty) {
          weeks = (response.data['availableWeeks'] as List).map((w) {
            final wMap = w as Map<String, dynamic>;
            final range = wMap['weekRange']?.toString() ?? '';
            String cleanLabel = wMap['label']?.toString() ?? '';
            final match = RegExp(r'(\d{1,2}/\d{1,2})').allMatches(range).toList();
            if (match.length >= 2) {
              final sStr = match[0].group(1)!;
              final eStr = match[1].group(1)!;
              if (wMap['isCurrent'] == true) {
                cleanLabel = 'Tuần này ($sStr - $eStr)';
              } else if (wMap['isNext'] == true) {
                cleanLabel = 'Tuần sau ($sStr - $eStr)';
              } else {
                cleanLabel = '$cleanLabel ($sStr - $eStr)';
              }
            }
            return {
              'index': wMap['index'] ?? 0,
              'label': cleanLabel.isNotEmpty ? cleanLabel : range,
              'weekRange': range,
              'isCurrent': wMap['isCurrent'] == true,
              'isNext': wMap['isNext'] == true,
            };
          }).toList();
        }

        List<Map<String, String>> daysList = state.days;
        if (response.data['days'] is List && (response.data['days'] as List).isNotEmpty) {
          daysList = (response.data['days'] as List).map((d) {
            final dMap = d as Map<String, dynamic>;
            return {
              'day': dMap['label']?.toString() ?? dMap['name']?.toString() ?? 'Thứ 2',
              'date': dMap['dateShort']?.toString() ?? dMap['date']?.toString() ?? '',
              'fullDate': dMap['date']?.toString() ?? '',
            };
          }).toList();
        }

        state = state.copyWith(
          items: items,
          weekRange: weekRange,
          selectedWeekIndex: selWeekIdx,
          currentWeekIndex: curWeekIdx,
          isSunday: isSunday,
          availableWeeks: weeks,
          days: daysList,
          isLoading: false,
        );
      } else {
        _useFallbackMockData();
      }
    } catch (_) {
      _useFallbackMockData();
    }
  }

  void _useFallbackMockData() {
    final mockItems = [
      const ScheduleItem(
        id: 1,
        courseName: 'LS Đảng CS VN',
        room: '2.21 (CLC)',
        dayOfWeek: 'Thứ 2',
        timeSlot: 'Tiết 1-4',
        lecturer: 'Đoàn Văn Kỳ',
      ),
      const ScheduleItem(
        id: 2,
        courseName: 'Lập trình thiết bị di động',
        room: '9.2.04',
        dayOfWeek: 'Thứ 2',
        timeSlot: 'Tiết 7-10',
        lecturer: 'TS. Hoàng Minh',
      ),
      const ScheduleItem(
        id: 3,
        courseName: 'Hệ quản trị cơ sở dữ liệu nâng cao',
        room: 'Nhà học số 7.2.1',
        dayOfWeek: 'Thứ 3',
        timeSlot: '07:00 - 09:15',
        lecturer: 'TS. Lê Thị Hồng Vân',
      ),
      const ScheduleItem(
        id: 4,
        courseName: 'Phân tích thiết kế hệ thống thông tin',
        room: 'Nhà học số 8.2.3',
        dayOfWeek: 'Thứ 4',
        timeSlot: '13:00 - 15:15',
        lecturer: 'ThS. Đặng Hữu Phúc',
      ),
      const ScheduleItem(
        id: 5,
        courseName: 'Trí tuệ nhân tạo & Khai phá dữ liệu',
        room: 'Nhà học số 9.3.2',
        dayOfWeek: 'Thứ 5',
        timeSlot: '07:00 - 09:15',
        lecturer: 'PGS.TS. Vũ Đình Khang',
      ),
      const ScheduleItem(
        id: 6,
        courseName: 'Giáo dục thể chất (Bóng đá)',
        room: 'Sân vận động',
        dayOfWeek: 'Thứ 6',
        timeSlot: '06:30 - 08:45',
        lecturer: 'ThS. Phan Quốc Tuấn',
      ),
    ];

    state = state.copyWith(items: mockItems, isLoading: false);
  }

  Future<bool> addCustomSchedule(ScheduleItem item) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.customSchedule,
        data: item.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(items: [...state.items, item]);
        return true;
      }
    } catch (_) {}

    state = state.copyWith(items: [...state.items, item]);
    return true;
  }
}

final scheduleProvider = NotifierProvider<ScheduleNotifier, ScheduleState>(ScheduleNotifier.new);

