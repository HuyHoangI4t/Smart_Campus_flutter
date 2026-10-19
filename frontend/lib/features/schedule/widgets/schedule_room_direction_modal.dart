import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../models/schedule_model.dart';

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

  @override
  Widget build(BuildContext context) {
    // Extract building code/name from room e.g. "2.21 (CLC)" -> "Nhà 2", "9.2.04" -> "Nhà 9"
    final roomStr = item.room;
    final buildingCode = _extractBuildingCode(roomStr);
    final buildingName = _extractBuildingName(roomStr);

    return Container(
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
          // ─── 1. HEADER ───
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
                        color: Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.near_me, color: AppColors.primary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Chỉ đường phòng học',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textForeground,
                      ),
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

          // ─── 2. CONTENT ───
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x060F172A),
                        offset: Offset(0, 3),
                        blurRadius: 8,
                      ),
                    ],
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
                      const SizedBox(height: 8),

                      // Badges: Room + Building
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Phòng $roomStr',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              buildingCode,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
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
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
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
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.menu_book_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            buildingName,
                            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Lộ trình di chuyển chi tiết
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
                _buildTimelineStep(
                  stepNum: 1,
                  icon: Icons.explore_outlined,
                  isFirst: true,
                  isLast: false,
                  title: '1. Cổng trường',
                  desc: 'Từ cổng đi thẳng qua trục đường trung tâm hướng về phía $buildingCode.',
                ),
                _buildTimelineStep(
                  stepNum: 2,
                  icon: Icons.home_outlined,
                  isFirst: false,
                  isLast: false,
                  title: '2. Vào sảnh chính $buildingCode',
                  desc: 'Bước vào sảnh chính $buildingCode, có thể tra cứu sơ đồ phân phòng tại bảng thông báo sảnh.',
                ),
                _buildTimelineStep(
                  stepNum: 3,
                  icon: Icons.location_on_outlined,
                  isFirst: false,
                  isLast: true,
                  title: '3. Đến Phòng $roomStr',
                  desc: 'Đi theo biển chỉ dẫn số phòng tại khu vực $buildingCode, Phòng $roomStr nằm ở vị trí tương ứng.',
                ),
                const SizedBox(height: 16),

                // Tiện ích & Lưu ý Green Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF16A34A)),
                          SizedBox(width: 8),
                          Text(
                            'Tiện ích & Lưu ý',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Nhà xe thường đông vào đầu ca học, bạn có thể thử nhà xe khác để nhanh hơn.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF15803D), height: 1.45),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Nên đến trước giờ vào lớp 5 - 10 phút để ổn định vị trí và điểm danh.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF15803D), height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Actions: Xem trên Bản đồ trường
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/map?building=${Uri.encodeComponent(buildingCode)}');
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

  Widget _buildTimelineStep({
    required int stepNum,
    required IconData icon,
    required bool isFirst,
    required bool isLast,
    required String title,
    required String desc,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Badge + Vertical Line
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
                    icon,
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

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textForeground,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
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
  }

  String _extractBuildingCode(String room) {
    if (room.startsWith('2.') || room.startsWith('2_') || room.contains('Nhà 2')) {
      return 'Nhà 2';
    }
    if (room.startsWith('9.') || room.startsWith('9_') || room.contains('Nhà 9')) {
      return 'Nhà 9';
    }
    if (room.startsWith('7.') || room.startsWith('7_') || room.contains('Nhà 7')) {
      return 'Nhà 7';
    }
    return 'Nhà học';
  }

  String _extractBuildingName(String room) {
    if (room.startsWith('2.') || room.startsWith('2_')) {
      return 'Nhà học số 2';
    }
    if (room.startsWith('9.') || room.startsWith('9_')) {
      return 'Giảng đường Nhà 9';
    }
    if (room.startsWith('7.') || room.startsWith('7_')) {
      return 'Giảng đường Nhà 7';
    }
    return 'Khu giảng đường trung tâm';
  }
}

