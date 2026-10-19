import 'package:flutter/material.dart';
import 'login_screen.dart';

/// Màn hình Đăng ký - Tận dụng LoginScreen với tab Đăng ký
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(initialTab: 1);
  }
}
