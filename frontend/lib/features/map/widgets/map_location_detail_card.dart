import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/campus_constants.dart';
import '../../../core/utils/haversine.dart';

/// Card chi tiết địa điểm dưới chân màn hình
class MapLocationDetailCard extends StatelessWidget {
  final CampusLocationItem location;
  final CampusGate currentGate;
  final String? roomName;
  final VoidCallback onClose;
  final VoidCallback onStartNavigation;

  const MapLocationDetailCard({
    super.key,
    required this.location,
    required this.currentGate,
    this.roomName,
    required this.onClose,
    required this.onStartNavigation,
  });

  @override
  Widget build(BuildContext context) {
    // Tính khoảng cách ước tính từ cổng hiện tại
    final distMeters = calculateHaversineDistance(
      currentGate.lat,
      currentGate.lng,
      location.lat,
      location.lng,
    ).round();
    final walkMinutes = (distMeters / 75).ceil().clamp(1, 45);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Badges Row: Category + Khoảng cách/Thời gian đi bộ + Nút đóng ✕
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: location.color,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  location.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.near_me, size: 10, color: AppColors.success),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '~${distMeters}m • ~$walkMinutes phút đi bộ',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tên địa điểm
          Text(
            location.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textForeground,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),

          // Tòa nhà & Tầng
          Text(
            '${location.building} • ${location.floor.isNotEmpty ? location.floor : "Tầng 1 - 4"}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          if (roomName != null && roomName!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.meeting_room_rounded, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Text(
                    'Phòng học: ${roomName!.trim()}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (location.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              location.description,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),

          // Nút hành động: "Chỉ đường đi bộ"
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onStartNavigation,
              icon: const Icon(Icons.near_me, color: Colors.white, size: 18),
              label: const Text(
                'Chỉ đường đi bộ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
