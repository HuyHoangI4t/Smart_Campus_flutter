import '../constants/api_endpoints.dart';

/// Danh sách ảnh mẫu dự phòng trường đại học (giống chuẩn React Native)
const List<String> campusFallbackImages = [
  'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=800&auto=format&fit=crop&q=80',
  'https://images.unsplash.com/photo-1524178232363-1fb2b075b655?w=800&auto=format&fit=crop&q=80',
  'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800&auto=format&fit=crop&q=80',
  'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=800&auto=format&fit=crop&q=80',
  'https://images.unsplash.com/photo-1562774053-701939374585?w=800&auto=format&fit=crop&q=80',
];

/// Chuyển đổi URL hình ảnh sang backend proxy (/api/news/image-proxy)
/// để tránh lỗi 502 Bad Gateway và lỗi SSL tự ký của máy chủ TTN khi chạy trên thiết bị di động
String getNewsImageUrl(String? imageUrl, [int fallbackIndex = 0]) {
  if (imageUrl == null || imageUrl.trim().isEmpty) {
    return campusFallbackImages[fallbackIndex.abs() % campusFallbackImages.length];
  }

  final trimmed = imageUrl.trim();

  // Nếu đã là link proxy rồi hoặc ảnh unsplash thì giữ nguyên, không bọc lặp
  if (trimmed.contains('/image-proxy') || trimmed.contains('unsplash.com')) {
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

