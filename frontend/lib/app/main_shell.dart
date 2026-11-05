import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../features/grades/providers/grades_provider.dart';
import '../features/home/providers/home_provider.dart';
import '../features/map/providers/map_provider.dart';
import '../features/schedule/providers/schedule_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  Timer? _preloadTimer;

  @override
  void initState() {
    super.initState();
    if (widget.navigationShell.currentIndex == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(mapProvider.notifier).activateMap();
      });
    }

    // Preload ngầm song song cho các phân hệ để chuyển tab tức thì (tham khảo LTDDDNT)
    _preloadTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      try {
        ref.read(homeProvider.notifier).fetchDashboard();
        ref.read(scheduleProvider.notifier).fetchSchedule();
        ref.read(gradesProvider.notifier).fetchGrades();
        ref.read(mapProvider.notifier).fetchLocationsFromBackend();
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _preloadTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final prevIndex = oldWidget.navigationShell.currentIndex;
    final currIndex = widget.navigationShell.currentIndex;
    if (prevIndex != currIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (prevIndex == 2 && currIndex != 2) {
          ref.read(mapProvider.notifier).deactivateMap();
        } else if (prevIndex != 2 && currIndex == 2) {
          ref.read(mapProvider.notifier).activateMap();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tự động ẩn bottom navigation bar khi đang chỉ đường đi bộ trên bản đồ
    final isNavigatingOnMap = ref.watch(mapProvider.select((s) => s.isNavigating));
    final isOnMapTab = widget.navigationShell.currentIndex == 2;
    final shouldHideBottomNav = isOnMapTab && isNavigatingOnMap;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: widget.navigationShell,
      bottomNavigationBar: shouldHideBottomNav ? null : _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final currentIndex = widget.navigationShell.currentIndex;

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
    final prevIndex = widget.navigationShell.currentIndex;
    if (prevIndex == 2 && index != 2) {
      // Khi rời khỏi tab Bản đồ: HỦY TOÀN BỘ stream, cảm biến và chỉ đường chạy ngầm
      ref.read(mapProvider.notifier).deactivateMap();
    } else if (prevIndex != 2 && index == 2) {
      // Khi vào lại tab Bản đồ: Kích hoạt lại định vị và la bàn
      ref.read(mapProvider.notifier).activateMap();
    }

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
