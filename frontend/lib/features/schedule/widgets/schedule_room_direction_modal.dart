import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final RoomDirectionInfo direction = item.roomDirection;

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

          // ─── 2. MODAL BODY ───
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // Course Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
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
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              direction.room,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (direction.floor.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                direction.floor,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              direction.buildingCode,
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
                          const Icon(Icons.domain_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              direction.building,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
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

                // Steps Timeline (Dựa trên direction.steps đã bóc tách động)
                Column(
                  children: List.generate(direction.steps.length, (idx) {
                    final step = direction.steps[idx];
                    final isFirst = idx == 0;
                    final isLast = idx == direction.steps.length - 1;

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

                          // Content
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
                        const Row(
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

                // Action: Xem trên Bản đồ trường
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    final query = direction.mapQuery.isNotEmpty ? direction.mapQuery : direction.buildingCode;
                    context.go('/map?building=${Uri.encodeComponent(query)}');
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
}
