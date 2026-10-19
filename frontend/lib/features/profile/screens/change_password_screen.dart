import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/nav_header.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _loading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showNoticeDialog({
    required String title,
    required String message,
    required bool isSuccess,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      barrierColor: const Color(0x8C0F172A),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSuccess ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                    size: 28,
                    color: isSuccess ? AppColors.success : AppColors.danger,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textForeground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? AppColors.primary : AppColors.danger,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onConfirm?.call();
                  },
                  child: const Text(
                    'Đồng ý',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

  Future<void> _handleChangePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty) {
      _showNoticeDialog(
        title: 'Thiếu thông tin',
        message: 'Vui lòng nhập mật khẩu hiện tại của bạn.',
        isSuccess: false,
      );
      return;
    }

    if (newPassword.length < 6) {
      _showNoticeDialog(
        title: 'Mật khẩu chưa đủ mạnh',
        message: 'Mật khẩu mới phải có ít nhất 6 ký tự để đảm bảo an toàn.',
        isSuccess: false,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      _showNoticeDialog(
        title: 'Mật khẩu không khớp',
        message: 'Xác nhận mật khẩu mới không trùng khớp. Vui lòng kiểm tra lại.',
        isSuccess: false,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        ApiEndpoints.changePassword,
        data: {
          'old_password': currentPassword,
          'new_password': newPassword,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 && response.data['success'] == true) {
        _showNoticeDialog(
          title: 'Đổi mật khẩu thành công!',
          message: 'Mật khẩu tài khoản sinh viên của bạn đã được cập nhật. Vui lòng ghi nhớ mật khẩu mới cho các lần đăng nhập tiếp theo.',
          isSuccess: true,
          onConfirm: () {
            if (context.mounted) context.pop();
          },
        );
      } else {
        _showNoticeDialog(
          title: 'Không thể đổi mật khẩu',
          message: response.data['message'] ?? 'Mật khẩu hiện tại không chính xác hoặc đã có lỗi xảy ra. Vui lòng thử lại.',
          isSuccess: false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showNoticeDialog(
        title: 'Lỗi kết nối',
        message: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại kết nối mạng.',
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ─── NAVHEADER ───
          NavHeader(
            title: 'Đổi mật khẩu',
            subtitle: 'Bảo vệ an toàn tài khoản sinh viên',
            showBack: true,
            onBack: () => context.pop(),
          ),

          // ─── SCROLLABLE FORM ───
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              children: [
                // ─── NOTICE BOX (16_profile_change_password.jpg) ───
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                  ),
                  child: const Text(
                    'Lưu ý: Mật khẩu mới cần tối thiểu 6 ký tự. Tránh sử dụng ngày sinh hoặc chuỗi ký tự dễ đoán.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ─── 1. MẬT KHẨU HIỆN TẠI ───
                _buildPasswordField(
                  label: 'Mật khẩu hiện tại',
                  hint: 'Nhập mật khẩu hiện tại',
                  controller: _currentPasswordController,
                  obscureText: !_showCurrent,
                  onToggleObscure: () => setState(() => _showCurrent = !_showCurrent),
                  marginBottom: 16,
                ),

                // ─── 2. MẬT KHẨU MỚI ───
                _buildPasswordField(
                  label: 'Mật khẩu mới',
                  hint: 'Tối thiểu 6 ký tự',
                  controller: _newPasswordController,
                  obscureText: !_showNew,
                  onToggleObscure: () => setState(() => _showNew = !_showNew),
                  marginBottom: 16,
                ),

                // ─── 3. XÁC NHẬN MẬT KHẨU MỚI ───
                _buildPasswordField(
                  label: 'Xác nhận mật khẩu mới',
                  hint: 'Nhập lại mật khẩu mới',
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirm,
                  onToggleObscure: () => setState(() => _showConfirm = !_showConfirm),
                  marginBottom: 28,
                ),

                // ─── SUBMIT BUTTON ───
                InkWell(
                  onTap: _loading ? null : _handleChangePassword,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          offset: const Offset(0, 3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Cập nhật mật khẩu',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required double marginBottom,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textForeground,
            ),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textForeground,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF94A3B8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: onToggleObscure,
              splashRadius: 18,
            ),
          ),
        ),
        SizedBox(height: marginBottom),
      ],
    );
  }
}
