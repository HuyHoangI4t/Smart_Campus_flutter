import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../features/map/providers/map_provider.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tự động ẩn bottom navigation bar khi đang chỉ đường đi bộ trên bản đồ
    final isNavigatingOnMap = ref.watch(mapProvider.select((s) => s.isNavigating));
    final isOnMapTab = navigationShell.currentIndex == 2;
    final shouldHideBottomNav = isOnMapTab && isNavigatingOnMap;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: shouldHideBottomNav ? null : _buildBottomNav(context, ref),
    );
  }

  Widget _buildBottomNav(BuildContext context, WidgetRef ref) {
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
            ref: ref,
            index: 0,
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Trang chủ',
            isSelected: currentIndex == 0,
          ),
          _buildTabItem(
            ref: ref,
            index: 1,
            icon: Icons.calendar_today_outlined,
            selectedIcon: Icons.calendar_month_rounded,
            label: 'Lịch học',
            isSelected: currentIndex == 1,
          ),
          _buildTabItem(
            ref: ref,
            index: 2,
            icon: Icons.near_me_outlined,
            selectedIcon: Icons.near_me_rounded,
            label: 'Bản đồ',
            isSelected: currentIndex == 2,
            isCenter: true,
          ),
          _buildTabItem(
            ref: ref,
            index: 3,
            icon: Icons.bar_chart_outlined,
            selectedIcon: Icons.bar_chart_rounded,
            label: 'Điểm',
            isSelected: currentIndex == 3,
          ),
          _buildTabItem(
            ref: ref,
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
    required WidgetRef ref,
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
        onTap: () => _onTabSelected(ref, index),
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

  void _onTabSelected(WidgetRef ref, int index) {
    if (navigationShell.currentIndex == 2 && index != 2) {
      // Khi rời khỏi tab Bản đồ: tự động dọn sạch ô tìm kiếm, huỷ chọn toà nhà,
      // TRỪ TRƯỜNG HỢP đang ở chế độ dẫn đường chỉ đường (isNavigating == true)
      final mapState = ref.read(mapProvider);
      if (!mapState.isNavigating) {
        ref.read(mapProvider.notifier).resetExploreState();
      }
    }

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
