import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/news_card_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../../grades/providers/grades_provider.dart';
import '../models/news_model.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final nextClass = ref.watch(nextClassProvider);
    final gradesState = ref.watch(gradesProvider);
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
                await ref.read(homeProvider.notifier).fetchDashboard();
                await ref.read(gradesProvider.notifier).fetchGrades();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  // 3. NEXT CLASS CARD
                  _buildNextClassCard(context, nextClass),
                  const SizedBox(height: 16),

                  // 4. GPA OVERVIEW CARD
                  _buildGpaCard(context, gradesState),
                  const SizedBox(height: 24),

                  // 5. QUICK ACTIONS
                  _buildQuickActions(context),
                  const SizedBox(height: 24),

                  // 6. ALERTS & NOTIFICATIONS
                  _buildAlertsSection(context, homeState.alerts),
                  const SizedBox(height: 24),

                  // 7. ANNOUNCEMENTS SECTION
                  _buildAnnouncementsSection(context, homeState.announcements),
                  const SizedBox(height: 24),

                  // 8. NEWS SECTION
                  _buildNewsSection(context, homeState.news),
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
    final roleText = isGuest
        ? 'KHÁCH THAM QUAN'
        : 'SINH VIÊN • ${user.studentId ?? "23103023"}';
    final nameText = user?.fullName ?? 'Nguyễn Huy Hoàng';

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

  // ─── 2. NEXT CLASS CARD ───
  Widget _buildNextClassCard(BuildContext context, NextClassInfo info) {
    const indicatorColor = Color(0xFF8B5CF6); // Purple accent

    return GestureDetector(
      onTap: () => context.push('/map?room=${Uri.encodeComponent(info.room)}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              offset: const Offset(0, 6),
              blurRadius: 12,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Left Accent Pill Indicator
            Positioned(
              left: 0,
              top: 18,
              bottom: 18,
              width: 4.5,
              child: Container(
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Status Capsule + Room Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: indicatorColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: indicatorColor.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6.5,
                              height: 6.5,
                              decoration: const BoxDecoration(
                                color: indicatorColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              info.capsuleLabel.isNotEmpty
                                  ? info.capsuleLabel
                                  : 'NGÀY MAI (THỨ HAI)',
                              style: const TextStyle(
                                color: indicatorColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        info.room.isNotEmpty ? info.room : '2.21 (CLC)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Row 2: Subject Title + Period Pill
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          info.subject.isNotEmpty ? info.subject : 'LS Đảng CS VN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          info.time.isNotEmpty ? info.time : 'Tiết 1-4',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Row 3: Lecturer + Navigation Capsule
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            info.lecturer.isNotEmpty ? info.lecturer : 'Đoàn Văn Kỳ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.near_me, color: AppColors.textLight, size: 13),
                            SizedBox(width: 6),
                            Text(
                              'Chỉ đường →',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
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
  }

  // ─── 3. GPA OVERVIEW CARD ───
  Widget _buildGpaCard(BuildContext context, dynamic gradesState) {
    const rankColor = Color(0xFFF59E0B); // Amber for "Khá"

    return GestureDetector(
      onTap: () => context.push('/grades'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 3),
              blurRadius: 10,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Row: Award Icon + Title + Rank Pill + Chevron
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.military_tech_outlined,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kết quả học tập',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Tích lũy toàn khóa đào tạo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: rankColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: rankColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: rankColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            gradesState.academicRank.isNotEmpty ? gradesState.academicRank : 'Khá',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: rankColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSubtle,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Tonal Container (3 Columns)
            Container(
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                children: [
                  // GPA HỆ 4
                  Expanded(
                    child: _buildGpaStatCol(
                      label: 'GPA HỆ 4',
                      value: gradesState.gpa4 > 0 ? gradesState.gpa4.toStringAsFixed(2) : '2.63',
                      scale: '/4.0',
                      valueColor: AppColors.info,
                    ),
                  ),
                  Container(width: 1, height: 26, color: AppColors.border),
                  // GPA HỆ 10
                  Expanded(
                    child: _buildGpaStatCol(
                      label: 'GPA HỆ 10',
                      value: gradesState.averageScore10 > 0 ? gradesState.averageScore10.toStringAsFixed(2) : '7.21',
                      scale: '/10',
                      valueColor: AppColors.accent,
                    ),
                  ),
                  Container(width: 1, height: 26, color: AppColors.border),
                  // TÍN CHỈ
                  Expanded(
                    child: _buildGpaStatCol(
                      label: 'TÍN CHỈ',
                      value: gradesState.accumulatedCredits > 0 ? '${gradesState.accumulatedCredits}' : '106',
                      scale: 'TC',
                      valueColor: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpaStatCol({
    required String label,
    required String value,
    required String scale,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: valueColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              scale,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSubtle,
              ),
            ),
          ],
        ),
      ],
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
    return GestureDetector(
      onTap: () => context.push(route),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
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
      onTap: () {
        if (alert.actionScreen == 'feedback') {
          context.push('/feedback');
        } else if (alert.actionScreen == 'sos') {
          context.push('/sos');
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(alert.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              content: Text(alert.content.isNotEmpty ? alert.content : alert.subtitle),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
        }
      },
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
      BuildContext context, List<NewsModel> announcements) {
    final sampleItems = announcements.isNotEmpty
        ? announcements.take(3).toList()
        : [
            const NewsModel(
              id: 1,
              title:
                  'Thông báo về việc xét chọn sinh viên nhận Học bổng Quỹ Thiện Tâm năm học 2026 -2027',
              summary: 'Chi tiết học bổng Quỹ Thiện Tâm...',
              content: '',
              category: 'Thông báo SV',
              publishedAt: '08/10/2026',
              author: 'Đậu Thị Thúy Hoàn',
            ),
            const NewsModel(
              id: 2,
              title: 'Mobifone Đắk Lắk tuyển dụng',
              summary: 'Mobifone Đắk Lắk tuyển dụng nhân sự...',
              content: '',
              category: 'Thông báo SV',
              publishedAt: '07/10/2026',
              author: 'Nguyễn Thạch Cương',
            ),
            const NewsModel(
              id: 3,
              title:
                  'Tổ chức thi chứng chỉ Ứng dụng CNTT cơ bản tại Trường Đại học Tây Nguyên. Khóa ngày 24-25/10/2026',
              summary: 'Thông tin tổ chức thi CNTT...',
              content: '',
              category: 'Thông báo SV',
              publishedAt: '06/10/2026',
              author: 'Nguyễn Thạch Cương',
            ),
          ];

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
          children: sampleItems.map((item) {
            final dateStr = item.publishedAt ?? '08/10/2026';

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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_none, size: 12, color: AppColors.success),
                              SizedBox(width: 4),
                              Text(
                                'Thông báo SV',
                                style: TextStyle(
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
  Widget _buildNewsSection(BuildContext context, List<NewsModel> newsList) {
    final sampleNews = newsList.isNotEmpty
        ? newsList.take(2).toList()
        : [
            const NewsModel(
              id: 101,
              title:
                  'Hội nghị thực hiện quy trình quy hoạch chức danh Hiệu trưởng, Phó Hiệu trưởng Trường Đại học Tây Nguyên, nhiệm kỳ 2026 – 2031',
              summary:
                  'Ngày 07/10, Trường Đại học Tây Nguyên tổ chức Hội nghị thực hiện quy trình quy hoạch chức danh Hiệu trưởng...',
              content:
                  'Ngày 07/10, Trường Đại học Tây Nguyên tổ chức Hội nghị thực hiện quy trình quy hoạch chức danh Hiệu trưởng...',
              category: 'Tin hoạt động',
              publishedAt: '07/10/2026',
              author: 'Ban Biên tập TTN',
            ),
          ];

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
          children: sampleNews.map((item) {
            final dateStr = item.publishedAt ?? '07/10/2026';

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
                      fallbackIndex: item.id,
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
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.menu_book_outlined, size: 12, color: AppColors.info),
                                    SizedBox(width: 4),
                                    Text(
                                      'Tin hoạt động',
                                      style: TextStyle(
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
                          if (item.content != null && item.content!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              item.content!,
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
