import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_otp_view.dart';
import '../widgets/auth_text_field.dart';

/// Màn hình Đăng nhập / Đăng ký tài khoản sinh viên
/// Chuẩn 1:1 theo 01_auth_login.jpg, 02_auth_register.jpg, 03_auth_otp_verify.jpg
class LoginScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const LoginScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late int _activeTab;
  bool _isOtpStep = false;
  String _pendingEmail = '';

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  // ─── Login Form Controllers ───
  final _loginFormKey = GlobalKey<FormState>();
  final _loginKeyController = TextEditingController();
  final _loginPassController = TextEditingController();
  bool _obscureLoginPass = true;

  // ─── Register Form Controllers ───
  final _regFormKey = GlobalKey<FormState>();
  final _regLastNameController = TextEditingController(); // Họ và tên đệm
  final _regFirstNameController = TextEditingController(); // Tên
  final _regMssvController = TextEditingController(); // MSSV
  final _regPassController = TextEditingController(); // Mật khẩu
  final _regConfirmPassController = TextEditingController(); // Xác nhận mật khẩu
  bool _obscureRegPass = true;
  bool _obscureRegConfirmPass = true;

  @override
  void dispose() {
    _loginKeyController.dispose();
    _loginPassController.dispose();
    _regLastNameController.dispose();
    _regFirstNameController.dispose();
    _regMssvController.dispose();
    _regPassController.dispose();
    _regConfirmPassController.dispose();
    super.dispose();
  }

  // Xử lý đăng nhập
  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    final key = _loginKeyController.text.trim();
    final pass = _loginPassController.text;

    final success = await ref.read(authProvider.notifier).login(key, pass);
    if (!mounted) return;

    if (success) {
      context.go('/home');
    } else {
      final error = ref.read(authProvider).error ?? 'Đăng nhập không thành công';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Xử lý gửi OTP đăng ký (Bước 1: Tiếp Tục)
  Future<void> _handleRegister() async {
    if (!_regFormKey.currentState!.validate()) return;

    final mssv = _regMssvController.text.trim();
    final lastName = _regLastNameController.text.trim();
    final firstName = _regFirstNameController.text.trim();
    final fullName = '$lastName $firstName'.trim();
    final email = '$mssv@sv.ttn.edu.vn';

    final success = await ref.read(authProvider.notifier).register(
          studentId: mssv,
          fullName: fullName,
          email: email,
          password: _regPassController.text,
        );

    if (!mounted) return;

    if (success) {
      setState(() {
        _isOtpStep = true;
        _pendingEmail = email;
      });
    } else {
      final error = ref.read(authProvider).error ?? 'Đăng ký không thành công';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Xử lý xác thực OTP đăng ký (Bước 2: Hoàn tất)
  Future<bool> _handleVerifyOtp(String otp) async {
    final mssv = _regMssvController.text.trim();
    final pass = _regPassController.text;
    final success = await ref.read(authProvider.notifier).verifyOtp(mssv, otp);
    if (!mounted) return false;

    final errorMsg = ref.read(authProvider).error ?? '';
    final isActuallySuccess = success || errorMsg.toLowerCase().contains('thành công');

    if (isActuallySuccess) {
      // Điền sẵn MSSV & mật khẩu vừa tạo vào tab Đăng Nhập
      _loginKeyController.text = mssv;
      _loginPassController.text = pass;

      // Chuyển ngay sang tab Đăng Nhập
      setState(() {
        _isOtpStep = false;
        _activeTab = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký tài khoản thành công! Vui lòng đăng nhập.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg.isNotEmpty ? errorMsg : 'Mã OTP không chính xác'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  // Xử lý vào Chế độ Khách
  Future<void> _handleGuestMode() async {
    await ref.read(authProvider.notifier).enterGuestMode();
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── TOP IMAGE HEADER & TABS ───
            AuthHeader(
              activeTab: _activeTab,
              onTabChanged: (index) {
                setState(() {
                  _activeTab = index;
                  _isOtpStep = false;
                });
              },
            ),

            const SizedBox(height: 20),

            // ─── BODY CONTENT ───
            if (_activeTab == 0)
              _buildLoginForm(authState)
            else if (_isOtpStep)
              AuthOtpView(
                studentId: _regMssvController.text.trim(),
                email: _pendingEmail,
                onVerify: _handleVerifyOtp,
                onBack: () => setState(() => _isOtpStep = false),
                onResend: _handleRegister,
              )
            else
              _buildRegisterForm(authState),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── 01_AUTH_LOGIN FORM ───
  Widget _buildLoginForm(AuthState authState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // EMAIL HOẶC MÃ SINH VIÊN
            AuthTextField(
              label: 'Email hoặc mã sinh viên',
              hint: 'MSSV hoặc Email trường',
              controller: _loginKeyController,
              keyboardType: TextInputType.text,
              prefixIcon: const Icon(
                Icons.mail_outline_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Vui lòng nhập MSSV hoặc Email' : null,
            ),
            const SizedBox(height: 16),

            // MẬT KHẨU
            AuthTextField(
              label: 'Mật khẩu',
              hint: '. . . . . . . .',
              controller: _loginPassController,
              obscureText: _obscureLoginPass,
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureLoginPass = !_obscureLoginPass),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
            ),
            const SizedBox(height: 10),

            // Quên mật khẩu?
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => context.push('/auth/forgot-password'),
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Nút Đăng Nhập Vào Campus
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: authState.isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF132F73),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: authState.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Đăng Nhập Vào Campus',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 22),

            // Divider hoặc
            Row(
              children: const [
                Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'hoặc',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
              ],
            ),
            const SizedBox(height: 22),

            // Nút Khách (giới hạn chức năng)
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: authState.isLoading ? null : _handleGuestMode,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF475569),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Khách (giới hạn chức năng)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 02_AUTH_REGISTER FORM ───
  Widget _buildRegisterForm(AuthState authState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _regFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row: HỌ VÀ TÊN ĐỆM & TÊN
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: AuthTextField(
                    label: 'Họ và tên đệm',
                    hint: 'Nguyễn Văn',
                    controller: _regLastNameController,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Nhập họ' : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: AuthTextField(
                    label: 'Tên',
                    hint: 'A',
                    controller: _regFirstNameController,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Nhập tên' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // MÃ SỐ SINH VIÊN (MSSV)
            AuthTextField(
              label: 'Mã số sinh viên (MSSV)',
              hint: 'MSSV',
              controller: _regMssvController,
              keyboardType: TextInputType.text,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Vui lòng nhập MSSV' : null,
            ),
            const SizedBox(height: 16),

            // MẬT KHẨU
            AuthTextField(
              label: 'Mật khẩu',
              hint: '. . . . . . . .',
              controller: _regPassController,
              obscureText: _obscureRegPass,
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegPass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureRegPass = !_obscureRegPass),
              ),
              validator: (v) =>
                  v != null && v.length >= 6 ? null : 'Mật khẩu tối thiểu 6 ký tự',
            ),
            const SizedBox(height: 16),

            // XÁC NHẬN MẬT KHẨU
            AuthTextField(
              label: 'Xác nhận mật khẩu',
              hint: '. . . . . . . .',
              controller: _regConfirmPassController,
              obscureText: _obscureRegConfirmPass,
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegConfirmPass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () => setState(
                    () => _obscureRegConfirmPass = !_obscureRegConfirmPass),
              ),
              validator: (v) => v == _regPassController.text
                  ? null
                  : 'Mật khẩu xác nhận không khớp',
            ),
            const SizedBox(height: 24),

            // Nút Tiếp Tục
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: authState.isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF132F73),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: authState.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Tiếp Tục',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
