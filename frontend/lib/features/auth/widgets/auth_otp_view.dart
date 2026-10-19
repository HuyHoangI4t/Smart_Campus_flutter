import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class AuthOtpView extends StatefulWidget {
  final String studentId;
  final String email;
  final Future<bool> Function(String otp) onVerify;
  final VoidCallback onBack;
  final VoidCallback? onResend;

  const AuthOtpView({
    super.key,
    required this.studentId,
    required this.email,
    required this.onVerify,
    required this.onBack,
    this.onResend,
  });

  @override
  State<AuthOtpView> createState() => _AuthOtpViewState();
}

class _AuthOtpViewState extends State<AuthOtpView> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );

  int _secondsRemaining = 60;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentOtp => _controllers.map((c) => c.text).join();

  Future<void> _submitOtp() async {
    final otp = _currentOtp;
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ 6 chữ số mã OTP'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await widget.onVerify(otp);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      // Clear OTP on error
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayEmail = widget.email.isNotEmpty
        ? widget.email
        : '${widget.studentId}@sv.ttn.edu.vn';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── 1. GREEN SUCCESS BANNER ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF16A34A),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đăng ký tài khoản thành công.',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── 2. INFO CARD ───
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.mail_outline_rounded,
                  color: Color(0xFF132F73),
                  size: 36,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Xác thực Email đăng ký',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      height: 1.45,
                    ),
                    children: [
                      const TextSpan(text: 'Mã OTP 6 chữ số đã được gửi đến email '),
                      TextSpan(
                        text: displayEmail,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const TextSpan(
                        text: '.\nNhập mã để hoàn tất đăng ký và lưu tài khoản vào hệ thống.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ─── 3. OTP 6-DIGIT INPUT ───
          const Text(
            'MÃ OTP 6 CHỮ SỐ',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) => _buildOtpBox(index)),
          ),
          const SizedBox(height: 18),

          // ─── 4. RESEND TIMER ───
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                _secondsRemaining > 0
                    ? Text(
                        'Gửi lại mã sau ${_secondsRemaining}s',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          _startCountdown();
                          widget.onResend?.call();
                        },
                        child: const Text(
                          'Gửi lại mã ngay',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ─── 5. BACK BUTTON ───
          Center(
            child: GestureDetector(
              onTap: widget.onBack,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.arrow_back, size: 16, color: Color(0xFF3B82F6)),
                    SizedBox(width: 4),
                    Text(
                      'Quay lại',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ─── 6. PRIMARY BUTTON: ĐĂNG KÝ ───
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF132F73),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Đăng Ký',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final controller = _controllers[index];
    final focusNode = _focusNodes[index];
    final hasText = controller.text.isNotEmpty;

    return Container(
      width: 46,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasText
              ? const Color(0xFF132F73)
              : const Color(0xFFCBD5E1),
          width: hasText ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF132F73),
          ),
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (val) {
            setState(() {});
            if (val.isNotEmpty && index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else if (val.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }
}

