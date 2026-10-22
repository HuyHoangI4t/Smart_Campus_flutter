import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ─── 1. SOLID NAVY BLUE HEADER ───
          _buildHomeHeader(context, user),

          // ─── 2. SCROLLABLE BODY ───
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await Future.wait<void>([
                  ref.read(homeProvider.notifier).fetchDashboard(forceRefresh: true),
                  ref.read(scheduleProvider.notifier).fetchSchedule(forceRefresh: true),
                  ref.read(gradesProvider.notifier).fetchGrades(),
                ]);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                    _buildAlertsSection(context, homeState.alerts),
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
          ),
        ],
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
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 16),
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
                onTap: () => context.push('/profile'),
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
                    child: user?.avatarUrl != null
                        ? Image.network(
                            user!.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
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
        onTap: () => context.push(route),
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
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Center(
                child: Icon(icon, color: fg, size: 24),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
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
  Widget _buildAlertsSection(BuildContext context, List<HomeAlertItem> alerts) {
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Thông báo & Cảnh báo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            Text(
              '${alerts.length} tin mới',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.accentLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        for (int i = 0; i < alerts.length; i++) ...[
          _buildAlertCard(context, alerts[i]),
          if (i < alerts.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  void _showHomeNoticeModal(BuildContext context, HomeAlertItem alert) {
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
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: SizedBox(
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, HomeAlertItem alert) {
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

    return GestureDetector(
      onTap: () => _showHomeNoticeModal(context, alert),
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
            Icon(
              Icons.chevron_right,
              color: iconColor,
              size: 18,
            ),
          ],
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
          const WireframeEmptyState(
            title: 'Chưa có thông báo',
            subtitle: 'Thông báo từ nhà trường sẽ cập nhật tại đây',
            icon: Icons.notifications_none_rounded,
          ),
        ],
      );
    }

    final displayItems = announcements.take(6).toList();

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
              onTap: () => context.push('/home/news'),
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

            return GestureDetector(
              onTap: () => context.push('/home/news/${item.id}'),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.notifications_none, size: 12, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                item.category.isNotEmpty ? item.category : 'Thông báo SV',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
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
          const WireframeEmptyState(
            title: 'Chưa có tin tức',
            subtitle: 'Tin tức và hoạt động mới nhất sẽ cập nhật tại đây',
            icon: Icons.article_outlined,
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
              onTap: () => context.push('/home/news'),
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

            return GestureDetector(
              onTap: () => context.push('/home/news/${item.id}'),
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
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.menu_book_outlined, size: 12, color: AppColors.info),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.category.isNotEmpty ? item.category : 'Tin hoạt động',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.info,
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
