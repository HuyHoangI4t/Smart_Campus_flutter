import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/url_launcher_helper.dart';
import '../models/schedule_model.dart';
import '../models/room_direction_model.dart';

class ScheduleRoomDirectionModal extends StatelessWidget {
  final ScheduleItem item;

  const ScheduleRoomDirectionModal({
    super.key,
    required this.item,
  });

  static Future<void> show(BuildContext context, {required ScheduleItem item}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScheduleRoomDirectionModal(item: item),
    );
  }

  void _handleCopyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Đã sao chép mã phòng "$code" vào bộ nhớ tạm!')),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleOpenMeet(String url, String? code) async {
    await AppUrlLauncher.openGoogleMeet(
      url: url,
      code: code,
    );
  }

  @override
  Widget build(BuildContext context) {
    final RoomDirectionInfo direction = item.roomDirection;
    final bool isOnline = item.isOnline;
    final String? meetingUrl = item.onlineMeetingUrl;
    final String? meetingCode = item.onlineMeetingCode;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFFEFF6FF) : const Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isOnline ? Icons.videocam : Icons.near_me,
                          color: isOnline ? const Color(0xFF2563EB) : AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isOnline ? 'Lớp học trực tuyến (Online)' : 'Chỉ đường phòng học',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textForeground,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
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
                // Course Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isOnline ? const Color(0xFFF8FAFC) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isOnline ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.courseName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textForeground,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tags Row: Room + Floor (if any) + Building
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOnline ? const Color(0xFF2563EB) : AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOnline ? (item.room.isNotEmpty ? item.room : 'Online') : direction.room,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOnline ? const Color(0xFFEFF6FF) : const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOnline ? 'Học từ xa' : (direction.floor.isNotEmpty ? direction.floor : 'Tầng 1'),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isOnline ? const Color(0xFF2563EB) : AppColors.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOnline ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOnline ? 'Google Meet / Trực tuyến' : direction.buildingCode,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isOnline ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Meta items
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 6),
                          Text(
                            item.timeSlot,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (item.lecturer != null && item.lecturer!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 6),
                            Text(
                              item.lecturer!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            isOnline ? Icons.monitor : Icons.domain_outlined,
                            size: 14,
                            color: isOnline ? const Color(0xFF2563EB) : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isOnline ? 'Không gian số (Học Online qua mạng)' : direction.building,
                              style: TextStyle(
                                fontSize: 12,
                                color: isOnline ? const Color(0xFF1D4ED8) : AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ─── NẾU LÀ ONLINE: HIỂN THỊ MÃ PHÒNG VÀ NÚT COPY THAY VÌ LỘ TRÌNH ĐI BỘ ───
                if (isOnline) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDBEAFE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.videocam, color: Color(0xFF2563EB), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Mã tham gia phòng học',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0369A1),
                                    ),
                                  ),
                                  Text(
                                    item.note ?? direction.meetingInfo ?? 'Google Meet phòng học',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (meetingCode != null && meetingCode.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE0F2FE)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'MÃ PHÒNG (MEET CODE)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF94A3B8),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      SelectableText(
                                        meetingCode,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0284C7),
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _handleCopyCode(context, meetingCode),
                                  icon: const Icon(Icons.copy, size: 14),
                                  label: const Text('Sao chép', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // ─── NẾU LÀ OFFLINE: LỘ TRÌNH DI CHUYỂN CHI TIẾT ───
                  const Text(
                    'Lộ trình di chuyển chi tiết',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textForeground,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Steps Timeline
                  Column(
                    children: List.generate(direction.steps.length, (idx) {
                      final step = direction.steps[idx];
                      final isFirst = idx == 0;
                      final isLast = idx == direction.steps.length - 1;

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isFirst ? AppColors.primary : const Color(0xFFEEF2FF),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isFirst ? AppColors.primary : const Color(0xFFC7D2FE),
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      step.iconData,
                                      size: 15,
                                      color: isFirst ? Colors.white : AppColors.primary,
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: const Color(0xFFE2E8F0),
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${step.step}. ${step.title}',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textForeground,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      step.desc,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                ],

                // Tiện ích & Lưu ý Green Box
                if (direction.tips.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF16A34A)),
                            const SizedBox(width: 8),
                            Text(
                              isOnline ? 'Lưu ý khi tham gia học Online' : 'Tiện ích & Lưu ý',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...direction.tips.map((tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '• ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF16A34A),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF15803D),
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // ─── ACTION BUTTONS DƯỚI ĐÁY ───
                if (isOnline) ...[
                  if (meetingUrl != null && meetingUrl.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => _handleOpenMeet(meetingUrl, meetingCode),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text(
                        'Tham gia Google Meet ngay',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  if (meetingCode != null && meetingCode.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _handleCopyCode(context, meetingCode),
                      icon: const Icon(Icons.copy, size: 16),
                      label: Text(
                        'Sao chép mã phòng ($meetingCode)',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF93C5FD)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ] else ...[
                  // Action cho lớp Offline: Xem trên Bản đồ trường
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      final query = direction.building.isNotEmpty
                          ? direction.building
                          : (direction.mapQuery.isNotEmpty ? direction.mapQuery : direction.buildingCode);
                      final roomParam = item.room.isNotEmpty
                          ? (direction.floor.isNotEmpty && !item.room.toLowerCase().contains('tầng')
                              ? '${item.room} (${direction.floor})'
                              : item.room)
                          : direction.room;
                      context.go('/map?building=${Uri.encodeComponent(query)}&room=${Uri.encodeComponent(roomParam)}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Xem trên Bản đồ trường',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Đóng lại',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
