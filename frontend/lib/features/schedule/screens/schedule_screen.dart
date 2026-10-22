import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/nav_header.dart';
import '../../../core/widgets/wireframe_widgets.dart';
import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import '../widgets/schedule_add_custom_modal.dart';
import '../widgets/schedule_room_direction_modal.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  final List<Map<String, dynamic>> _weeks = [
    {
      'index': 0,
      'label': 'Tuần trước',
      'isCurrent': false,
      'isNext': false,
    },
    {
      'index': 1,
      'label': 'Tuần này',
      'isCurrent': true,
      'isNext': false,
    },
    {
      'index': 2,
      'label': 'Tuần sau',
      'isCurrent': false,
      'isNext': true,
    },
    {
      'index': 3,
      'label': '2 tuần sau',
      'isCurrent': false,
      'isNext': false,
    },
  ];

  final List<Map<String, String>> _days = [
    {'day': 'Thứ 2', 'date': '19/10'},
    {'day': 'Thứ 3', 'date': '20/10'},
    {'day': 'Thứ 4', 'date': '21/10'},
    {'day': 'Thứ 5', 'date': '22/10'},
    {'day': 'Thứ 6', 'date': '23/10'},
    {'day': 'Thứ 7', 'date': '24/10'},
    {'day': 'CN', 'date': '25/10'},
  ];

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleProvider);
    final weekSubtitle = scheduleState.weekRange.isNotEmpty
        ? scheduleState.weekRange
        : 'Từ ngày 19/10/2026 đến ngày 25/10/2026';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ─── 1. NAVHEADER (Navy #132F73) ───
          NavHeader(
            title: 'Thời khóa biểu',
            subtitle: weekSubtitle,
            rightElement: GestureDetector(
              onTap: () => _showAddScheduleModal(context, ref, scheduleState),
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

          // ─── 2. THANH ĐIỀU HƯỚNG TUẦN (WEEK NAVIGATOR HIỆN ĐẠI) ───
          _buildWeekNavigator(scheduleState),

          // ─── 3. SUNDAY / NEXT WEEK ALERT ───
          if (scheduleState.isSunday) _buildSundayAlert(),

          // ─── 4. MAIN SCHEDULE TABLE (Thứ theo chiều dọc, chỉ Sáng & Chiều) ───
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(scheduleProvider.notifier).fetchSchedule(forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hint bar
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.touch_app_outlined, size: 14, color: AppColors.primary),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Thời khóa biểu 7 ngày (T2 - CN) • Chạm vào ô để xem chỉ đường',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Table Card
                    if (scheduleState.isLoading)
                      _buildTableSkeleton()
                    else
                      _buildVerticalTimetable(scheduleState),

                    const SizedBox(height: 14),

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

  // ─── THANH ĐIỀU HƯỚNG TUẦN HIỆN ĐẠI (WEEK NAVIGATOR) ───
  Widget _buildWeekNavigator(ScheduleState scheduleState) {
    final weeks = scheduleState.availableWeeks.isNotEmpty ? scheduleState.availableWeeks : _weeks;
    final currentIdx = scheduleState.selectedWeekIndex;
    final canPrev = currentIdx > 0;
    final canNext = currentIdx < weeks.length - 1;

    // Dữ liệu tuần đang chọn
    final currentWeekData = weeks.firstWhere(
      (w) => (w['index'] is int ? w['index'] as int : 0) == currentIdx,
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

    // Tìm index của 4 tuần cốt lõi: Tuần trước (-1), Tuần này (0), Tuần sau (+1), 2 tuần sau (+2)
    final curIdx = scheduleState.currentWeekIndex;
    int? prevIdx;
    int? thisIdx;
    int? nextIdx;
    int? twoAfterIdx;

    for (int i = 0; i < weeks.length; i++) {
      final w = weeks[i];
      final wIdx = w['index'] is int ? w['index'] as int : i;
      final lbl = (w['label']?.toString() ?? '').toLowerCase();
      final diff = wIdx - curIdx;

      if (diff == -1 || lbl.contains('tuần trước')) {
        prevIdx ??= wIdx;
      }
      if (diff == 0 || w['isCurrent'] == true || lbl.contains('tuần này')) {
        thisIdx ??= wIdx;
      }
      if (diff == 1 || (lbl.contains('tuần sau') && !lbl.contains('2 tuần'))) {
        nextIdx ??= wIdx;
      }
      if (diff == 2 || lbl.contains('2 tuần sau')) {
        twoAfterIdx ??= wIdx;
      }
    }

    thisIdx ??= curIdx;
    prevIdx ??= (curIdx > 0 ? curIdx - 1 : null);
    nextIdx ??= (curIdx + 1 < weeks.length ? curIdx + 1 : null);
    twoAfterIdx ??= (curIdx + 2 < weeks.length ? curIdx + 2 : null);

    final quickTabs = [
      {'label': 'Tuần trước', 'index': prevIdx},
      {'label': 'Tuần này', 'index': thisIdx},
      {'label': 'Tuần sau', 'index': nextIdx},
      {'label': '2 tuần sau', 'index': twoAfterIdx},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dòng 1: Điều hướng tuần kèm nút mở chọn tất cả các tuần
          Row(
            children: [
              // Nút Tuần trước ◀
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canPrev
                      ? () => ref.read(scheduleProvider.notifier).selectWeek(currentIdx - 1)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: canPrev ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: canPrev ? AppColors.textForeground : const Color(0xFFCBD5E1),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Nút trung tâm chọn tuần (Bấm vào mở danh sách toàn bộ các tuần)
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showWeekPickerSheet(context, scheduleState, weeks),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              displayTitle,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Nút Tuần sau ▶
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canNext
                      ? () => ref.read(scheduleProvider.notifier).selectWeek(currentIdx + 1)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: canNext ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: canNext ? AppColors.textForeground : const Color(0xFFCBD5E1),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Dòng 2: 4 Nút chọn tuần nhanh: [ Tuần trước ] [ Tuần này ] [ Tuần sau ] [ 2 tuần sau ]
          Row(
            children: quickTabs.map((tab) {
              final tabIdx = tab['index'] as int?;
              final isTabSelected = tabIdx != null && tabIdx == currentIdx;
              final isTabEnabled = tabIdx != null;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isTabEnabled
                          ? () => ref.read(scheduleProvider.notifier).selectWeek(tabIdx)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: isTabSelected
                              ? AppColors.primary
                              : (isTabEnabled ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isTabSelected
                                ? AppColors.primary
                                : (isTabEnabled ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9)),
                            width: 1,
                          ),
                          boxShadow: isTabSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.28),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            tab['label'] as String,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isTabSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isTabSelected
                                  ? Colors.white
                                  : (isTabEnabled ? const Color(0xFF334155) : const Color(0xFF94A3B8)),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
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
  Widget _buildSundayAlert() {
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
          const Expanded(
            child: Text(
              'Hôm nay là Chủ nhật: Đang xem trước lịch học Tuần sau',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1E40AF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(scheduleProvider.notifier).selectWeek(0);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF93C5FD)),
              ),
              child: const Text(
                'Xem tuần này',
                style: TextStyle(
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
    final days = scheduleState.days.isNotEmpty ? scheduleState.days : _days;
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
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ScheduleRoomDirectionModal.show(context, item: item),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE68A),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'Tự thêm',
                          style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
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

  void _showAddScheduleModal(BuildContext context, WidgetRef ref, ScheduleState scheduleState) {
    ScheduleAddCustomModal.show(
      context,
      days: scheduleState.days,
      onSave: (newItem) {
        ref.read(scheduleProvider.notifier).addCustomSchedule(newItem);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm lịch học "${newItem.courseName}"'),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );
  }
}
