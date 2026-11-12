import 'package:flutter/foundation.dart';
import '../constants/api_endpoints.dart';

/// Danh sách ảnh mẫu dự phòng cũ (đã loại bỏ hoàn toàn để không hiển thị ảnh mẫu slideshow)
const List<String> campusFallbackImages = [];

/// Headers chuẩn giả lập trình duyệt để tải ảnh trực tiếp từ máy chủ TTN mà không bị 502 Bad Gateway
const Map<String, String> ttnImageHeaders = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Referer': 'https://www.ttn.edu.vn/',
  'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
};

/// Chuẩn hóa URL hình ảnh bài viết:
/// - Loại bỏ hoàn toàn các ảnh mẫu slideshow, banner, unsplash, demo
/// - Trên Web: định tuyến qua backend proxy để vượt rào CORS trình duyệt
/// - Trên Thiết bị di động (Android / iOS): giữ nguyên URL trực tiếp của Trường Đại học Tây Nguyên
///   kết hợp gửi kèm User-Agent & Referer header trong CachedNetworkImage để tải ảnh thực tế trực tiếp
///   từ web trường (hoạt động độc lập cả khi kết nối Wi-Fi, 4G mà không phụ thuộc localhost).
String getNewsImageUrl(String? imageUrl, [int fallbackIndex = 0]) {
  if (imageUrl == null || imageUrl.trim().isEmpty) {
    return '';
  }

  final trimmed = imageUrl.trim();

  // Bỏ toàn bộ ảnh mẫu slideshow, unsplash, demo, banner, placeholder, images.jpg
  final lower = trimmed.toLowerCase();
  if (lower.contains('slideshow') ||
      lower.contains('slideshow2') ||
      lower.contains('unsplash.com') ||
      lower.contains('images.jpg') ||
      lower.contains('assets/images') ||
      lower.contains('sample') ||
      lower.contains('placeholder') ||
      lower.contains('demo') ||
      lower.contains('mod_languages') ||
      lower.contains('/banner/') ||
      lower.contains('file_icons')) {
    return '';
  }

  // Nếu URL đang bọc trong image-proxy thì trích xuất URL gốc
  String cleanUrl = trimmed;
  if (cleanUrl.contains('/image-proxy')) {
    final idx = cleanUrl.indexOf('?url=');
    if (idx != -1) {
      final rawTarget = cleanUrl.substring(idx + 5);
      cleanUrl = Uri.decodeComponent(rawTarget);
    }
  }

  // Chuẩn hóa đường dẫn tương đối thành URL đầy đủ của ttn.edu.vn
  if (cleanUrl.startsWith('/images/')) {
    cleanUrl = 'https://www.ttn.edu.vn$cleanUrl';
  } else if (!cleanUrl.startsWith('http')) {
    cleanUrl = 'https://www.ttn.edu.vn/${cleanUrl.replaceFirst(RegExp(r'^/'), '')}';
  }

  // Kiểm tra lại sau khi giải mã để đảm bảo không dính ảnh mẫu
  final cleanLower = cleanUrl.toLowerCase();
  if (cleanLower.contains('slideshow') ||
      cleanLower.contains('slideshow2') ||
      cleanLower.contains('unsplash.com') ||
      cleanLower.contains('images.jpg') ||
      cleanLower.contains('assets/images') ||
      cleanLower.contains('sample') ||
      cleanLower.contains('placeholder') ||
      cleanLower.contains('demo') ||
      cleanLower.contains('mod_languages') ||
      cleanLower.contains('/banner/')) {
    return '';
  }

  // Trên Web: Cần đi qua proxy backend để tránh lỗi CORS
  if (kIsWeb) {
    return '${ApiEndpoints.activeBaseUrl}${ApiEndpoints.newsImageProxy}?url=${Uri.encodeComponent(cleanUrl)}';
  }

  // Trên Native Mobile (Android/iOS): Trả về link trực tiếp
  return cleanUrl;
}

/// Chuyển đổi URL hình ảnh sang backend image proxy để tải dự phòng khi kết nối trực tiếp thất bại
String getProxyImageUrl(String cleanUrl) {
  if (cleanUrl.isEmpty) return '';
  if (cleanUrl.contains(ApiEndpoints.newsImageProxy)) return cleanUrl;
  return '${ApiEndpoints.activeBaseUrl}${ApiEndpoints.newsImageProxy}?url=${Uri.encodeComponent(cleanUrl)}';
}


