import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: navigationShell,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomInset > 0 ? bottomInset : 12,
            child: _buildFloatingBottomNav(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBottomNav(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return SizedBox(
      height: 78,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Background White Pill Card
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  offset: const Offset(0, 6),
                  blurRadius: 18,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Trang chủ
                _buildTabItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Trang chủ',
                  isSelected: currentIndex == 0,
                ),
                // 2. Lịch học
                _buildTabItem(
                  index: 1,
                  icon: Icons.calendar_today_outlined,
                  selectedIcon: Icons.calendar_month,
                  label: 'Lịch học',
                  isSelected: currentIndex == 1,
                ),
                // 3. Placeholder for Center Raised Button
                const SizedBox(width: 58),
                // 4. Điểm
                _buildTabItem(
                  index: 3,
                  icon: Icons.bar_chart_outlined,
                  selectedIcon: Icons.bar_chart,
                  label: 'Điểm',
                  isSelected: currentIndex == 3,
                ),
                // 5. Hồ sơ
                _buildTabItem(
                  index: 4,
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  label: 'Hồ sơ',
                  isSelected: currentIndex == 4,
                ),
              ],
            ),
          ),

          // Center Raised Button for Map (Bản đồ)
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () => _onTabSelected(2),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.38),
                          offset: const Offset(0, 6),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.near_me,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bản đồ',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: currentIndex == 2 ? FontWeight.w800 : FontWeight.w600,
                      color: currentIndex == 2 ? AppColors.primary : AppColors.textMuted,
                      letterSpacing: 0.1,
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

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
