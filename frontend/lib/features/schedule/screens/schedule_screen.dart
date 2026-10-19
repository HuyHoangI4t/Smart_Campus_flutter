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
  int _selectedWeekIndex = 1; // 0: Tuần này, 1: Tuần sau
  int _selectedDayIndex = 0; // 0: Thứ 2 ... 6: CN

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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ─── 1. NAVHEADER (Navy #132F73) ───
          NavHeader(
            title: 'Thời khóa biểu',
            subtitle: _selectedWeekIndex == 1
                ? 'Từ ngày 12/10/2026 đến ngày 18/10/2026'
                : 'Từ ngày 05/10/2026 đến ngày 11/10/2026',
            rightElement: GestureDetector(
              onTap: () => _showAddScheduleModal(context, ref),
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
          _buildWeekBar(),

          // ─── 3. SUNDAY / NEXT WEEK ALERT ───
          if (_selectedWeekIndex == 1) _buildSundayAlert(),

          // ─── 4. DAY SELECTOR BAR ───
          _buildDayBar(),

          // ─── 5. SCHEDULE LIST CONTENT ───
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(scheduleProvider.notifier).fetchSchedule(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  if (items.isEmpty)
                    _buildEmptySchedule()
                  else
                    for (final item in items) ...[
                      _buildScheduleCard(context, item),
                      const SizedBox(height: 14),
                    ],

                  // Default sample class if list is empty to match screenshot
                  if (items.isEmpty) ...[
                    _buildSampleScheduleCard(context),
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
  Widget _buildWeekBar() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_weeks.length, (index) {
            final w = _weeks[index];
            final isSelected = index == _selectedWeekIndex;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedWeekIndex = index;
                });
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
              setState(() {
                _selectedWeekIndex = 0;
              });
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
  Widget _buildDayBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_days.length, (index) {
            final d = _days[index];
            final isSelected = index == _selectedDayIndex;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDayIndex = index;
                });
                ref.read(scheduleProvider.notifier).selectDay(d['day']!);
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
                      d['day']!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : AppColors.text,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      d['date']!,
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

  // ─── SAMPLE SCHEDULE CARD MATCHING SCREENSHOT ───
  Widget _buildSampleScheduleCard(BuildContext context) {
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
          // Row 1: Day Tag + Status Pill + Date + Period
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Thứ 2 12/10',
                  style: TextStyle(
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
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 10, color: AppColors.info),
                    SizedBox(width: 3),
                    Text(
                      'Sắp tới',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Row(
                children: [
                  Icon(Icons.calendar_today, size: 10, color: AppColors.primary),
                  SizedBox(width: 3),
                  Text(
                    '12/10/2026',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Row(
                children: [
                  Icon(Icons.schedule, size: 12, color: AppColors.textSecondary),
                  SizedBox(width: 4),
                  Text(
                    'Tiết 1-4',
                    style: TextStyle(
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

          // Course Title
          const Text(
            'LS Đảng CS VN',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.textForeground,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),

          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Bottom Row: Room + Lecturer + Navigation Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        '2.21 (CLC)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textForeground,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.info_outline, size: 12, color: AppColors.textMuted),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Đoàn Văn Kỳ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => ScheduleRoomDirectionModal.show(
                  context,
                  item: const ScheduleItem(
                    id: 1,
                    courseName: 'LS Đảng CS VN',
                    room: '2.21 (CLC)',
                    dayOfWeek: 'Thứ 2',
                    timeSlot: 'Tiết 1-4',
                    lecturer: 'Đoàn Văn Kỳ',
                  ),
                ),
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

  // ─── SCHEDULE CARD FOR REAL ITEMS ───
  Widget _buildScheduleCard(BuildContext context, ScheduleItem item) {
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
                  '${item.dayOfWeek} ${_days[_selectedDayIndex]['date']}',
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
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 10, color: AppColors.info),
                    SizedBox(width: 3),
                    Text(
                      'Sắp tới',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.info,
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
                    '${_days[_selectedDayIndex]['date']}/2026',
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
    return const SizedBox.shrink();
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

  void _showAddScheduleModal(BuildContext context, WidgetRef ref) {
    ScheduleAddCustomModal.show(
      context,
      onSave: (newItem) {
        ref.read(scheduleProvider.notifier).addCustomSchedule(newItem);
      },
    );
  }
}
