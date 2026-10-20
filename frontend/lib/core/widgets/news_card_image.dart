import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/image_utils.dart';

/// Widget hiển thị hình ảnh tin tức / thông báo chuẩn 1:1 theo React Native
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
  bool _hasAttemptedFallback = false;

  @override
  void initState() {
    super.initState();
    _currentUri = getNewsImageUrl(widget.imageUrl, widget.fallbackIndex);
  }

  @override
  void didUpdateWidget(covariant NewsCardImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl || oldWidget.fallbackIndex != widget.fallbackIndex) {
      _currentUri = getNewsImageUrl(widget.imageUrl, widget.fallbackIndex);
      _hasAttemptedFallback = false;
    }
  }

  void _triggerFallback() {
    if (!_hasAttemptedFallback && mounted) {
      final fallback = campusFallbackImages[widget.fallbackIndex.abs() % campusFallbackImages.length];
      if (_currentUri != fallback) {
        setState(() {
          _hasAttemptedFallback = true;
          _currentUri = fallback;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    // Trên Flutter Web: dùng Image.network trực tiếp qua browser HTML engine để tương thích 100% với CORS
    if (kIsWeb) {
      imageWidget = Image.network(
        _currentUri,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: widget.width,
            height: widget.height,
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
          if (!_hasAttemptedFallback) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _triggerFallback());
            return Container(
              width: widget.width,
              height: widget.height,
              color: const Color(0xFFF1F5F9),
            );
          }
          return Image.asset(
            'assets/images/images.jpg',
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        },
      );
    } else {
      // Trên thiết bị di động (Android / iOS): Dùng CachedNetworkImage với cache trên đĩa
      imageWidget = CachedNetworkImage(
        imageUrl: _currentUri,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => Container(
          width: widget.width,
          height: widget.height,
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
          final fallback = campusFallbackImages[widget.fallbackIndex.abs() % campusFallbackImages.length];
          return CachedNetworkImage(
            imageUrl: fallback,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorWidget: (c, e, s) => Image.asset(
              'assets/images/images.jpg',
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
            ),
          );
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

