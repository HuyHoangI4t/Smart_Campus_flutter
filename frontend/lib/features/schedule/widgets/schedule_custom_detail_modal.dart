import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import 'schedule_add_custom_modal.dart';
import 'schedule_room_direction_modal.dart';

class ScheduleCustomDetailModal extends ConsumerWidget {
  final ScheduleItem item;
  final List<Map<String, String>>? days;
  final String? weekRange;

  const ScheduleCustomDetailModal({
    super.key,
    required this.item,
    this.days,
    this.weekRange,
  });

  static Future<void> show(
    BuildContext context, {
    required ScheduleItem item,
    List<Map<String, String>>? days,
    String? weekRange,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScheduleCustomDetailModal(
        item: item,
        days: days,
        weekRange: weekRange,
      ),
    );
  }

  Map<String, dynamic> _getTypeConfig(String? type) {
    switch (type) {
      case 'hoc_bu':
        return {
          'label': 'Học bù',
          'color': const Color(0xFF2563EB),
          'bg': const Color(0xFFEFF6FF),
          'border': const Color(0xFFBFDBFE),
        };
      case 'kiem_tra':
        return {
          'label': 'Kiểm tra / Thi',
          'color': const Color(0xFFDC2626),
          'bg': const Color(0xFFFEF2F2),
          'border': const Color(0xFFFECACA),
        };
      case 'khac':
        return {
          'label': 'Khác',
          'color': const Color(0xFF059669),
          'bg': const Color(0xFFF0FDF4),
          'border': const Color(0xFFBBF7D0),
        };
      case 'dot_xuat':
      default:
        return {
          'label': 'Thực hành',
          'color': const Color(0xFFD97706),
          'bg': const Color(0xFFFFFBEB),
          'border': const Color(0xFFFDE68A),
        };
    }
  }

  void _handleEdit(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pop();
    ScheduleAddCustomModal.show(
      context,
      initialItem: item,
      days: days,
      weekRange: weekRange,
      onSave: (updatedItem) async {
        final success = await ref.read(scheduleProvider.notifier).updateCustomSchedule(item.id, updatedItem);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(success ? Icons.check_circle : Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      success ? 'Đã cập nhật lịch học "${updatedItem.courseName}"!' : 'Cập nhật lịch học thất bại',
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
        _confirmDelete(context, ref);
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
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
          'Bạn có chắc chắn muốn xóa ca học "${item.courseName}" (${item.timeSlot}, ${item.room}) khỏi thời khóa biểu?',
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
                            success ? 'Đã xóa lịch học "${item.courseName}"!' : 'Xóa lịch học thất bại',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeConfig = _getTypeConfig(item.type);
    final String dateDisplay = item.date != null && item.date!.isNotEmpty
        ? '${item.cleanDay}, ngày ${item.date}'
        : item.cleanDay;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── 1. MODAL HEADER ───
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.event_note, color: Color(0xFFD97706), size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chi tiết lịch học',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textForeground,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Lịch học do bạn tự thêm',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // ─── 2. MODAL BODY ───
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // Info Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge loại lịch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: typeConfig['bg'] as Color,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: typeConfig['border'] as Color, width: 0.8),
                            ),
                            child: Text(
                              typeConfig['label'] as String,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: typeConfig['color'] as Color,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDE68A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Tự thêm',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Tên môn học
                      Text(
                        item.courseName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textForeground,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Hàng ngày học
                      _buildInfoRow(
                        icon: Icons.calendar_month_outlined,
                        iconColor: const Color(0xFF0284C7),
                        title: 'Ngày học',
                        content: dateDisplay,
                      ),
                      const SizedBox(height: 10),

                      // Hàng tiết học
                      _buildInfoRow(
                        icon: Icons.schedule_outlined,
                        iconColor: const Color(0xFFD97706),
                        title: 'Tiết học',
                        content: item.timeSlot,
                      ),
                      const SizedBox(height: 10),

                      // Hàng phòng học
                      _buildInfoRow(
                        icon: Icons.location_on_outlined,
                        iconColor: AppColors.primary,
                        title: 'Phòng học',
                        content: item.room,
                      ),

                      // Hàng giảng viên (nếu có)
                      if (item.lecturer != null && item.lecturer!.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFF64748B),
                          title: 'Giảng viên',
                          content: item.lecturer!,
                        ),
                      ],

                      // Hàng ghi chú (nếu có)
                      if (item.note != null && item.note!.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.notes, size: 14, color: Color(0xFF64748B)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Ghi chú cá nhân',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.note!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textForeground,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ─── 3. ACTION BUTTONS: SỬA & XÓA ───
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleEdit(context, ref),
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: const Text(
                          'Chỉnh sửa',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _confirmDelete(context, ref);
                        },
                        icon: const Icon(Icons.delete_outline, size: 17, color: Color(0xFFDC2626)),
                        label: const Text(
                          'Xóa ca',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Nút phụ: Xem chỉ đường phòng học
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScheduleRoomDirectionModal.show(context, item: item);
                  },
                  icon: const Icon(Icons.near_me_outlined, size: 16, color: AppColors.primary),
                  label: const Text(
                    'Xem hướng dẫn chỉ đường đến phòng',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textForeground,
            ),
          ),
        ),
      ],
    );
  }
}

