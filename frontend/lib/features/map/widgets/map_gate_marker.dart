import 'package:flutter/material.dart';
import '../../../core/constants/campus_constants.dart';

/// Marker hiển thị Cổng trường dạng Pill đen/xanh nổi bật (Chuẩn 09_map_campus_overview.jpg)
class MapGateMarker extends StatelessWidget {
  final CampusGate gate;
  final bool isSelected;
  final VoidCallback onTap;

  const MapGateMarker({
    super.key,
    required this.gate,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Dark Navy/Black
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              offset: const Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.door_front_door_outlined,
              size: 13,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            const Text(
              'Cổng',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            // Chấm tròn phát sáng
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              gate.shortName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

