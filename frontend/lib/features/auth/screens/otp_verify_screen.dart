import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_otp_view.dart';

/// Màn hình Xác thực OTP Đăng ký tài khoản
/// Chuẩn 1:1 theo 03_auth_otp_verify.jpg
class OtpVerifyScreen extends ConsumerWidget {
  final String studentId;
  final String? email;

  const OtpVerifyScreen({
    super.key,
    required this.studentId,
    this.email,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayEmail = email ?? '$studentId@sv.ttn.edu.vn';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header với Tab Đăng Ký đang chọn
            AuthHeader(
              activeTab: 1,
              onTabChanged: (index) {
                if (index == 0) {
                  context.go('/auth/login');
                }
              },
            ),

            const SizedBox(height: 20),

            // View xác thực OTP
            AuthOtpView(
              studentId: studentId,
              email: displayEmail,
              onVerify: (otp) async {
                final success = await ref
                    .read(authProvider.notifier)
                    .verifyOtp(studentId, otp);

                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Xác thực tài khoản thành công! Vui lòng đăng nhập.',
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  context.go('/auth/login');
                  return true;
                }
                return false;
              },
              onBack: () => context.go('/auth/login'),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
