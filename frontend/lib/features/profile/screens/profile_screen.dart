import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/home_widget_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/nav_header.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../grades/providers/grades_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/server_config_dialog.dart';
import '../widgets/avatar_picker_modal.dart';
import '../widgets/edit_profile_modal.dart';
import '../widgets/logout_confirm_dialog.dart';

/// MÃ n hÃ¬nh Há»“ sÆ¡ sinh viÃªn
/// TuÃ¢n thá»§ quy chuáº©n: Clean Architecture, Small Widgets (<300 lines), Const constructors,
/// Touch Target >= 44px, Riverpod state management.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final fullName = user?.fullName.isNotEmpty == true ? user!.fullName : 'Nguyá»…n Huy HoÃ ng';
    final studentId = user?.studentId.isNotEmpty == true ? user!.studentId : '23103023';
    final faculty = user?.faculty?.isNotEmpty == true ? user!.faculty! : 'KHTN &CN';
    final studentClass = user?.studentClass?.isNotEmpty == true ? user!.studentClass! : 'K23';
    final email = user?.email?.isNotEmpty == true ? user!.email! : '$studentId@sv.ttn.edu.vn';
    final phone = user?.phone?.isNotEmpty == true ? user!.phone! : '0329106783';
    final avatarUrl = user?.avatarUrl ?? 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // â”€â”€â”€ 1. NAVHEADER (Navy #132F73) â”€â”€â”€
          NavHeader(
            title: 'Há»“ sÆ¡ sinh viÃªn',
            subtitle: 'ThÃ´ng tin cÃ¡ nhÃ¢n & TÃ i khoáº£n',
            rightIcon: Icons.edit_outlined,
            onRight: () => EditProfileModal.show(context, currentUser: user),
          ),

          // â”€â”€â”€ 2. SCROLLABLE BODY â”€â”€â”€
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                // 3. MAIN PROFILE CARD
                _ProfileOverviewCard(
                  fullName: fullName,
                  studentId: studentId,
                  avatarUrl: avatarUrl,
                  currentUser: user,
                ),
                const SizedBox(height: 20),

                // 4. ACADEMIC & CONTACT INFO
                const Text(
                  'ThÃ´ng tin há»c táº­p & liÃªn há»‡',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textForeground,
                  ),
                ),
                const SizedBox(height: 12),
                _AcademicInfoCard(
                  faculty: faculty,
                  studentClass: studentClass,
                  email: email,
                  phone: phone,
                ),
                const SizedBox(height: 24),

                // 5. SECURITY & SETTINGS
                const Text(
                  'Báº£o máº­t tÃ i khoáº£n',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textForeground,
                  ),
                ),
                const SizedBox(height: 12),
                _SecuritySettingsCard(currentUser: user),
                const SizedBox(height: 24),

                // 6. CÃ€I Äáº¶T á»¨NG Dá»¤NG & THÃ”NG BÃO (NHáº®C NHá»ž Lá»ŠCH Há»ŒC 1 TIáº¾NG & THá»¬ Gá»¬I)
                const Text(
                  'CÃ i Ä‘áº·t á»©ng dá»¥ng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textForeground,
                  ),
                ),
                const SizedBox(height: 12),
                const _AppSettingsCard(),
                const SizedBox(height: 24),

                // 7. LOGOUT BUTTON
                const _LogoutButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ 1. MAIN PROFILE CARD COMPONENT â”€â”€â”€
class _ProfileOverviewCard extends StatelessWidget {
  final String fullName;
  final String studentId;
  final String avatarUrl;
  final UserModel? currentUser;

  const _ProfileOverviewCard({
    required this.fullName,
    required this.studentId,
    required this.avatarUrl,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar + Camera Badge
          GestureDetector(
            onTap: () => AvatarPickerModal.show(context, currentUser: currentUser),
            child: Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEEF2FF), width: 3),
                    color: const Color(0xFFE2E8F0),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: AppColors.primary,
                        alignment: Alignment.center,
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Change Avatar Pill
          GestureDetector(
            onTap: () => AvatarPickerModal.show(context, currentUser: currentUser),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_outlined, size: 12, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'Äá»•i áº£nh Ä‘áº¡i diá»‡n',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Há» vÃ  tÃªn
          Text(
            fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textForeground,
            ),
          ),
          const SizedBox(height: 4),

          // MSSV
          Text(
            'MSSV: $studentId',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),

          // Status Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 12, color: Color(0xFF059669)),
                SizedBox(width: 5),
                Text(
                  'Äang theo há»c chÃ­nh quy',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ 2. ACADEMIC & CONTACT INFO CARD COMPONENT â”€â”€â”€
class _AcademicInfoCard extends StatelessWidget {
  final String faculty;
  final String studentClass;
  final String email;
  final String phone;

  const _AcademicInfoCard({
    required this.faculty,
    required this.studentClass,
    required this.email,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.menu_book_outlined,
            label: 'Khoa Ä‘Ã o táº¡o',
            value: faculty,
          ),
          const Divider(height: 28, thickness: 1, color: AppColors.cardBorder),
          _buildInfoRow(
            icon: Icons.people_outline,
            label: 'Lá»›p sinh hoáº¡t',
            value: studentClass,
          ),
          const Divider(height: 28, thickness: 1, color: AppColors.cardBorder),
          _buildInfoRow(
            icon: Icons.mail_outline,
            label: 'Email trÆ°á»ng',
            value: email,
          ),
          const Divider(height: 28, thickness: 1, color: AppColors.cardBorder),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Sá»‘ Ä‘iá»‡n thoáº¡i',
            value: phone,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textForeground,
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€ 3. SECURITY SETTINGS CARD COMPONENT â”€â”€â”€
class _SecuritySettingsCard extends StatelessWidget {
  final UserModel? currentUser;

  const _SecuritySettingsCard({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Äá»•i máº­t kháº©u
        InkWell(
          onTap: () => context.push('/profile/change-password'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_outline, size: 18, color: AppColors.primary),
                    SizedBox(width: 12),
                    Text(
                      'Äá»•i máº­t kháº©u tÃ i khoáº£n',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textForeground,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Chá»‰nh sá»­a há»“ sÆ¡ cÃ¡ nhÃ¢n
        InkWell(
          onTap: () => EditProfileModal.show(context, currentUser: currentUser),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: AppColors.primary),
                    SizedBox(width: 12),
                    Text(
                      'Chá»‰nh sá»­a há»“ sÆ¡ cÃ¡ nhÃ¢n',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textForeground,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€ 4. LOGOUT BUTTON COMPONENT â”€â”€â”€
class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => LogoutConfirmDialog.show(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECACA), width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 18, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text(
              'ÄÄƒng xuáº¥t khá»i thiáº¿t bá»‹',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ 5. APP SETTINGS & NOTIFICATIONS COMPONENT â”€â”€â”€
class _AppSettingsCard extends ConsumerStatefulWidget {
  const _AppSettingsCard();

  @override
  ConsumerState<_AppSettingsCard> createState() => _AppSettingsCardState();
}

class _AppSettingsCardState extends ConsumerState<_AppSettingsCard> {
  bool _scheduleReminder = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          // Row 1: Nháº¯c nhá»Ÿ lá»‹ch há»c trÆ°á»›c 1 tiáº¿ng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.alarm_on_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nháº¯c nhá»Ÿ lá»‹ch há»c',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textForeground,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ThÃ´ng bÃ¡o trÆ°á»›c khi báº¯t Ä‘áº§u 1 tiáº¿ng',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: _scheduleReminder,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _scheduleReminder = val;
                    });
                    if (val) {
                      final scheduleItems = ref.read(scheduleProvider).items;
                      NotificationService.instance.syncAllScheduleReminders(scheduleItems);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ÄÃ£ báº­t tÃ­nh nÄƒng nháº¯c nhá»Ÿ lá»‹ch há»c trÆ°á»›c 1 tiáº¿ng!'),
                          duration: Duration(seconds: 2),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    } else {
                      NotificationService.instance.cancelAll();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ÄÃ£ táº¯t toÃ n bá»™ thÃ´ng bÃ¡o nháº¯c nhá»Ÿ lá»‹ch há»c.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),

          // Row 2: Thá»­ gá»­i thÃ´ng bÃ¡o
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: Color(0xFFD97706),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kiá»ƒm tra thÃ´ng bÃ¡o',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textForeground,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Gá»­i thÃ´ng bÃ¡o máº«u lÃªn thiáº¿t bá»‹',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final nextClass = ref.read(nextClassProvider);
                    final subject = nextClass.subject.isNotEmpty ? nextClass.subject : 'LS Äáº£ng CS VN';
                    final time = nextClass.time.isNotEmpty ? nextClass.time : 'Tiáº¿t 1-4';
                    final room = nextClass.room.isNotEmpty ? nextClass.room : '2.21 (CLC)';

                    await NotificationService.instance.sendTestNotification(
                      title: 'ðŸ”” Nháº¯c nhá»Ÿ ca há»c: $subject',
                      body: 'Ca há»c báº¯t Ä‘áº§u lÃºc $time táº¡i phÃ²ng $room. HÃ£y chuáº©n bá»‹ trÆ°á»›c 1 tiáº¿ng!',
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ÄÃ£ gá»­i thÃ´ng bÃ¡o thá»­ nghiá»‡m thÃ nh cÃ´ng!'),
                          backgroundColor: AppColors.primary,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.send_outlined, size: 14),
                  label: const Text('Thá»­ gá»­i', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),

          // Row 3: Widget Launcher mÃ n hÃ¬nh chÃ­nh
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.widgets_outlined,
                        color: Color(0xFF16A34A),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Widget mÃ n hÃ¬nh chÃ­nh',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textForeground,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Äá»“ng bá»™ ra mÃ n hÃ¬nh Ä‘iá»‡n thoáº¡i',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final nextClass = ref.read(nextClassProvider);
                    final gradesState = ref.read(gradesProvider);

                    await HomeWidgetService.instance.updateWidgetData(
                      subject: nextClass.subject.isNotEmpty ? nextClass.subject : 'LS Äáº£ng CS VN',
                      time: nextClass.time.isNotEmpty ? nextClass.time : 'Tiáº¿t 1-4',
                      room: nextClass.room.isNotEmpty ? nextClass.room : '2.21 (CLC)',
                      status: nextClass.capsuleLabel.isNotEmpty ? nextClass.capsuleLabel : 'Lá»ŠCH Há»ŒC',
                      countdown: nextClass.countdownText,
                      gpa: gradesState.gpa4.toStringAsFixed(2),
                      credits: '${gradesState.accumulatedCredits} TC',
                      rank: gradesState.summary.academicRank.isNotEmpty ? gradesState.summary.academicRank : 'KhÃ¡',
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ÄÃ£ Ä‘á»“ng bá»™ dá»¯ liá»‡u ra Widget Launcher!'),
                          backgroundColor: Color(0xFF16A34A),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync_outlined, size: 14),
                  label: const Text('Äá»“ng bá»™', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),

          // Row 4: Máy chủ kết nối (Dành cho kiểm thử / cấu hình hệ thống)
          InkWell(
            onTap: () => ServerConfigDialog.show(context),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.dns_outlined,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Máy chủ kết nối',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textForeground,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ref.watch(serverUrlProvider),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => ServerConfigDialog.show(context),
                    icon: const Icon(Icons.tune_rounded, size: 14),
                    label: const Text('Cấu hình', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
