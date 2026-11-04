import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Lớp tương thích ngược: Điều hướng thẳng sang trang Cài đặt ứng dụng (AppSettingsScreen)
class AppSettingsModal {
  const AppSettingsModal._();

  static Future<void> show(BuildContext context) async {
    context.push('/profile/settings');
  }
}
