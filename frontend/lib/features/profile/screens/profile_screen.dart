import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/nav_header.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
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

                // 6. LOGOUT BUTTON (14_profile_security.jpg)
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
