import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/schedule_model.dart';
import '../models/room_direction_model.dart';

class ScheduleCard extends StatelessWidget {
  final ScheduleItem item;
  final ValueChanged<ScheduleItem> onSelectDirection;
  final ValueChanged<ScheduleItem>? onEdit;
  final ValueChanged<ScheduleItem>? onDelete;

  const ScheduleCard({
    super.key,
    required this.item,
    required this.onSelectDirection,
    this.onEdit,
    this.onDelete,
  });

  Map<String, dynamic> _getTypeConfig() {
    if (!item.isCustom) {
      return {
        'label': 'Chính khóa',
        'color': const Color(0xFF4338CA),
        'bg': const Color(0xFFEEF2FF),
        'border': const Color(0xFFC7D2FE),
        'accent': const Color(0xFF4F46E5),
      };
    }

    switch (item.type) {
      case 'hoc_bu':
        return {
          'label': 'Học bù',
          'color': const Color(0xFF2563EB),
          'bg': const Color(0xFFEFF6FF),
          'border': const Color(0xFFBFDBFE),
          'accent': const Color(0xFF3B82F6),
        };
      case 'kiem_tra':
        return {
          'label': 'Kiểm tra / Thi',
          'color': const Color(0xFFDC2626),
          'bg': const Color(0xFFFEF2F2),
          'border': const Color(0xFFFECACA),
          'accent': const Color(0xFFEF4444),
        };
      case 'khac':
        return {
          'label': 'Khác',
          'color': const Color(0xFF059669),
          'bg': const Color(0xFFF0FDF4),
          'border': const Color(0xFFBBF7D0),
          'accent': const Color(0xFF10B981),
        };
      case 'dot_xuat':
      default:
        return {
          'label': 'Thực hành',
          'color': const Color(0xFFD97706),
          'bg': const Color(0xFFFFFBEB),
          'border': const Color(0xFFFDE68A),
          'accent': const Color(0xFFF59E0B),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeConfig = _getTypeConfig();
    final Color accentColor = typeConfig['accent'] as Color;
    final RoomDirectionInfo direction = item.roomDirection;

    String locationDisplay = item.room;
    if (direction.buildingCode.isNotEmpty && !item.room.contains(direction.buildingCode)) {
      locationDisplay = '${item.room} • ${direction.buildingCode}';
    }

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
    final todayDayName = weekdayMap[now.weekday] ?? '';
    final isToday = item.matchesDay(todayDayName);
    final nowMinutes = now.hour * 60 + now.minute;
    final isOngoing = isToday && nowMinutes >= item.startMinutes && nowMinutes <= item.endMinutes;
    final isCompleted = isToday && nowMinutes > item.endMinutes;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOngoing ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
          width: isOngoing ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isOngoing
                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 3),
            blurRadius: isOngoing ? 10 : 8,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Left accent stripe
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4.5,
            child: Container(
              color: isOngoing ? const Color(0xFF10B981) : accentColor,
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── ROW 1: TIME BADGE + TYPE TAG ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Time Capsule
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOngoing ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isOngoing ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_filled,
                            size: 13,
                            color: isOngoing ? const Color(0xFF059669) : const Color(0xFF475569),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${item.startTime} – ${item.endTime}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isOngoing ? const Color(0xFF065F46) : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '• ${item.periodDisplay}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isOngoing ? const Color(0xFF047857) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Type & Status Badges
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isOngoing)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF6EE7B7)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 6, color: Color(0xFF059669)),
                                SizedBox(width: 3),
                                Text(
                                  'Đang học',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isCompleted)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Đã qua',
                              style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                            ),
                          ),
                        if (item.isCustom)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: const Text(
                              'Tự thêm',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: typeConfig['bg'] as Color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: typeConfig['border'] as Color),
                          ),
                          child: Text(
                            typeConfig['label'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: typeConfig['color'] as Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ─── ROW 2: COURSE NAME ───
                Text(
                  item.courseName,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textForeground,
                    height: 1.25,
                    letterSpacing: -0.2,
                  ),
                ),

                const SizedBox(height: 10),

                // ─── ROW 3: ROOM + LECTURER CHIPS ───
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // Room chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            locationDisplay,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Lecturer chip (if present)
                    if (item.lecturer != null && item.lecturer!.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_outline, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              item.lecturer!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // ─── ROW 4: NOTE (IF PRESENT) ───
                if (item.note != null && item.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.sticky_note_2_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.note!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF475569),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // ─── ROW 5: ACTION BUTTONS ───
                Row(
                  children: [
                    // Nút "Chỉ đường"
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onSelectDirection(item),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFC7D2FE)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.near_me, size: 14, color: AppColors.primary),
                                SizedBox(width: 6),
                                Text(
                                  'Chỉ đường tới phòng',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Nếu là lịch tự tạo: Thêm nút Sửa & Xóa
                    if (item.isCustom) ...[
                      const SizedBox(width: 8),
                      if (onEdit != null)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onEdit!(item),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFBAE6FD)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_outlined, size: 15, color: Color(0xFF0284C7)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Sửa',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 6),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onDelete!(item),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_outline, size: 15, color: Color(0xFFDC2626)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Xóa',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

