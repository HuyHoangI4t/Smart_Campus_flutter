import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/campus_constants.dart';
import '../../../core/utils/haversine.dart';

/// Card chi tiết địa điểm dưới chân màn hình (Chuẩn 09_map_campus_overview.jpg)
class MapLocationDetailCard extends StatelessWidget {
  final CampusLocationItem location;
  final CampusGate currentGate;
  final VoidCallback onClose;
  final VoidCallback onStartNavigation;

  const MapLocationDetailCard({
    super.key,
    required this.location,
    required this.currentGate,
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
              Container(
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
                    Text(
                      '~${distMeters}m • ~$walkMinutes phút đi bộ',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
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

          // 2 Nút hành động: "Chỉ đường đi bộ" + "Mở App ngoài"
          Row(
            children: [
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: onStartNavigation,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.near_me, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Chỉ đường đi bộ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () async {
                    final url = Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=${location.lat},${location.lng}',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.open_in_new, color: AppColors.textForeground, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Mở App ngoài',
                          style: TextStyle(
                            color: AppColors.textForeground,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
