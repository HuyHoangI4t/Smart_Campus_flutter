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
      weekRange: defaultWeeks.length > 1 ? defaultWeeks[1]['weekRange'] : (defaultWeeks.isNotEmpty ? defaultWeeks[0]['weekRange'] : ''),
      selectedWeekIndex: defaultWeeks.length > 1 ? 1 : 0,
      currentWeekIndex: defaultWeeks.length > 1 ? 1 : 0,
      availableWeeks: defaultWeeks,
      days: defaultDays,
      isLoading: true,
    );
  }

  static List<Map<String, dynamic>> _generateDefaultWeeks(DateTime mon) {
    final weeks = <Map<String, dynamic>>[];
    String pad(int n) => n.toString().padLeft(2, '0');

    final config = [
      {'offset': -1, 'label': 'Tuần trước', 'isCurrent': false, 'isNext': false},
      {'offset': 0, 'label': 'Tuần này', 'isCurrent': true, 'isNext': false},
      {'offset': 1, 'label': 'Tuần sau', 'isCurrent': false, 'isNext': true},
      {'offset': 2, 'label': '2 tuần sau', 'isCurrent': false, 'isNext': false},
    ];

    for (int i = 0; i < config.length; i++) {
      final item = config[i];
      final off = item['offset'] as int;
      final wMon = mon.add(Duration(days: off * 7));
      final wSun = wMon.add(const Duration(days: 6));
      final sStr = '${pad(wMon.day)}/${pad(wMon.month)}';
      final eStr = '${pad(wSun.day)}/${pad(wSun.month)}';
      final label = '${item['label']} ($sStr - $eStr)';
      final weekRange = 'Từ ngày ${pad(wMon.day)}/${pad(wMon.month)}/${wMon.year} đến ngày ${pad(wSun.day)}/${pad(wSun.month)}/${wSun.year}';

      weeks.add({
        'index': i,
        'offset': off,
        'label': label,
        'weekRange': weekRange,
        'isCurrent': item['isCurrent'] == true,
        'isNext': item['isNext'] == true,
        'startDate': wMon,
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
    state = state.copyWith(selectedDay: day.trim());
  }

  Future<void> selectWeek(int weekIndex) async {
    final wData = state.availableWeeks.firstWhere(
      (w) => w['index'] == weekIndex,
      orElse: () => {},
    );

    if (wData.isNotEmpty && wData['startDate'] is DateTime) {
      final mon = wData['startDate'] as DateTime;
      state = state.copyWith(
        selectedWeekIndex: weekIndex,
        days: _generateDefaultDays(mon),
        weekRange: wData['weekRange'] ?? state.weekRange,
      );
    } else if (wData.isNotEmpty && wData['weekRange'] is String) {
      final rangeText = wData['weekRange'] as String;
      final match = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})').allMatches(rangeText).toList();
      if (match.length >= 2) {
        final d = int.parse(match[0].group(1)!);
        final m = int.parse(match[0].group(2)!);
        final y = int.parse(match[0].group(3)!);
        final mon = DateTime(y, m, d);
        state = state.copyWith(
          selectedWeekIndex: weekIndex,
          days: _generateDefaultDays(mon),
          weekRange: rangeText,
        );
      } else {
        state = state.copyWith(selectedWeekIndex: weekIndex);
      }
    } else {
      state = state.copyWith(selectedWeekIndex: weekIndex);
    }

    await fetchSchedule(weekIndex: weekIndex);
  }

  Future<void> fetchSchedule({int? weekIndex, bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = ref.read(authProvider).user;
      final mssv = (user != null && !user.isGuest) ? user.studentId : null;

      final Map<String, dynamic> query = {};
      if (mssv != null) query['mssv'] = mssv;
      final targetWeek = weekIndex ?? state.selectedWeekIndex;
      query['weekIndex'] = targetWeek;
      if (forceRefresh) {
        query['refresh'] = 'true';
        query['reload'] = 'true';
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
              if (cleanLabel.contains('(')) {
                cleanLabel = cleanLabel.split('(')[0].trim();
              }
              cleanLabel = '$cleanLabel ($sStr - $eStr)';
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
          daysList = (response.data['days'] as List)
              .map((d) {
                final dMap = d as Map<String, dynamic>;
                return {
                  'day': dMap['label']?.toString() ?? dMap['name']?.toString() ?? 'Thứ 2',
                  'date': dMap['dateShort']?.toString() ?? dMap['date']?.toString() ?? '',
                  'fullDate': dMap['date']?.toString() ?? '',
                };
              })
              .toList();
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
        state = state.copyWith(items: const [], isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(items: const [], isLoading: false);
    }
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

  Future<bool> updateCustomSchedule(dynamic id, ScheduleItem updatedItem) async {
    try {
      final response = await _dio.put(
        '${ApiEndpoints.customSchedule}/$id',
        data: updatedItem.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newItems = state.items.map((i) => i.id == id ? updatedItem : i).toList();
        state = state.copyWith(items: newItems);
        return true;
      }
    } catch (_) {}

    final newItems = state.items.map((i) => i.id == id ? updatedItem : i).toList();
    state = state.copyWith(items: newItems);
    return true;
  }

  Future<bool> deleteCustomSchedule(dynamic id) async {
    try {
      final response = await _dio.delete(
        '${ApiEndpoints.customSchedule}/$id',
      );

      if (response.statusCode == 200) {
        final newItems = state.items.where((i) => i.id != id).toList();
        state = state.copyWith(items: newItems);
        return true;
      }
    } catch (_) {}

    final newItems = state.items.where((i) => i.id != id).toList();
    state = state.copyWith(items: newItems);
    return true;
  }
}

final scheduleProvider = NotifierProvider<ScheduleNotifier, ScheduleState>(ScheduleNotifier.new);

