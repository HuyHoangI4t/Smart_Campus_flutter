import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/wireframe_widgets.dart';
import '../../schedule/models/schedule_model.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../schedule/widgets/schedule_room_direction_modal.dart';
import '../providers/home_provider.dart';

/// Thẻ Lớp học tiếp theo (NextClassCard) - Chuẩn thiết kế Hybrid Android 16 & iOS HIG
/// Khi đang tải hoặc chưa có dữ liệu từ DB/cache, hiển thị Wireframe skeleton hoặc empty state chuẩn.
class HomeNextClassCard extends ConsumerWidget {
  const HomeNextClassCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleState = ref.watch(scheduleProvider);
    final nextClass = ref.watch(nextClassProvider);

    // 1. Trạng thái đang tải từ DB/mạng -> Hiển thị Wireframe Skeleton Shimmer
    if (scheduleState.isLoading) {
      return const WireframeNextClassCard();
    }

    final ScheduleItem? item = nextClass.item;
    final direction = item?.roomDirection;

    // 2. Trạng thái không có dữ liệu từ DB/cache -> Hiển thị Wireframe Card thông báo thực tế
    if (item == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              offset: const Offset(0, 6),
              blurRadius: 12,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy, size: 11, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'CHƯA CÓ LỊCH HỌC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Khu giảng đường',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Không có ca học nào sắp tới',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hôm nay hoặc các ngày tới không có lịch học trong hệ thống',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => context.push('/schedule'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month, color: AppColors.textLight, size: 12),
                      SizedBox(width: 6),
                      Text(
                        'Xem lịch học →',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 3. Trạng thái có dữ liệu môn học thực tế
    Color indicatorColor;
    if (nextClass.isOngoing) {
      indicatorColor = const Color(0xFF10B981); // Green
    } else if (nextClass.capsuleLabel.contains('HÔM NAY')) {
      indicatorColor = const Color(0xFF8B5CF6); // Purple
    } else {
      indicatorColor = const Color(0xFF38BDF8); // Sky blue
    }

    String roomDisplay = 'Khu giảng đường';
    if (direction != null) {
      roomDisplay = '${direction.buildingCode} • ${direction.room}';
    } else if (nextClass.room.isNotEmpty) {
      roomDisplay = nextClass.room;
    }

    final subjectDisplay = nextClass.subject;
    final timeDisplay = nextClass.time;
    final lecturerDisplay = nextClass.lecturer.isNotEmpty
        ? nextClass.lecturer
        : 'Giảng viên bộ môn';
    final statusLabel = nextClass.capsuleLabel.isNotEmpty
        ? nextClass.capsuleLabel
        : 'LỊCH HỌC';

    return GestureDetector(
      onTap: () => ScheduleRoomDirectionModal.show(context, item: item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              offset: const Offset(0, 6),
              blurRadius: 12,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Left Accent Pill Indicator
            Positioned(
              left: 0,
              top: 18,
              bottom: 18,
              width: 4.5,
              child: Container(
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Status Capsule + Room
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: indicatorColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: indicatorColor.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6.5,
                              height: 6.5,
                              decoration: BoxDecoration(
                                color: indicatorColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: indicatorColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        roomDisplay,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Row 2: Subject Title + Time badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subjectDisplay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          timeDisplay.startsWith('Tiết') ? timeDisplay : 'Tiết $timeDisplay',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Row 3: Lecturer + Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            lecturerDisplay,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => ScheduleRoomDirectionModal.show(context, item: item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                              width: 0.8,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.near_me, color: AppColors.textLight, size: 12),
                              SizedBox(width: 6),
                              Text(
                                'Chỉ đường →',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
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
            ),
          ],
        ),
      ),
    );
  }
}
