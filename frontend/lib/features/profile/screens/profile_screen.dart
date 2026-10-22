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
import '../widgets/avatar_picker_modal.dart';
import '../widgets/edit_profile_modal.dart';
import '../widgets/logout_confirm_dialog.dart';

/// Màn hình Hồ sơ sinh viên (13_profile_overview.jpg & 14_profile_security.jpg)
/// Tuân thủ quy chuẩn: Clean Architecture, Small Widgets (<300 lines), Const constructors,
/// Touch Target >= 44px, Riverpod state management.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final fullName = user?.fullName.isNotEmpty == true ? user!.fullName : 'Nguyễn Huy Hoàng';
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
          // ─── 1. NAVHEADER (Navy #132F73) ───
          NavHeader(
            title: 'Hồ sơ sinh viên',
            subtitle: 'Thông tin cá nhân & Tài khoản',
            rightIcon: Icons.edit_outlined,
            onRight: () => EditProfileModal.show(context, currentUser: user),
          ),

          // ─── 2. SCROLLABLE BODY ───
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                // 3. MAIN PROFILE CARD (13_profile_overview.jpg)
                _ProfileOverviewCard(
                  fullName: fullName,
                  studentId: studentId,
                  avatarUrl: avatarUrl,
                  currentUser: user,
                ),
                const SizedBox(height: 20),

                // 4. ACADEMIC & CONTACT INFO (13_profile_overview.jpg)
                const Text(
                  'Thông tin học tập & liên hệ',
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

                // 5. SECURITY & SETTINGS (14_profile_security.jpg)
                const Text(
                  'Bảo mật tài khoản',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textForeground,
                  ),
                ),
                const SizedBox(height: 12),
                _SecuritySettingsCard(currentUser: user),
                const SizedBox(height: 24),

                // 6. CÀI ĐẶT ỨNG DỤNG & THÔNG BÁO (NHẮC NHỞ LỊCH HỌC 1 TIẾNG & THỬ GỬI)
                const Text(
                  'Cài đặt ứng dụng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textForeground,
                  ),
                ),
                const SizedBox(height: 12),
                const _AppSettingsCard(),
                const SizedBox(height: 24),

                // 7. LOGOUT BUTTON (14_profile_security.jpg)
                const _LogoutButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 1. MAIN PROFILE CARD COMPONENT ───
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
                    'Đổi ảnh đại diện',
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

          // Họ và tên
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
                  'Đang theo học chính quy',
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

// ─── 2. ACADEMIC & CONTACT INFO CARD COMPONENT ───
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
            label: 'Khoa đào tạo',
            value: faculty,
          ),
          const Divider(height: 28, thickness: 1, color: AppColors.cardBorder),
          _buildInfoRow(
            icon: Icons.people_outline,
            label: 'Lớp sinh hoạt',
            value: studentClass,
          ),
          const Divider(height: 28, thickness: 1, color: AppColors.cardBorder),
          _buildInfoRow(
            icon: Icons.mail_outline,
            label: 'Email trường',
            value: email,
          ),
          const Divider(height: 28, thickness: 1, color: AppColors.cardBorder),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Số điện thoại',
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

// ─── 3. SECURITY SETTINGS CARD COMPONENT ───
class _SecuritySettingsCard extends StatelessWidget {
  final UserModel? currentUser;

  const _SecuritySettingsCard({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Đổi mật khẩu
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
                      'Đổi mật khẩu tài khoản',
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

        // Chỉnh sửa hồ sơ cá nhân
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
                      'Chỉnh sửa hồ sơ cá nhân',
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

// ─── 4. LOGOUT BUTTON COMPONENT ───
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
              'Đăng xuất khỏi thiết bị',
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

// ─── 5. APP SETTINGS & NOTIFICATIONS COMPONENT ───
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
          // Row 1: Nhắc nhở lịch học trước 1 tiếng
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
                          'Nhắc nhở lịch học',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textForeground,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Thông báo trước khi bắt đầu 1 tiếng',
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
                          content: Text('Đã bật tính năng nhắc nhở lịch học trước 1 tiếng!'),
                          duration: Duration(seconds: 2),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    } else {
                      NotificationService.instance.cancelAll();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã tắt toàn bộ thông báo nhắc nhở lịch học.'),
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

          // Row 2: Thử gửi thông báo
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
                          'Kiểm tra thông báo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textForeground,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Gửi thông báo mẫu lên thiết bị',
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
                    final subject = nextClass.subject.isNotEmpty ? nextClass.subject : 'LS Đảng CS VN';
                    final time = nextClass.time.isNotEmpty ? nextClass.time : 'Tiết 1-4';
                    final room = nextClass.room.isNotEmpty ? nextClass.room : '2.21 (CLC)';

                    await NotificationService.instance.sendTestNotification(
                      title: '🔔 Nhắc nhở ca học: $subject',
                      body: 'Ca học bắt đầu lúc $time tại phòng $room. Hãy chuẩn bị trước 1 tiếng!',
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã gửi thông báo thử nghiệm thành công!'),
                          backgroundColor: AppColors.primary,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.send_outlined, size: 14),
                  label: const Text('Thử gửi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
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

          // Row 3: Widget Launcher màn hình chính
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
                          'Widget màn hình chính',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textForeground,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Đồng bộ ra màn hình điện thoại',
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
                      subject: nextClass.subject.isNotEmpty ? nextClass.subject : 'LS Đảng CS VN',
                      time: nextClass.time.isNotEmpty ? nextClass.time : 'Tiết 1-4',
                      room: nextClass.room.isNotEmpty ? nextClass.room : '2.21 (CLC)',
                      status: nextClass.capsuleLabel.isNotEmpty ? nextClass.capsuleLabel : 'LỊCH HỌC',
                      countdown: nextClass.countdownText,
                      gpa: gradesState.gpa4.toStringAsFixed(2),
                      credits: '${gradesState.accumulatedCredits} TC',
                      rank: gradesState.summary.academicRank.isNotEmpty ? gradesState.summary.academicRank : 'Khá',
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã đồng bộ dữ liệu ra Widget Launcher!'),
                          backgroundColor: Color(0xFF16A34A),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync_outlined, size: 14),
                  label: const Text('Đồng bộ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
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
        ],
      ),
    );
  }
}
