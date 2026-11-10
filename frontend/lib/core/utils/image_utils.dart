import '../constants/api_endpoints.dart';

/// Danh sách ảnh mẫu dự phòng cũ (đã loại bỏ để không hiển thị ảnh mẫu slideshow)
const List<String> campusFallbackImages = [];

/// Chuyển đổi URL hình ảnh sang backend proxy (/api/news/image-proxy)
/// để tránh lỗi 502 Bad Gateway và lỗi SSL tự ký của máy chủ TTN khi chạy trên thiết bị di động.
/// Loại bỏ hoàn toàn các ảnh mẫu slideshow và unsplash để chỉ hiển thị ảnh thực tế của bài viết.
String getNewsImageUrl(String? imageUrl, [int fallbackIndex = 0]) {
  if (imageUrl == null || imageUrl.trim().isEmpty) {
    return '';
  }

  final trimmed = imageUrl.trim();

  // Bỏ toàn bộ ảnh mẫu slideshow và ảnh unsplash
  final lower = trimmed.toLowerCase();
  if (lower.contains('slideshow') ||
      lower.contains('slideshow2') ||
      lower.contains('unsplash.com') ||
      lower.contains('sample') ||
      lower.contains('demo')) {
    return '';
  }

  // Nếu đã là link proxy, chuẩn hóa lại host theo ApiEndpoints.activeBaseUrl hiện tại
  // để đảm bảo khi chuyển đổi giữa USB cắm dây và Wi-Fi ảnh luôn tải được
  if (trimmed.contains('/image-proxy')) {
    final idx = trimmed.indexOf('?url=');
    if (idx != -1) {
      final rawTarget = trimmed.substring(idx + 5);
      final decoded = Uri.decodeComponent(rawTarget);
      final decodedLower = decoded.toLowerCase();
      if (decodedLower.contains('slideshow') ||
          decodedLower.contains('slideshow2') ||
          decodedLower.contains('unsplash.com') ||
          decodedLower.contains('sample') ||
          decodedLower.contains('demo')) {
        return '';
      }
      return '${ApiEndpoints.activeBaseUrl}${ApiEndpoints.newsImageProxy}?url=${Uri.encodeComponent(decoded)}';
    }
    return trimmed;
  }

  // Nếu là ảnh từ ttn.edu.vn hoặc đường dẫn tương đối từ ttn, điều hướng qua proxy của backend
  if (trimmed.contains('ttn.edu.vn') || trimmed.startsWith('/images/') || !trimmed.startsWith('http')) {
    String rawUrl = trimmed;
    if (!rawUrl.startsWith('http')) {
      rawUrl = 'https://www.ttn.edu.vn${rawUrl.startsWith('/') ? '' : '/'}$rawUrl';
    }
    return '${ApiEndpoints.activeBaseUrl}${ApiEndpoints.newsImageProxy}?url=${Uri.encodeComponent(rawUrl)}';
  }

  return trimmed;
}


