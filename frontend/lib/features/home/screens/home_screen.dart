import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/home_widget_service.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../../core/widgets/news_card_image.dart';
import '../../../core/widgets/wireframe_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../grades/providers/grades_provider.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../models/news_model.dart';
import '../providers/home_provider.dart';
import '../widgets/home_gpa_card.dart';
import '../widgets/home_next_class_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final homeState = ref.watch(homeProvider);
    final user = authState.user;

    // Tự động đồng bộ 2 Widget màn hình chính Launcher khi có dữ liệu mới
    ref.listen(nextClassProvider, (_, next) {
      final item = next.item;
      final timeStr = item != null && item.startTime.isNotEmpty
          ? '${item.startTime} - ${item.endTime} (${item.periodDisplay})'
          : (next.time.isNotEmpty ? next.time : 'Hôm nay nghỉ');
      final statusBadge = next.capsuleLabel.isNotEmpty
          ? (next.capsuleLabel == 'NGÀY MAI'
              ? 'Thứ 2 • Ngày mai'
              : (next.capsuleLabel == 'HÔM NAY'
                  ? (next.isOngoing ? 'Hôm nay • Đang học' : 'Hôm nay • Sắp tới')
                  : next.capsuleLabel))
          : 'LỊCH HỌC';
      final lecturerStr = (item?.lecturer != null && item!.lecturer!.isNotEmpty)
          ? 'GV: ${item.lecturer}'
          : 'Smart Campus TTN';

      HomeWidgetService.instance.updateScheduleWidget(
        subject: next.subject.isNotEmpty ? next.subject : 'Chưa có môn học',
        time: timeStr,
        room: next.room.isNotEmpty ? next.room : 'Khuôn viên trường',
        status: statusBadge,
        countdown: next.countdownText.isNotEmpty ? next.countdownText : 'Sắp diễn ra',
        lecturer: lecturerStr,
      );
    });

    ref.listen(gradesProvider, (_, grades) {
      final gpa4 = grades.gpa4;
      final gpa10 = grades.summary.gpa10;
      final credits = grades.accumulatedCredits;
      final progressPercent = (credits / 140 * 100).clamp(0, 100).round();

      HomeWidgetService.instance.updateGpaWidget(
        gpa: gpa4 > 0 ? gpa4.toStringAsFixed(2) : '0.00',
        gpa10: gpa10 > 0 ? 'Thang 10: ${gpa10.toStringAsFixed(1)}' : 'Thang 10: --',
        credits: credits.toString(),
        rank: gpa4 > 0 && grades.summary.academicRank.isNotEmpty
            ? grades.summary.academicRank
            : 'Chưa xét',
        progressText: credits > 0 ? 'Tiến độ: ~$progressPercent% CTĐT' : 'Chưa có tín chỉ',
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait<void>([
            ref.read(homeProvider.notifier).fetchDashboard(forceRefresh: true),
            ref.read(scheduleProvider.notifier).fetchSchedule(forceRefresh: true),
            ref.read(gradesProvider.notifier).fetchGrades(),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            // ─── 1. SOLID NAVY BLUE HEADER ───
            _buildHomeHeader(context, user),

            // ─── 2. SCROLLABLE BODY CARDS ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3. THẺ LỊCH HỌC HÔM NAY / SẮP TỚI
                  const HomeNextClassCard(),
                  const SizedBox(height: 16),

                  // 4. THẺ KẾT QUẢ HỌC TẬP (GPA & TÍN CHỈ)
                  const HomeGpaCard(),
                  const SizedBox(height: 24),

                  // 5. QUICK ACTIONS
                  _buildQuickActions(context),
                  const SizedBox(height: 24),

                  // 6. ALERTS & NOTIFICATIONS
                  if (homeState.alerts.isNotEmpty) ...[
                    _buildAlertsSection(context, ref, homeState.alerts),
                    const SizedBox(height: 24),
                  ],

                  // 7. ANNOUNCEMENTS SECTION
                  _buildAnnouncementsSection(
                    context,
                    homeState.announcements,
                    isLoading: homeState.isLoading,
                  ),
                  const SizedBox(height: 24),

                  // 8. NEWS SECTION
                  _buildNewsSection(
                    context,
                    homeState.news,
                    isLoading: homeState.isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 1. HEADER (Deep Navy #132F73) ───
  Widget _buildHomeHeader(BuildContext context, dynamic user) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final isGuest = user == null || user.isGuest == true;
    final studentIdStr = (user?.studentId != null && user!.studentId.toString().isNotEmpty)
        ? ' • ${user.studentId}'
        : '';
    final roleText = isGuest ? 'KHÁCH THAM QUAN' : 'SINH VIÊN$studentIdStr';
    final nameText = (user?.fullName != null && user!.fullName.toString().isNotEmpty)
        ? user.fullName
        : (isGuest ? 'Khách tham quan' : 'Sinh viên');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // User Role & Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  roleText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  nameText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // SOS & Profile Action Buttons
          Row(
            children: [
              // SOS Button
              GestureDetector(
                onTap: () => context.push('/sos'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.danger.withValues(alpha: 0.35),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Profile Avatar Button
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: AvatarImage(
                      avatarUrl: user?.avatarUrl,
                      size: 44,
                      fallbackText: user?.fullName ?? 'S',
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

  // ─── 4. QUICK ACTIONS ───
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tác vụ nhanh',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickActionItem(
              context: context,
              icon: Icons.near_me,
              label: 'Bản đồ',
              route: '/map',
              bg: const Color(0xFFEEF2FF),
              border: const Color(0xFFE0E7FF),
              fg: const Color(0xFF6366F1),
            ),
            _buildQuickActionItem(
              context: context,
              icon: Icons.calendar_month,
              label: 'Lịch học',
              route: '/schedule',
              bg: const Color(0xFFE0F2FE),
              border: const Color(0xFFBAE6FD),
              fg: const Color(0xFF0284C7),
            ),
            _buildQuickActionItem(
              context: context,
              icon: Icons.chat_bubble_outline,
              label: 'Phản hồi',
              route: '/feedback',
              bg: const Color(0xFFFEF3C7),
              border: const Color(0xFFFDE68A),
              fg: const Color(0xFFD97706),
            ),
            _buildQuickActionItem(
              context: context,
              icon: Icons.bar_chart,
              label: 'Kết quả',
              route: '/grades',
              bg: const Color(0xFFDCFCE7),
              border: const Color(0xFFBBF7D0),
              fg: const Color(0xFF16A34A),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required Color bg,
    required Color border,
    required Color fg,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          const tabRoutes = ['/home', '/schedule', '/map', '/grades', '/profile'];
          if (tabRoutes.contains(route)) {
            context.go(route);
          } else {
            context.push(route);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: fg.withValues(alpha: 0.15),
                    offset: const Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Icon(icon, color: fg, size: 24),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─── 5. ALERTS & NOTIFICATIONS ───
  void _handleDeleteAlert(BuildContext context, WidgetRef ref, HomeAlertItem alert, int index, {bool showSnackBar = true}) {
    ref.read(homeProvider.notifier).dismissAlert(alert.uniqueId);

    if (showSnackBar && context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã xóa: "${alert.title}"',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF1E293B),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Hoàn tác',
            textColor: const Color(0xFF6EE7B7),
            onPressed: () {
              ref.read(homeProvider.notifier).undoDismissAlert(alert, atIndex: index);
            },
          ),
        ),
      );
    }
  }

  void _confirmClearAllAlerts(BuildContext context, WidgetRef ref, List<HomeAlertItem> alerts) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Text(
              'Xóa tất cả thông báo?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xóa tất cả ${alerts.length} thông báo và cảnh báo đang hiển thị?',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final count = alerts.length;
              ref.read(homeProvider.notifier).dismissAllAlerts();
              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã xóa sạch $count thông báo & cảnh báo.',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFF1E293B),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('Xóa tất cả', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(BuildContext context, WidgetRef ref, List<HomeAlertItem> alerts) {
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Thông báo & Cảnh báo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC7D2FE), width: 0.8),
                  ),
                  child: Text(
                    '${alerts.length}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            // Nút "Xóa tất cả" nhanh
            InkWell(
              onTap: () => _confirmClearAllAlerts(context, ref, alerts),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_sweep_rounded, size: 14, color: Color(0xFFDC2626)),
                    SizedBox(width: 4),
                    Text(
                      'Xóa tất cả',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        for (int i = 0; i < alerts.length; i++) ...[
          _buildAlertCard(context, ref, alerts[i], i),
          if (i < alerts.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  void _showHomeNoticeModal(BuildContext context, WidgetRef ref, HomeAlertItem alert, int index) {
    final isSuccess = alert.variant == 'success';
    final isWarning = alert.variant == 'warning' || alert.type == 'sos';

    final Color iconBg = isSuccess
        ? const Color(0xFFDCFCE7)
        : (isWarning ? const Color(0xFFFEF3C7) : const Color(0xFFDBEAFE));
    final Color iconColor = isSuccess
        ? const Color(0xFF10B981)
        : (isWarning ? const Color(0xFFD97706) : const Color(0xFF2563EB));
    final IconData iconData = isSuccess
        ? Icons.check_circle_outline
        : (isWarning ? Icons.warning_amber_rounded : Icons.info_outline);

    final String typeLabel = alert.type == 'feedback'
        ? 'Trạng thái phản hồi'
        : (alert.type == 'sos' ? 'Cảnh báo khẩn cấp' : 'Thông báo từ nhà trường');

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Icon + Type + Date + Close
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(iconData, size: 20, color: iconColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          alert.date.isNotEmpty ? alert.date : 'Hôm nay',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Status Badge
              if (alert.status.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? const Color(0xFFDCFCE7)
                        : (isWarning ? const Color(0xFFFEF3C7) : const Color(0xFFDBEAFE)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alert.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSuccess
                          ? const Color(0xFF166534)
                          : (isWarning ? const Color(0xFF92400E) : const Color(0xFF1E40AF)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Title
              Text(
                alert.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),

              // Content / Subtitle
              Text(
                alert.content.isNotEmpty ? alert.content : alert.subtitle,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  if (alert.actionScreen != null && alert.actionScreen!.isNotEmpty) ...[
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            if (alert.actionScreen == 'feedback') {
                              context.push('/feedback');
                            } else if (alert.actionScreen == 'sos') {
                              context.push('/sos');
                            }
                          },
                          child: const Text(
                            'Xem chi tiết',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Nút Xóa nhanh thông báo này trong Dialog
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEF2F2),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleDeleteAlert(context, ref, alert, index);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                            SizedBox(width: 4),
                            Text(
                              'Xóa tin',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Đóng',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, WidgetRef ref, HomeAlertItem alert, int index) {
    final isSuccess = alert.variant == 'success';
    final isWarning = alert.variant == 'warning' || alert.type == 'sos';

    final Color bgColor = isSuccess
        ? const Color(0xFFECFDF5)
        : (isWarning ? const Color(0xFFFFFBEB) : const Color(0xFFEFF6FF));
    final Color borderColor = isSuccess
        ? const Color(0xFFA7F3D0)
        : (isWarning ? const Color(0xFFFDE68A) : const Color(0xFFBFDBFE));
    final Color iconBg = isSuccess
        ? const Color(0xFFD1FAE5)
        : (isWarning ? const Color(0xFFFEF3C7) : const Color(0xFFDBEAFE));
    final Color iconColor = isSuccess
        ? const Color(0xFF10B981)
        : (isWarning ? const Color(0xFFD97706) : const Color(0xFF2563EB));
    final Color titleColor = isSuccess
        ? const Color(0xFF065F46)
        : (isWarning ? const Color(0xFF92400E) : const Color(0xFF1E40AF));
    final Color dateColor = isSuccess
        ? const Color(0xFF047857)
        : (isWarning ? const Color(0xFFB45309) : const Color(0xFF1D4ED8));
    final IconData icon = isSuccess
        ? Icons.check_circle_outline
        : (isWarning ? Icons.warning_amber_rounded : Icons.info_outline);

    return Dismissible(
      key: Key('alert_${alert.uniqueId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 22),
            SizedBox(width: 6),
            Text(
              'Xóa',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        _handleDeleteAlert(context, ref, alert, index);
      },
      child: GestureDetector(
        onTap: () => _showHomeNoticeModal(context, ref, alert, index),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert.date.isNotEmpty ? alert.date : (alert.subtitle.isNotEmpty ? alert.subtitle : 'Hôm nay'),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: dateColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Nút xóa nhanh trực tiếp trên card
              Tooltip(
                message: 'Xóa thông báo này',
                child: InkWell(
                  onTap: () => _handleDeleteAlert(context, ref, alert, index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: iconColor,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 6. ANNOUNCEMENTS SECTION ───
  Widget _buildAnnouncementsSection(
      BuildContext context, List<NewsModel> announcements, {bool isLoading = false}) {
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông báo Sinh viên',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          const WireframeNewsCard(),
        ],
      );
    }

    if (announcements.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông báo Sinh viên',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          // Empty State chỉn chu (tham khảo LTDDDNT)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(Icons.inbox_rounded, size: 24, color: AppColors.textSubtle),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chưa có thông báo mới',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Các thông báo học vụ, lịch thi và học bổng mới nhất sẽ hiển thị tại đây khi có tin tức mới.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Hiển thị 3 thông báo mới nhất như LTDDDNT
    final displayItems = announcements.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Thông báo Sinh viên',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/home/news?category=announcement'),
              child: Row(
                children: [
                  Text(
                    'Xem tất cả',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentLight,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 16, color: AppColors.accentLight),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Column(
          children: displayItems.map((item) {
            final dateStr = item.publishedAt ?? '';

            final isFallback = item.id.startsWith('ann-ttn-') ||
                item.id.startsWith('sample-') ||
                item.title.contains('[Dữ liệu mẫu]');
            final hasAttachments = item.attachments.isNotEmpty;

            return GestureDetector(
              onTap: () => context.push('/home/news/${item.id}', extra: item),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isFallback
                                    ? const Color(0xFFFEF3C7)
                                    : const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isFallback ? Icons.warning_amber_rounded : Icons.notifications_none,
                                    size: 12,
                                    color: isFallback ? const Color(0xFFD97706) : AppColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isFallback
                                        ? 'Dữ liệu mẫu'
                                        : (item.category.isNotEmpty ? item.category : 'Thông báo SV'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isFallback ? const Color(0xFFD97706) : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (hasAttachments) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.attach_file, size: 10, color: AppColors.textSecondary),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${item.attachments.length} file',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSubtle,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textForeground,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.home_outlined, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              item.author ?? 'Phòng Công tác SV',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'Chi tiết',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentLight,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.accentLight),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── 7. NEWS & ACTIVITIES SECTION ───
  Widget _buildNewsSection(BuildContext context, List<NewsModel> newsList, {bool isLoading = false}) {
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tin tức & Hoạt động',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          const WireframeNewsCard(),
        ],
      );
    }

    if (newsList.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tin tức & Hoạt động',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          // Empty State chỉn chu (tham khảo LTDDDNT)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(Icons.inbox_rounded, size: 24, color: AppColors.textSubtle),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chưa có tin tức mới',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Các bài viết mới nhất từ cổng thông tin trường sẽ hiển thị tại đây khi có cập nhật.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final displayNews = newsList.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tin tức & Hoạt động',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/home/news?category=news'),
              child: Row(
                children: [
                  Text(
                    'Xem tất cả',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentLight,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 16, color: AppColors.accentLight),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Column(
          children: displayNews.map((item) {
            final dateStr = item.publishedAt ?? '';
            final isFallback = item.id.startsWith('sample-') ||
                item.title.contains('[Dữ liệu mẫu]');

            return GestureDetector(
              onTap: () => context.push('/home/news/${item.id}', extra: item),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      offset: const Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Image
                    NewsCardImage(
                      imageUrl: item.imageUrl,
                      fallbackIndex: item.numericIndex,
                      height: 155,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),

                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isFallback
                                      ? const Color(0xFFFEF3C7)
                                      : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isFallback ? Icons.warning_amber_rounded : Icons.menu_book_outlined,
                                      size: 12,
                                      color: isFallback ? const Color(0xFFD97706) : AppColors.info,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isFallback
                                          ? 'Dữ liệu mẫu'
                                          : (item.category.isNotEmpty ? item.category : 'Tin hoạt động'),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: isFallback ? const Color(0xFFD97706) : AppColors.info,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSubtle,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textForeground,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.summary.isNotEmpty || (item.content != null && item.content!.isNotEmpty)) ...[
                            const SizedBox(height: 6),
                            Text(
                              item.summary.isNotEmpty ? item.summary : item.content!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.public, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.author ?? 'Ban Biên tập TTN',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Chi tiết bài viết',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accentLight,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.accentLight),
                                ],
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
          }).toList(),
        ),
      ],
    );
  }
}
