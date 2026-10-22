import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/campus_constants.dart';

/// Thanh điều hướng dẫn đường đi bộ dưới chân màn hình (Chuẩn 10_map_routing_navigation.jpg)
class MapNavigationBar extends StatelessWidget {
  final CampusLocationItem destination;
  final CampusGate currentGate;
  final double distanceMeters;
  final int walkingMinutes;
  final VoidCallback onStopNavigation;

  const MapNavigationBar({
    super.key,
    required this.destination,
    required this.currentGate,
    required this.distanceMeters,
    required this.walkingMinutes,
    required this.onStopNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon điều hướng mũi tên xanh
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.near_me, size: 22, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),

          // Thông tin điểm đến & Cổng & Khoảng cách
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Huy hiệu cổng đang qua
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_forward, size: 10, color: Color(0xFF059669)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          'CỔNG: ${currentGate.name.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF059669),
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Tên địa điểm đến
                Text(
                  destination.name,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                // Khoảng cách mét & phút đi bộ
                Text(
                  '~${(distanceMeters.isInfinite || distanceMeters.isNaN) ? 100 : distanceMeters.round()}m • ~$walkingMinutes phút đi bộ',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Nút Dừng màu đỏ
          InkWell(
            onTap: onStopNavigation,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECACA), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFDC2626)),
                  SizedBox(width: 5),
                  Text(
                    'Dừng',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFDC2626),
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
}

