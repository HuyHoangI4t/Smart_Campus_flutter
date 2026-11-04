import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/nav_header.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../grades/providers/grades_provider.dart';
import '../widgets/avatar_picker_modal.dart';
import '../widgets/edit_profile_modal.dart';
import '../widgets/logout_confirm_dialog.dart';

/// Màn hình Hồ sơ sinh viên & Thẻ sinh viên điện tử (Redesigned)
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final gradesState = ref.watch(gradesProvider);
    final user = authState.user;
    final isGuest = user?.isGuest ?? true;

    final fullName = user?.fullName.isNotEmpty == true
        ? user!.fullName
        : (isGuest ? 'Khách tham quan' : 'Sinh viên Đại học Tây Nguyên');
    final studentId = user?.studentId.isNotEmpty == true
        ? user!.studentId
        : (isGuest ? 'GUEST' : '23103023');
    final faculty = user?.faculty?.isNotEmpty == true
        ? user!.faculty!
        : (isGuest ? 'Trường Đại học Tây Nguyên' : 'Khoa KHTN & Công nghệ');
    final studentClass = user?.studentClass?.isNotEmpty == true
        ? user!.studentClass!
        : (isGuest ? 'Khách tham quan' : 'K23 - Công nghệ thông tin');
    final email = user?.email?.isNotEmpty == true
        ? user!.email!
        : (isGuest ? 'guest@ttn.edu.vn' : '$studentId@sv.ttn.edu.vn');
    final phone = user?.phone?.isNotEmpty == true
        ? user!.phone!
        : (isGuest ? 'Chưa cập nhật' : '0329 106 783');
    final avatarUrl = (user?.avatarUrl?.isNotEmpty == true)
        ? user!.avatarUrl!
        : 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';

    // Chỉ số học vụ
    final gpa4 = gradesState.gpa4 > 0 ? gradesState.gpa4.toStringAsFixed(2) : (isGuest ? '3.45' : '3.42');
    final gpa10 = gradesState.averageScore10 > 0
        ? gradesState.averageScore10.toStringAsFixed(1)
        : (gradesState.summary.gpa10 > 0 ? gradesState.summary.gpa10.toStringAsFixed(1) : (isGuest ? '8.2' : '8.1'));
    final credits = gradesState.accumulatedCredits > 0
        ? '${gradesState.accumulatedCredits}'
        : (isGuest ? '68' : '64');
    final academicRank = gradesState.summary.academicRank.isNotEmpty
        ? gradesState.summary.academicRank
        : (isGuest ? 'Giỏi' : 'Khá');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          // ─── 1. NAVHEADER CHUẨN NAVY BLUE ───
          NavHeader(
            title: 'Hồ sơ sinh viên',
            subtitle: 'Thẻ điện tử & Thông tin cá nhân',
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
            rightElement: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => context.push('/profile/settings'),
                  icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                  tooltip: 'Cài đặt ứng dụng',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => EditProfileModal.show(context, currentUser: user),
                  icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                  tooltip: 'Chỉnh sửa hồ sơ',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // ─── 2. SCROLLABLE BODY ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // THẺ SINH VIÊN ĐIỆN TỬ (DIGITAL STUDENT ID CARD)
                _DigitalStudentCard(
                  fullName: fullName,
                  studentId: studentId,
                  faculty: faculty,
                  studentClass: studentClass,
                  avatarUrl: avatarUrl,
                  currentUser: user,
                  isGuest: isGuest,
                ),
                const SizedBox(height: 18),

                // TỔNG QUAN CHỈ SỐ HỌC TẬP (ACADEMIC SNAPSHOT)
                _AcademicSnapshotCard(
                  gpa4: gpa4,
                  gpa10: gpa10,
                  credits: credits,
                  academicRank: academicRank,
                  onViewGrades: () => context.push('/grades'),
                ),
                const SizedBox(height: 20),

                // THÔNG TIN HỌC VỤ & ĐÀO TẠO
                _buildSectionTitle('Thông tin đào tạo & Học vụ'),
                const SizedBox(height: 10),
                _InfoCardContainer(
                  items: [
                    _InfoRowItem(
                      icon: Icons.school_outlined,
                      label: 'Khoa quản lý',
                      value: faculty,
                    ),
                    _InfoRowItem(
                      icon: Icons.groups_outlined,
                      label: 'Lớp sinh hoạt',
                      value: studentClass,
                    ),
                    _InfoRowItem(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Bậc đào tạo',
                      value: 'Đại học chính quy',
                    ),
                    _InfoRowItem(
                      icon: Icons.calendar_today_outlined,
                      label: 'Khóa học',
                      value: '2023 - 2027 (K23)',
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // THÔNG TIN LIÊN HỆ & TÀI KHOẢN
                _buildSectionTitle('Thông tin liên hệ & Tài khoản'),
                const SizedBox(height: 10),
                _InfoCardContainer(
                  items: [
                    _InfoRowItem(
                      icon: Icons.badge_outlined,
                      label: 'Mã số sinh viên',
                      value: studentId,
                    ),
                    _InfoRowItem(
                      icon: Icons.email_outlined,
                      label: 'Email sinh viên',
                      value: email,
     
                    ),
                    _InfoRowItem(
                      icon: Icons.phone_android_outlined,
                      label: 'Số điện thoại',
                      value: phone,
                    ),
                    _InfoRowItem(
                      icon: Icons.verified_user_outlined,
                      label: 'Trạng thái học tập',
                      value: isGuest ? 'Khách tham quan' : 'Bình thường (Đạt tiến độ)',
                      valueColor: const Color(0xFF059669),
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // CÀI ĐẶT & BẢO MẬT
                _buildSectionTitle('Cài đặt & Bảo mật'),
                const SizedBox(height: 10),
                _SettingsMenuCard(currentUser: user),
                const SizedBox(height: 24),

                // NÚT ĐĂNG XUẤT
                const _LogoutActionCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textForeground,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}


// ─── 1. THẺ SINH VIÊN ĐIỆN TỬ (DIGITAL STUDENT ID CARD) ───
class _DigitalStudentCard extends StatelessWidget {
  final String fullName;
  final String studentId;
  final String faculty;
  final String studentClass;
  final String avatarUrl;
  final UserModel? currentUser;
  final bool isGuest;

  const _DigitalStudentCard({
    required this.fullName,
    required this.studentId,
    required this.faculty,
    required this.studentClass,
    required this.avatarUrl,
    required this.currentUser,
    required this.isGuest,
  });

  void _showDigitalCardBarcodeModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 14),
              const Text(
                'Mã thẻ sinh viên điện tử',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textForeground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Quét mã này tại Thư viện, Căn tin & Cổng kiểm soát trường',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),

              // Barcode mô phỏng sắc nét
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    // Mô phỏng thanh mã vạch (Barcode lines)
                    SizedBox(
                      height: 64,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(46, (idx) {
                          final isThick = idx % 3 == 0 || idx % 7 == 0;
                          final isGap = idx % 5 == 0;
                          return Container(
                            width: isGap ? 2 : (isThick ? 3.5 : 2),
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            color: isGap ? Colors.transparent : Colors.black87,
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      studentId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                fullName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$studentClass • $faculty',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F2042),
            Color(0xFF132F73),
            Color(0xFF1E40AF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF132F73).withValues(alpha: 0.35),
            offset: const Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Hoa văn chìm phía sau
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -35,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header thẻ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: const Center(
                              child: Icon(Icons.school, color: Colors.white, size: 22),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TRƯỜNG ĐẠI HỌC TÂY NGUYÊN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                SizedBox(height: 1),
                                Text(
                                  'THẺ SINH VIÊN ĐIỆN TỬ • SMART ID',
                                  style: TextStyle(
                                    color: Color(0xFF93C5FD),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Giả lập Smart Chip kim loại vàng sang trọng
                    Container(
                      width: 32,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFFD97706)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFFFEF3C7), width: 0.8),
                      ),
                      child: Center(
                        child: Container(
                          width: 22,
                          height: 14,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFB45309), width: 0.8),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Nội dung thân thẻ (Ảnh đại diện + Tên + MSSV)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Ảnh đại diện viền vàng kim
                    GestureDetector(
                      onTap: () => AvatarPickerModal.show(context, currentUser: currentUser),
                      child: Stack(
                        children: [
                          Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFFCD34D), width: 2.5),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.network(
                                avatarUrl,
                                width: 78,
                                height: 78,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  width: 78,
                                  height: 78,
                                  color: const Color(0xFF1E3A8A),
                                  alignment: Alignment.center,
                                  child: Text(
                                    fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
                                    style: const TextStyle(
                                      fontSize: 32,
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
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, size: 11, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Thông tin chính
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'MSSV: $studentId',
                              style: const TextStyle(
                                color: Color(0xFFFEF08A),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            faculty,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Đáy thẻ: Badge trạng thái + Nút Barcode
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF34D399),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                isGuest ? 'Khách trải nghiệm' : 'Chính quy • Đang học',
                                style: const TextStyle(
                                  color: Color(0xFFD1FAE5),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Nút hiển thị mã vạch thẻ
                    InkWell(
                      onTap: () => _showDigitalCardBarcodeModal(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_2_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 5),
                            Text(
                              'Mã vạch thẻ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 2. TỔNG QUAN CHỈ SỐ HỌC TẬP (ACADEMIC SNAPSHOT) ───
class _AcademicSnapshotCard extends StatelessWidget {
  final String gpa4;
  final String gpa10;
  final String credits;
  final String academicRank;
  final VoidCallback onViewGrades;

  const _AcademicSnapshotCard({
    required this.gpa4,
    required this.gpa10,
    required this.credits,
    required this.academicRank,
    required this.onViewGrades,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
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
                      child: const Icon(Icons.insights_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kết quả tích lũy',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textForeground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Cập nhật theo học kỳ gần nhất',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
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
              const SizedBox(width: 8),
              InkWell(
                onTap: onViewGrades,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Bảng điểm',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                _buildStatItem('GPA HỆ 4', gpa4, isPrimary: true),
                Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
                _buildStatItem('GPA HỆ 10', gpa10),
                Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
                _buildStatItem('TÍN CHỈ', credits),
                Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
                _buildStatItem('XẾP LOẠI', academicRank, isBadge: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {bool isPrimary = false, bool isBadge = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          if (isBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD97706),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isPrimary ? AppColors.primary : AppColors.textForeground,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── 4. KHỐI THÔNG TIN CHI TIẾT (INFO CARD CONTAINER) ───
class _InfoCardContainer extends StatelessWidget {
  final List<_InfoRowItem> items;

  const _InfoCardContainer({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: items),
    );
  }
}

class _InfoRowItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _InfoRowItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? AppColors.textForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppColors.cardBorder),
      ],
    );
  }
}

// ─── 5. CÀI ĐẶT & BẢO MẬT (SETTINGS MENU CARD) ───
class _SettingsMenuCard extends StatelessWidget {
  final UserModel? currentUser;

  const _SettingsMenuCard({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildActionRow(
            icon: Icons.edit_note_rounded,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFEFF6FF),
            title: 'Chỉnh sửa hồ sơ cá nhân',
            subtitle: 'Cập nhật số điện thoại, họ tên, email',
            onTap: () => EditProfileModal.show(context, currentUser: currentUser),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),
          _buildActionRow(
            icon: Icons.lock_reset_rounded,
            iconColor: const Color(0xFF4F46E5),
            iconBg: const Color(0xFFEEF2FF),
            title: 'Đổi mật khẩu tài khoản',
            subtitle: 'Bảo vệ tài khoản và phiên đăng nhập',
            onTap: () => context.push('/profile/change-password'),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),
          _buildActionRow(
            icon: Icons.tune_rounded,
            iconColor: const Color(0xFF059669),
            iconBg: const Color(0xFFECFDF5),
            title: 'Cài đặt ứng dụng & Nhắc nhở',
            subtitle: 'Thông báo lịch học, Widget launcher, Máy chủ',
            onTap: () => context.push('/profile/settings'),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─── 6. NÚT ĐĂNG XUẤT (LOGOUT ACTION CARD) ───
class _LogoutActionCard extends StatelessWidget {
  const _LogoutActionCard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => LogoutConfirmDialog.show(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA), width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 18, color: Color(0xFFDC2626)),
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
