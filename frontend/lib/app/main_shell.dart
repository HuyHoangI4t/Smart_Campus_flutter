import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final currentIndex = navigationShell.currentIndex;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -3),
            blurRadius: 10,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 8,
        bottom: bottomInset > 0 ? bottomInset : 8,
      ),
      child: Row(
        children: [
          _buildTabItem(
            index: 0,
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Trang chủ',
            isSelected: currentIndex == 0,
          ),
          _buildTabItem(
            index: 1,
            icon: Icons.calendar_today_outlined,
            selectedIcon: Icons.calendar_month_rounded,
            label: 'Lịch học',
            isSelected: currentIndex == 1,
          ),
          _buildTabItem(
            index: 2,
            icon: Icons.near_me_outlined,
            selectedIcon: Icons.near_me_rounded,
            label: 'Bản đồ',
            isSelected: currentIndex == 2,
            isCenter: true,
          ),
          _buildTabItem(
            index: 3,
            icon: Icons.bar_chart_outlined,
            selectedIcon: Icons.bar_chart_rounded,
            label: 'Điểm',
            isSelected: currentIndex == 3,
          ),
          _buildTabItem(
            index: 4,
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: 'Hồ sơ',
            isSelected: currentIndex == 4,
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
    bool isCenter = false,
  }) {
    final Color activeColor = AppColors.primary;
    final Color inactiveColor = const Color(0xFF64748B);

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFEEF2FF)
                    : (isCenter ? const Color(0xFFF8FAFC) : Colors.transparent),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: -0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
