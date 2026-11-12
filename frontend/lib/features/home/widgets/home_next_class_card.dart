import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/url_launcher_helper.dart';
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
                onTap: () => context.go('/schedule'),
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
    if (nextClass.isOngoing || nextClass.stateType == NextClassState.ongoing || nextClass.capsuleLabel == 'ĐANG HỌC') {
      indicatorColor = const Color(0xFF10B981); // Emerald Green: Đang học
    } else if (nextClass.isUpcoming || nextClass.stateType == NextClassState.upcoming || nextClass.capsuleLabel == 'SẮP TỚI' || nextClass.capsuleLabel.contains('HÔM NAY')) {
      indicatorColor = const Color(0xFFF59E0B); // Amber / Warm Orange: Sắp tới
    } else {
      indicatorColor = const Color(0xFF38BDF8); // Sky blue: Ngày mai hoặc thứ gần nhất
    }

    final bool isOnline = item.isOnline;
    String roomDisplay = 'Khu giảng đường';
    if (isOnline) {
      if (item.onlineMeetingCode != null && item.onlineMeetingCode!.isNotEmpty) {
        roomDisplay = 'Online (${item.onlineMeetingCode})';
      } else if (item.room.isNotEmpty && item.room.toLowerCase() != 'online') {
        final cleanRoom = item.room.replaceFirst(RegExp(r'^online\s*[•\-–—:]?\s*', caseSensitive: false), '').trim();
        roomDisplay = cleanRoom.isNotEmpty ? 'Online • $cleanRoom' : 'Học trực tuyến';
      } else {
        roomDisplay = 'Học trực tuyến';
      }
    } else if (direction != null) {
      roomDisplay = '${direction.buildingCode} • ${direction.room}';
    } else if (nextClass.room.isNotEmpty) {
      roomDisplay = nextClass.room;
    }

    final subjectDisplay = nextClass.subject;
    final timeDisplay = nextClass.time;
    final lecturerDisplay = nextClass.lecturer.isNotEmpty
        ? nextClass.lecturer
        : 'Giảng viên bộ môn';
    String statusLabel = nextClass.capsuleLabel.isNotEmpty
        ? nextClass.capsuleLabel
        : 'LỊCH HỌC';
    if (statusLabel == 'HÔM NAY') {
      statusLabel = nextClass.isOngoing ? 'ĐANG HỌC' : 'SẮP TỚI';
    }

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
                  // Row 1: Status Capsule + Online Badge + Countdown + Room
                  Row(
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
                      if (isOnline) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.lightBlueAccent.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.videocam_rounded, size: 11, color: Colors.lightBlueAccent),
                              SizedBox(width: 4),
                              Text(
                                'ONLINE',
                                style: TextStyle(
                                  color: Colors.lightBlueAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (nextClass.countdownText.isNotEmpty && nextClass.countdownText != '--:--') ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '• ${nextClass.countdownText}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (!isOnline) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            roomDisplay,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
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
                          timeDisplay.trim().startsWith('Tiết') ? timeDisplay.trim() : 'Tiết ${timeDisplay.trim()}',
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
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                            Expanded(
                              child: Text(
                                lecturerDisplay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          if (isOnline) {
                            await AppUrlLauncher.openGoogleMeet(
                              url: item.onlineMeetingUrl,
                              code: item.onlineMeetingCode,
                            );
                            return;
                          }
                          if (context.mounted) {
                            ScheduleRoomDirectionModal.show(context, item: item);
                          }
                        },
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOnline ? Icons.open_in_new : Icons.near_me,
                                color: AppColors.textLight,
                                size: 12,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOnline ? 'Mở link →' : 'Chỉ đường →',
                                style: const TextStyle(
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
