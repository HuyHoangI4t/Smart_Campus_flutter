import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/nav_header.dart';
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
      'label': 'Tuần này (05/10 - 11/10)',
      'isNext': false,
    },
    {
      'label': 'Tuần sau (12/10 - 18/10)',
      'isNext': true,
    },
    {
      'label': 'Tuần 03 (19/10 - 25/10)',
      'isNext': false,
    },
    {
      'label': 'Tuần 04 (26/10 - 01/11)',
      'isNext': false,
    },
  ];

  final List<Map<String, String>> _days = [
    {'day': 'Thứ 2', 'date': '12/10'},
    {'day': 'Thứ 3', 'date': '13/10'},
    {'day': 'Thứ 4', 'date': '14/10'},
    {'day': 'Thứ 5', 'date': '15/10'},
    {'day': 'Thứ 6', 'date': '16/10'},
    {'day': 'Thứ 7', 'date': '17/10'},
    {'day': 'CN', 'date': '18/10'},
  ];

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleProvider);
    final items = scheduleState.filteredItems;
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

          // ─── 2. WEEK SELECTOR BAR ───
          _buildWeekBar(scheduleState),

          // ─── 3. SUNDAY / NEXT WEEK ALERT ───
          if (scheduleState.isSunday) _buildSundayAlert(),

          // ─── 4. DAY SELECTOR BAR ───
          _buildDayBar(scheduleState),

          // ─── 5. SCHEDULE LIST CONTENT ───
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(scheduleProvider.notifier).fetchSchedule(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  if (items.isEmpty) ...[
                    _buildEmptySchedule(),
                  ] else
                    for (final item in items) ...[
                      _buildScheduleCard(context, item, scheduleState),
                      const SizedBox(height: 14),
                    ],

                  // Information note box
                  _buildNoticeBox(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── WEEK SELECTOR BAR ───
  Widget _buildWeekBar(ScheduleState scheduleState) {
    final weeks = scheduleState.availableWeeks.isNotEmpty ? scheduleState.availableWeeks : _weeks;

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(weeks.length, (index) {
            final w = weeks[index];
            final wIdx = w['index'] is int ? w['index'] as int : index;
            final isSelected = wIdx == scheduleState.selectedWeekIndex;

            return GestureDetector(
              onTap: () {
                ref.read(scheduleProvider.notifier).selectWeek(wIdx);
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.cardBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      w['label'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.text,
                      ),
                    ),
                    if (w['isNext'] == true) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.22)
                              : AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Tuần tới',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─── SUNDAY ALERT BANNER ───
  Widget _buildSundayAlert() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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

  // ─── DAY SELECTOR BAR ───
  Widget _buildDayBar(ScheduleState scheduleState) {
    final days = scheduleState.days.isNotEmpty ? scheduleState.days : _days;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(days.length, (index) {
            final d = days[index];
            final dayName = d['day'] ?? 'Thứ 2';
            final isSelected = dayName == scheduleState.selectedDay ||
                scheduleState.selectedDay.contains(dayName) ||
                (dayName == 'CN' && (scheduleState.selectedDay == 'Chủ nhật' || scheduleState.selectedDay == 'CN'));

            return GestureDetector(
              onTap: () {
                ref.read(scheduleProvider.notifier).selectDay(dayName);
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                constraints: const BoxConstraints(minWidth: 62),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.cardBorder,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : AppColors.text,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      d['date'] ?? '',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─── SCHEDULE CARD FOR REAL ITEMS ───
  Widget _buildScheduleCard(BuildContext context, ScheduleItem item, ScheduleState scheduleState) {
    final activeDays = scheduleState.days.isNotEmpty ? scheduleState.days : _days;
    final dayInfo = activeDays.firstWhere(
      (d) => item.matchesDay(d['day'] ?? ''),
      orElse: () => activeDays.isNotEmpty ? activeDays.first : <String, String>{},
    );
    final dateDisplay = item.dateShort ?? dayInfo['date'] ?? '';
    final fullDateDisplay = item.date ?? dayInfo['fullDate'] ?? (dateDisplay.isNotEmpty ? '$dateDisplay/2026' : '');
    final dayLabel = item.dayOfWeek.contains('/') ? item.dayOfWeek : '${item.cleanDay} $dateDisplay';

    final schedStatus = item.getScheduleStatus(targetDateStr: fullDateDisplay);
    final Color statusBg;
    final Color statusBorder;
    final Color statusColor;
    final IconData statusIcon;
    final String statusText;

    switch (schedStatus) {
      case ScheduleStatus.ongoing:
        statusBg = AppColors.success.withValues(alpha: 0.12);
        statusBorder = AppColors.success.withValues(alpha: 0.35);
        statusColor = AppColors.success;
        statusIcon = Icons.radio_button_checked;
        statusText = 'Đang diễn ra';
        break;
      case ScheduleStatus.completed:
        statusBg = const Color(0xFFF1F5F9);
        statusBorder = const Color(0xFFE2E8F0);
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.check_circle_outline;
        statusText = 'Đã kết thúc';
        break;
      case ScheduleStatus.upcoming:
        statusBg = AppColors.info.withValues(alpha: 0.1);
        statusBorder = AppColors.info.withValues(alpha: 0.3);
        statusColor = AppColors.info;
        statusIcon = Icons.access_time;
        statusText = 'Sắp tới';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dayLabel.trim(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textForeground,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: statusBorder,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 10, color: statusColor),
                    const SizedBox(width: 3),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 10, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Text(
                    fullDateDisplay.isNotEmpty ? fullDateDisplay : item.cleanDay,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    item.timeSlot,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.courseName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.textForeground,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        item.room,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textForeground,
                        ),
                      ),
                    ],
                  ),
                  if (item.lecturer != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          item.lecturer!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              GestureDetector(
                onTap: () => ScheduleRoomDirectionModal.show(context, item: item),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.near_me, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Chỉ đường',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── EMPTY SCHEDULE STATE ───
  Widget _buildEmptySchedule() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_outlined,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Không có lịch học trong ngày này',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textForeground,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bạn có thể nghỉ ngơi hoặc bấm "Thêm lịch" để thêm lịch cá nhân.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
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
      padding: const EdgeInsets.all(16),
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
            '• Bấm "Chỉ đường" để xem chỉ dẫn chi tiết và vị trí tòa nhà trên bản đồ trường.',
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
      },
    );
  }
}
