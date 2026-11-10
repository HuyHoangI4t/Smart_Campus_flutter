import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/nav_header.dart';
import '../../../core/widgets/wireframe_widgets.dart';
import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import '../utils/schedule_date_utils.dart';
import '../widgets/schedule_add_custom_modal.dart';
import '../widgets/schedule_card.dart';
import '../widgets/schedule_custom_detail_modal.dart';
import '../widgets/schedule_day_bar.dart';
import '../widgets/schedule_room_direction_modal.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int _selectedDay = 2; // Mặc định Thứ 2, cập nhật theo ngày thực trong initState
  bool _isTableView = false; // Mặc định chế độ xem theo ngày (Day-by-Day như index.tsx)

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Trong model & DB: CN = 1, Thứ 2 = 2, ..., Thứ 7 = 7
    _selectedDay = now.weekday == 7 ? 1 : now.weekday + 1;
  }

  static const _dayNames = [
    '',
    'Chủ nhật',
    'Thứ 2',
    'Thứ 3',
    'Thứ 4',
    'Thứ 5',
    'Thứ 6',
    'Thứ 7'
  ];

  static const _dayLongNames = [
    '',
    'Chủ nhật',
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy'
  ];

  String _dayNumToName(int dayNum) =>
      (dayNum >= 1 && dayNum <= 7) ? _dayNames[dayNum] : 'Thứ 2';

  String _dayNumToLongName(int dayNum) =>
      (dayNum >= 1 && dayNum <= 7) ? _dayLongNames[dayNum] : 'Thứ Hai';
  List<Map<String, dynamic>> get _dynamicWeeks => ScheduleDateUtils.generateDefaultAvailableWeeks();
  List<Map<String, String>> get _dynamicDays => ScheduleDateUtils.generateWeekDays(ScheduleDateUtils.getMondayOfWeek(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleProvider);
    final now = DateTime.now();
    final dynamicDays = _dynamicDays;
    final weekSubtitle = scheduleState.weekRange.isNotEmpty
        ? scheduleState.weekRange
        : ScheduleDateUtils.getWeekRangeFromDate(now);

    final todayDayNum = ScheduleDateUtils.getTodayDayNum(now);
    final isViewingCurrentWeek = scheduleState.selectedWeekIndex == scheduleState.currentWeekIndex;

    // Tính số tiết học cho mỗi thứ trong tuần
    final Map<int, int> countMap = {};
    for (final item in scheduleState.items) {
      countMap[item.dayNum] = (countMap[item.dayNum] ?? 0) + 1;
    }

    final days = scheduleState.days.isNotEmpty ? scheduleState.days : dynamicDays;

    // Lọc môn học của thứ đang chọn
    final selectedDayName = _dayNumToName(_selectedDay);
    final filteredItems = scheduleState.items.where((it) {
      if (it.dayNum == _selectedDay) return true;
      if (it.matchesDay(selectedDayName)) return true;
      return false;
    }).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    // Tìm chuỗi ngày tương ứng với thứ đang chọn
    String selectedDateStr = '';
    for (final d in days) {
      final rawDay = d['day'] ?? '';
      if (ScheduleItem.dayStrToNum(rawDay) == _selectedDay) {
        selectedDateStr = d['date'] ?? '';
        break;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddScheduleModal(
          context,
          ref,
          scheduleState,
          initialDayNum: _selectedDay,
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Thêm lịch',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
        ),
      ),
      body: Column(
        children: [
          // ─── 1. NAVHEADER (Navy #132F73) ───
          NavHeader(
            title: 'Thời khóa biểu',
            subtitle: weekSubtitle,
            rightElement: GestureDetector(
              onTap: () => _showAddScheduleModal(
                context,
                ref,
                scheduleState,
                initialDayNum: _selectedDay,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.white, size: 15),
                    SizedBox(width: 5),
                    Text(
                      'Thêm lịch',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── 2. KHỐI ĐIỀU HƯỚNG LỊCH THỐNG NHẤT (UNIFIED CALENDAR CONTROLLER) ───
          _buildCalendarHeader(
            scheduleState: scheduleState,
            days: days,
            countMap: countMap,
            todayDayNum: todayDayNum,
            isViewingCurrentWeek: isViewingCurrentWeek,
          ),

          // ─── 5. DANH SÁCH LỊCH HỌC THEO NGÀY HOẶC BẢNG CẢ TUẦN ───
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(scheduleProvider.notifier).fetchSchedule(forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề ngày / Chế độ xem & nút chuyển đổi
                    Padding(
                      padding: const EdgeInsets.only(left: 2, right: 2, bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isTableView
                                  ? 'Thời khóa biểu cả tuần (T2 – CN)'
                                  : '${_dayNumToLongName(_selectedDay)}${selectedDateStr.isNotEmpty ? " ($selectedDateStr)" : ""}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (!_isTableView) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: filteredItems.isNotEmpty
                                    ? const Color(0xFFEEF2FF)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: filteredItems.isNotEmpty
                                      ? const Color(0xFFC7D2FE)
                                      : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${filteredItems.length} tiết',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: filteredItems.isNotEmpty
                                      ? const Color(0xFF4338CA)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // Nút chuyển đổi chế độ xem
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isTableView = !_isTableView;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isTableView ? Icons.view_day_outlined : Icons.calendar_view_week_outlined,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isTableView ? 'Theo ngày' : 'Cả tuần',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Nội dung: Bảng cả tuần hoặc Danh sách môn theo ngày
                    if (scheduleState.isLoading)
                      _isTableView
                          ? _buildTableSkeleton()
                          : const Column(
                              children: [
                                WireframeScheduleCard(),
                                WireframeScheduleCard(),
                                WireframeScheduleCard(),
                              ],
                            )
                    else if (_isTableView)
                      _buildVerticalTimetable(scheduleState)
                    else if (filteredItems.isEmpty)
                      _buildEmptyDayState(scheduleState)
                    else
                      Column(
                        children: filteredItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ScheduleCard(
                              item: item,
                              onSelectDirection: (it) => ScheduleRoomDirectionModal.show(context, item: it),
                              onEdit: (it) => _showEditScheduleModal(context, ref, scheduleState, it),
                              onDelete: (it) => _confirmDeleteSchedule(context, ref, it),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 16),

                    // Information note box
                    _buildNoticeBox(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── KHỐI ĐIỀU HƯỚNG LỊCH THỐNG NHẤT (UNIFIED CALENDAR CONTROLLER) ───
  Widget _buildCalendarHeader({
    required ScheduleState scheduleState,
    required List<Map<String, String>> days,
    required Map<int, int> countMap,
    required int todayDayNum,
    required bool isViewingCurrentWeek,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Hàng điều hướng tuần
          _buildWeekNavigator(scheduleState),

          // 2. Cảnh báo chủ nhật / chuyển tuần kế tiếp (nếu có)
          if (scheduleState.isSunday) _buildSundayAlert(scheduleState),

          // 3. Hàng chọn 7 thứ trong tuần (chế độ xem theo ngày)
          if (!_isTableView)
            ScheduleDayBar(
              selectedDay: _selectedDay,
              todayDayNum: todayDayNum,
              isViewingCurrentWeek: isViewingCurrentWeek,
              days: days,
              classCountPerDay: countMap,
              onSelectDay: (dayNum) {
                setState(() {
                  _selectedDay = dayNum;
                });
              },
            ),
        ],
      ),
    );
  }

  // ─── THANH ĐIỀU HƯỚNG TUẦN TINH GỌN (WEEK NAVIGATOR) ───
  Widget _buildWeekNavigator(ScheduleState scheduleState) {
    final weeks = scheduleState.availableWeeks.isNotEmpty ? scheduleState.availableWeeks : _dynamicWeeks;
    final currentIdx = scheduleState.selectedWeekIndex;
    final canPrev = currentIdx > 0;
    final canNext = currentIdx < weeks.length - 1;
    final curIdx = scheduleState.currentWeekIndex;

    // Dữ liệu tuần đang chọn
    final currentWeekData = weeks.firstWhere(
      (w) => ((w['index'] as num?)?.toInt() ?? 0) == currentIdx,
      orElse: () => weeks.isNotEmpty ? weeks.first : <String, dynamic>{},
    );

    // Tiêu đề tuần
    String rawLabel = currentWeekData['label']?.toString() ?? 'Tuần này';
    if (rawLabel.contains('(')) {
      rawLabel = rawLabel.split('(')[0].trim();
    }

    final range = currentWeekData['weekRange']?.toString() ?? scheduleState.weekRange;
    final match = RegExp(r'(\d{1,2}/\d{1,2})').allMatches(range).toList();
    String dateRangeStr = '';
    if (match.length >= 2) {
      dateRangeStr = '${match[0].group(1)} – ${match[1].group(1)}';
    }

    final displayTitle = dateRangeStr.isNotEmpty ? '$rawLabel ($dateRangeStr)' : rawLabel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(
        children: [
          // Nút Tuần trước ◀
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canPrev
                  ? () => ref.read(scheduleProvider.notifier).selectWeek(currentIdx - 1)
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: canPrev ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: canPrev ? AppColors.textForeground : const Color(0xFFCBD5E1),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Nút trung tâm chọn tuần (Bấm vào mở danh sách toàn bộ các tuần)
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showWeekPickerSheet(context, scheduleState, weeks),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          displayTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Nút Tuần sau ▶
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canNext
                  ? () => ref.read(scheduleProvider.notifier).selectWeek(currentIdx + 1)
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: canNext ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: canNext ? AppColors.textForeground : const Color(0xFFCBD5E1),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          // Nút quay về Tuần hiện tại nếu đang xem tuần khác
          if (currentIdx != curIdx) ...[
            const SizedBox(width: 6),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => ref.read(scheduleProvider.notifier).selectWeek(curIdx),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Hiện tại',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

    // Bottom Sheet chọn tuần
  void _showWeekPickerSheet(
    BuildContext context,
    ScheduleState scheduleState,
    List<Map<String, dynamic>> weeks,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chọn tuần học',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textForeground,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: weeks.length,
                    itemBuilder: (ctx, idx) {
                      final w = weeks[idx];
                      final wIdx = w['index'] is int ? w['index'] as int : idx;
                      final isSelected = wIdx == scheduleState.selectedWeekIndex;
                      final label = w['label']?.toString() ?? 'Tuần ${idx + 1}';
                      final range = w['weekRange']?.toString() ?? '';

                      return ListTile(
                        onTap: () {
                          Navigator.pop(ctx);
                          ref.read(scheduleProvider.notifier).selectWeek(wIdx);
                        },
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.calendar_today,
                              size: 15,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        title: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppColors.primary : AppColors.textForeground,
                          ),
                        ),
                        subtitle: range.isNotEmpty
                            ? Text(
                                range,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              )
                            : null,
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── SUNDAY ALERT BANNER ───
  Widget _buildSundayAlert(ScheduleState scheduleState) {
    final isViewingNextWeek = scheduleState.selectedWeekIndex != scheduleState.currentWeekIndex;
    final targetWeekIdx = isViewingNextWeek
        ? scheduleState.currentWeekIndex
        : (scheduleState.currentWeekIndex + 1 < scheduleState.availableWeeks.length
            ? scheduleState.currentWeekIndex + 1
            : scheduleState.currentWeekIndex);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isViewingNextWeek
                  ? 'Hôm nay là Chủ nhật: Đang xem trước lịch học Tuần sau'
                  : 'Hôm nay là Chủ nhật: Lịch học tuần này đã kết thúc',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1E40AF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(scheduleProvider.notifier).selectWeek(targetWeekIdx);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF93C5FD)),
              ),
              child: Text(
                isViewingNextWeek ? 'Xem tuần này' : 'Xem tuần sau',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.info,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ─── LOGIC KIỂM TRA HÔM NAY CHUẨN XÁC THEO LỊCH THỰC TẾ ───
  // ══════════════════════════════════════════════════════════════════════════
  bool _isDayToday(Map<String, String> dayData, int dayIndex, bool isCurrentWeek) {
    final now = DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');
    final todayShort = '${pad(now.day)}/${pad(now.month)}'; // e.g. "21/10"
    final todayFull = '${pad(now.day)}/${pad(now.month)}/${now.year}'; // e.g. "21/10/2026"

    // 1. So khớp trực tiếp theo ngày tháng nếu có (ví dụ "21/10")
    final dateStr = (dayData['date'] ?? '').trim();
    if (dateStr.isNotEmpty && dateStr == todayShort) {
      return true;
    }
    final fullDate = (dayData['fullDate'] ?? '').trim();
    if (fullDate.isNotEmpty && (fullDate == todayFull || fullDate.startsWith(todayShort))) {
      return true;
    }

    // 2. Nếu đang xem tuần hiện tại, so khớp theo thứ trong tuần
    if (isCurrentWeek) {
      final weekdayMap = {
        1: 'Thứ 2',
        2: 'Thứ 3',
        3: 'Thứ 4',
        4: 'Thứ 5',
        5: 'Thứ 6',
        6: 'Thứ 7',
        7: 'CN',
      };
      final todayDayName = weekdayMap[now.weekday];
      final dayName = (dayData['day'] ?? '').trim();
      if (dayName == todayDayName ||
          (todayDayName == 'CN' && (dayName == 'Chủ nhật' || dayName.toLowerCase().contains('chủ nhật')))) {
        return true;
      }
    }
    return false;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ─── THỜI KHÓA BIỂU DẠNG BẢNG: THỨ THEO CHIỀU DỌC (T2 -> CN), CHỈ SÁNG & CHIỀU ───
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildVerticalTimetable(ScheduleState scheduleState) {
    final days = scheduleState.days.isNotEmpty ? scheduleState.days : _dynamicDays;
    final isCurrentWeek = scheduleState.selectedWeekIndex == scheduleState.currentWeekIndex;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ─── HEADER: CỘT THỨ | BUỔI SÁNG | BUỔI CHIỀU ───
          _buildTableHeader(),

          // ─── 7 DÒNG CHO 7 NGÀY (THỨ 2 -> CHỦ NHẬT) THEO CHIỀU DỌC ───
          for (int i = 0; i < days.length; i++) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            _buildDayRow(
              dayData: days[i],
              dayIndex: i,
              scheduleState: scheduleState,
              isToday: _isDayToday(days[i], i, isCurrentWeek),
              isLast: i == days.length - 1,
            ),
          ],
        ],
      ),
    );
  }

  // Header của bảng: Thứ / Ngày | Sáng | Chiều
  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Cột 1: Thứ / Ngày
          const SizedBox(
            width: 78,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                SizedBox(height: 3),
                Text(
                  'Thứ / Ngày',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 32,
            child: VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          ),

          // Cột 2: Sáng (Tiết 1 - 4)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wb_sunny_outlined, size: 13, color: Color(0xFFD97706)),
                    const SizedBox(width: 4),
                    const Text(
                      'SÁNG',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                const Text(
                  'Tiết 1 - 4 (06:45 – 10:30)',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 32,
            child: VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          ),

          // Cột 3: Chiều (Tiết 7 - 10)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wb_twilight, size: 13, color: Color(0xFF0284C7)),
                    const SizedBox(width: 4),
                    const Text(
                      'CHIỀU',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                const Text(
                  'Tiết 7 - 10 (13:45 – 17:30)',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dòng cho một ngày cụ thể (Thứ 2, ..., Thứ 7, CN)
  Widget _buildDayRow({
    required Map<String, String> dayData,
    required int dayIndex,
    required ScheduleState scheduleState,
    required bool isToday,
    required bool isLast,
  }) {
    final dayName = dayData['day'] ?? 'Thứ ${dayIndex + 2}';
    final dateStr = dayData['date'] ?? '';
    final isWeekend = dayName == 'Thứ 7' || dayName == 'CN';

    // Lấy danh sách lịch học của ngày này
    final dayItems = scheduleState.items.where((it) => it.matchesDay(dayName)).toList();

    // Buổi Sáng: Giờ bắt đầu trước 12:00
    final morningItems = dayItems.where((it) => it.startMinutes < 12 * 60).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    // Buổi Chiều (và sau 12:00)
    final afternoonItems = dayItems.where((it) => it.startMinutes >= 12 * 60).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    final Color dayColBg;
    final Color dayTextColor;

    if (isToday) {
      dayColBg = const Color(0xFFEFF6FF);
      dayTextColor = AppColors.primary;
    } else if (isWeekend) {
      dayColBg = const Color(0xFFFFF7ED);
      dayTextColor = const Color(0xFFC2410C);
    } else {
      dayColBg = const Color(0xFFF8FAFC);
      dayTextColor = AppColors.textForeground;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── CỘT TRÁI: THỨ & NGÀY ───
          Container(
            width: 78,
            decoration: BoxDecoration(
              color: dayColBg,
              border: Border(
                left: isToday
                    ? const BorderSide(color: AppColors.primary, width: 3.5)
                    : BorderSide.none,
                right: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: dayTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr.isNotEmpty ? dateStr : '—',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isToday
                        ? AppColors.primary
                        : (isWeekend ? const Color(0xFFEA580C) : AppColors.textSecondary),
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Hôm nay',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ] else if (isWeekend) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Cuối tuần',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC2410C),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ─── CỘT GIỮA: BUỔI SÁNG ───
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 85),
              decoration: BoxDecoration(
                color: isToday ? const Color(0xFFF8FAFC) : Colors.white,
                border: const Border(
                  right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              padding: const EdgeInsets.all(5),
              child: morningItems.isEmpty
                  ? _buildEmptyCell(isToday)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int k = 0; k < morningItems.length; k++) ...[
                          if (k > 0) const SizedBox(height: 5),
                          _buildClassCard(
                            item: morningItems[k],
                            sessionColor: const Color(0xFFD97706),
                            sessionBg: const Color(0xFFFFFBEB),
                            sessionBorder: const Color(0xFFFDE68A),
                            scheduleState: scheduleState,
                          ),
                        ],
                      ],
                    ),
            ),
          ),

          // ─── CỘT PHẢI: BUỔI CHIỀU ───
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 85),
              color: isToday ? const Color(0xFFF8FAFC) : Colors.white,
              padding: const EdgeInsets.all(5),
              child: afternoonItems.isEmpty
                  ? _buildEmptyCell(isToday)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int k = 0; k < afternoonItems.length; k++) ...[
                          if (k > 0) const SizedBox(height: 5),
                          _buildClassCard(
                            item: afternoonItems[k],
                            sessionColor: const Color(0xFF0284C7),
                            sessionBg: const Color(0xFFF0F9FF),
                            sessionBorder: const Color(0xFFBAE6FD),
                            scheduleState: scheduleState,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Thẻ môn học bên trong ô bảng
  Widget _buildClassCard({
    required ScheduleItem item,
    required Color sessionColor,
    required Color sessionBg,
    required Color sessionBorder,
    required ScheduleState scheduleState,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (item.isCustom) {
            ScheduleCustomDetailModal.show(
              context,
              item: item,
              days: scheduleState.days,
              weekRange: scheduleState.weekRange,
            );
          } else {
            ScheduleRoomDirectionModal.show(context, item: item);
          }
        },
        onLongPress: item.isCustom ? () => _showCustomItemOptions(item, scheduleState) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: sessionBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: sessionColor.withValues(alpha: 0.08),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tiêu đề nhỏ: Tiết học & tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                decoration: BoxDecoration(
                  color: sessionBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 9, color: sessionColor),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        item.timeSlot,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: sessionColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isCustom)
                      GestureDetector(
                        onTap: () => _showCustomItemOptions(item, scheduleState),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE68A),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFF59E0B), width: 0.5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_calendar, size: 8, color: Color(0xFF92400E)),
                              SizedBox(width: 2),
                              Text(
                                'Tự thêm',
                                style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Tên môn và phòng
              Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.courseName,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textForeground,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Phòng học
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, size: 8.5, color: AppColors.primary),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              item.room,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (item.lecturer != null && item.lecturer!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 8.5, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              item.lecturer!,
                              style: const TextStyle(
                                fontSize: 8,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Ô trống khi không có tiết
  Widget _buildEmptyCell(bool isToday) {
    return Center(
      child: Text(
        '—',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w300,
          color: isToday
              ? AppColors.primary.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.12),
        ),
      ),
    );
  }

  // Khung xương loading cho bảng
  Widget _buildTableSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: const [
              WireframeBox(width: 78, height: 36, borderRadius: 6),
              SizedBox(width: 8),
              Expanded(child: WireframeBox(width: double.infinity, height: 36, borderRadius: 6)),
              SizedBox(width: 8),
              Expanded(child: WireframeBox(width: double.infinity, height: 36, borderRadius: 6)),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < 5; i++) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: const [
                  WireframeBox(width: 78, height: 75, borderRadius: 6),
                  SizedBox(width: 8),
                  Expanded(child: WireframeBox(width: double.infinity, height: 75, borderRadius: 6)),
                  SizedBox(width: 8),
                  Expanded(child: WireframeBox(width: double.infinity, height: 75, borderRadius: 6)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── NOTICE BOX ───
  Widget _buildNoticeBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 16),
              SizedBox(width: 6),
              Text(
                'Lưu ý tiết học',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textForeground,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• Buổi sáng: Tiết 1 bắt đầu từ 06:45, Tiết 4 kết thúc lúc 10:30.\n'
            '• Buổi chiều: Tiết 7 bắt đầu từ 13:45, Tiết 10 kết thúc lúc 16:30.\n'
            '• Bấm vào bất kỳ môn học nào để xem chỉ dẫn chi tiết và vị trí tòa nhà trên bản đồ trường.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── EMPTY DAY STATE ───
  Widget _buildEmptyDayState(ScheduleState scheduleState) {
    final isWeekEmpty = scheduleState.items.isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              size: 32,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isWeekEmpty ? 'Không có lịch học' : 'Không có tiết học',
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            isWeekEmpty
                ? 'Bạn không có lịch học trong tuần này!'
                : 'Bạn được nghỉ trong ngày này!',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => _showAddScheduleModal(
              context,
              ref,
              scheduleState,
              initialDayNum: _selectedDay,
            ),
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: Text('Thêm lịch cho ${_dayNumToName(_selectedDay)}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleModal(
    BuildContext context,
    WidgetRef ref,
    ScheduleState scheduleState, {
    int? initialDayNum,
  }) {
    ScheduleAddCustomModal.show(
      context,
      days: scheduleState.days,
      weekRange: scheduleState.weekRange,
      initialDayNum: initialDayNum,
      onSave: (newItem) async {
        final success = await ref.read(scheduleProvider.notifier).addCustomSchedule(newItem);
        if (context.mounted) {
          // Tự động chuyển sang ngày của môn vừa thêm để người dùng nhìn thấy ngay
          setState(() {
            _selectedDay = newItem.dayNum;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(success ? Icons.check_circle : Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      success
                          ? 'Đã thêm lịch học "${newItem.courseName}" vào ${newItem.cleanDay}!'
                          : 'Thêm lịch học thất bại. Vui lòng thử lại.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: success ? AppColors.success : AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
    );
  }

  void _showEditScheduleModal(BuildContext context, WidgetRef ref, ScheduleState scheduleState, ScheduleItem item) {
    ScheduleAddCustomModal.show(
      context,
      initialItem: item,
      days: scheduleState.days,
      weekRange: scheduleState.weekRange,
      onSave: (updatedItem) async {
        final success = await ref.read(scheduleProvider.notifier).updateCustomSchedule(item.id, updatedItem);
        if (context.mounted) {
          setState(() {
            _selectedDay = updatedItem.dayNum;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(success ? Icons.check_circle : Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      success
                          ? 'Đã cập nhật lịch học "${updatedItem.courseName}"!'
                          : 'Cập nhật lịch học thất bại.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: success ? AppColors.success : AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      onDelete: () {
        Navigator.of(context).pop();
        _confirmDeleteSchedule(context, ref, item);
      },
    );
  }

  void _confirmDeleteSchedule(BuildContext context, WidgetRef ref, ScheduleItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Xóa lịch học', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa ca học "${item.courseName}" (${item.timeSlot}, ${item.room}) khỏi thời khóa biểu không?',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref.read(scheduleProvider.notifier).deleteCustomSchedule(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(success ? Icons.check_circle : Icons.error_outline, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            success
                                ? 'Đã xóa lịch học "${item.courseName}"!'
                                : 'Xóa lịch học thất bại.',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showCustomItemOptions(ScheduleItem item, ScheduleState scheduleState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Text(
                    'Lịch tự thêm',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.courseName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textForeground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${item.timeSlot} • ${item.room} • ${item.cleanDay}',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 6),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                child: const Icon(Icons.near_me_outlined, size: 18, color: AppColors.primary),
              ),
              title: const Text('Xem chỉ đường phòng học', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('Bóc tách vị trí, lộ trình các bước đến tòa nhà', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.of(ctx).pop();
                ScheduleRoomDirectionModal.show(context, item: item);
              },
            ),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
              ),
              title: const Text('Chỉnh sửa ca học này', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('Cập nhật tên môn, phòng học, tiết, ngày', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.of(ctx).pop();
                _showEditScheduleModal(context, ref, scheduleState, item);
              },
            ),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
              ),
              title: const Text('Xóa khỏi thời khóa biểu', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('Hủy bỏ ca học tự tạo này', style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmDeleteSchedule(context, ref, item);
              },
            ),
          ],
        ),
      ),
    );
  }
}
