import 'package:flutter/material.dart';

/// Bảng mã màu chuẩn của Smart Campus theo quy chuẩn thiết kế hệ thống
/// Đồng bộ với Android 16 Material 3 Expressive & iOS HIG
class AppColors {
  AppColors._();

  // Theme & Brand
  static const Color primary = Color(0xFF132F73); // Xanh Navy thương hiệu
  static const Color primaryLight = Color(0xFF1E3E8F); // Xanh sáng Header / Card
  static const Color accent = Color(0xFF5B61F4); // Tím Indigo điểm nhấn
  static const Color accentLight = Color(0xFF818CF8); // Tím sáng Link/Action
  static const Color background = Color(0xFFF3F6FD); // Nền ứng dụng chính
  static const Color cardBg = Color(0xFFFFFFFF); // Nền thẻ card
  static const Color muted = Color(0xFFEEF2F9); // Nền phụ / Chip
  static const Color border = Color(0xFFE2E8F0); // Viền kẻ mảnh
  static const Color cardBorder = Color(0xFFE2E8F0); // Viền thẻ card

  // Text Colors
  static const Color textForeground = Color(0xFF0F172A); // Chữ đậm chính
  static const Color text = Color(0xFF0F172A); // Chữ tiêu đề
  static const Color textSecondary = Color(0xFF64748B); // Chữ phụ
  static const Color textMuted = Color(0xFF64748B); // Chữ chú thích
  static const Color textSubtle = Color(0xFF94A3B8); // Chữ mờ nhỏ
  static const Color textLight = Color(0xFF93C5FD); // Chữ xanh sáng

  // Status & Semantic Colors
  static const Color success = Color(0xFF10B981); // Thành công / Đang học
  static const Color warning = Color(0xFFF59E0B); // Cảnh báo / Sắp tới
  static const Color danger = Color(0xFFEF4444); // Lỗi / SOS
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6); // Thông tin
  static const Color purple = Color(0xFF8B5CF6); // Giảng đường

  // Dark Mode Overrides
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkCardBg = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
}

