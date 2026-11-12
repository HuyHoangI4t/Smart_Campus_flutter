import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/api_endpoints.dart';
import '../utils/image_utils.dart';

/// Widget hiển thị hình ảnh tin tức / thông báo với tỷ lệ chuẩn và hiệu ứng shimmer
/// Tự động định tuyến qua backend proxy, chống lỗi 502 Bad Gateway và SSL.
/// Phân bổ ảnh fallback đa dạng theo fallbackIndex để tránh tình trạng "toàn 1 ảnh".
class NewsCardImage extends StatefulWidget {
  final String? imageUrl;
  final int fallbackIndex;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const NewsCardImage({
    super.key,
    required this.imageUrl,
    this.fallbackIndex = 0,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  State<NewsCardImage> createState() => _NewsCardImageState();
}

class _NewsCardImageState extends State<NewsCardImage> {
  late String _currentUri;
  bool _triedProxy = false;

  @override
  void initState() {
    super.initState();
    _currentUri = getNewsImageUrl(widget.imageUrl, widget.fallbackIndex);
  }

  @override
  void didUpdateWidget(covariant NewsCardImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl || oldWidget.fallbackIndex != widget.fallbackIndex) {
      _triedProxy = false;
      _currentUri = getNewsImageUrl(widget.imageUrl, widget.fallbackIndex);
    }
  }

  void _onImageError() {
    if (!_triedProxy && _currentUri.isNotEmpty && !_currentUri.contains(ApiEndpoints.newsImageProxy)) {
      if (mounted) {
        setState(() {
          _triedProxy = true;
          _currentUri = getProxyImageUrl(_currentUri);
        });
      }
    }
  }

  /// Khung chờ trung tính nhẹ nhàng, loại bỏ hoàn toàn gradient bìa xanh "TRƯỜNG ĐẠI HỌC TÂY NGUYÊN"
  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height ?? 170,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: widget.borderRadius,
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 36,
          color: Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUri.isEmpty) {
      final placeholder = _buildPlaceholder();
      if (widget.borderRadius != null) {
        return ClipRRect(
          borderRadius: widget.borderRadius!,
          child: placeholder,
        );
      }
      return placeholder;
    }

    Widget imageWidget;

    if (kIsWeb) {
      // Trên Flutter Web: dùng Image.network trực tiếp qua browser HTML engine kèm headers
      imageWidget = Image.network(
        _currentUri,
        headers: ttnImageHeaders,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: widget.width,
            height: widget.height ?? 170,
            color: const Color(0xFFF1F5F9),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF132F73)),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          if (!_triedProxy && _currentUri.isNotEmpty && !_currentUri.contains(ApiEndpoints.newsImageProxy)) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _onImageError());
            return Container(
              width: widget.width,
              height: widget.height ?? 170,
              color: const Color(0xFFF1F5F9),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF132F73)),
                ),
              ),
            );
          }
          return _buildPlaceholder();
        },
      );
    } else {
      // Trên thiết bị di động (Android / iOS): Dùng CachedNetworkImage với cache trên đĩa kèm headers TTN
      imageWidget = CachedNetworkImage(
        imageUrl: _currentUri,
        httpHeaders: ttnImageHeaders,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => Container(
          width: widget.width,
          height: widget.height ?? 170,
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF132F73)),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          if (!_triedProxy && _currentUri.isNotEmpty && !_currentUri.contains(ApiEndpoints.newsImageProxy)) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _onImageError());
            return Container(
              width: widget.width,
              height: widget.height ?? 170,
              color: const Color(0xFFF1F5F9),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF132F73)),
                ),
              ),
            );
          }
          return _buildPlaceholder();
        },
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

