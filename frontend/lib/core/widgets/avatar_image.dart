import 'dart:convert';
import 'package:flutter/material.dart';

/// Widget hiển thị ảnh đại diện hỗ trợ linh hoạt cả URL mạng và Base64 từ Camera/Thư viện
class AvatarImage extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final String fallbackText;
  final BoxFit fit;

  const AvatarImage({
    super.key,
    required this.avatarUrl,
    this.size = 78,
    this.fallbackText = 'S',
    this.fit = BoxFit.cover,
  });

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFF1E3A8A),
      alignment: Alignment.center,
      child: Text(
        fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : 'S',
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    if (url == null || url.isEmpty) {
      return _buildFallback();
    }

    // Hỗ trợ ảnh Base64 từ camera hoặc thư viện máy (data:image/...;base64,...)
    if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        final base64Data = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (ctx, err, stack) => _buildFallback(),
        );
      } catch (_) {
        return _buildFallback();
      }
    }

    // Hỗ trợ ảnh tải từ mạng thông thường (http/https)
    return Image.network(
      url,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (ctx, err, stack) => _buildFallback(),
    );
  }
}

