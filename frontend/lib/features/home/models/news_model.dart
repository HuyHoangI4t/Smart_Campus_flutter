import 'dart:convert';
import '../../../core/utils/image_utils.dart';

class NewsAttachment {
  final String title;
  final String url;
  final String? size;
  final bool isPdf;

  const NewsAttachment({
    required this.title,
    required this.url,
    this.size,
    this.isPdf = false,
  });

  factory NewsAttachment.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['url']?.toString() ?? '';
    return NewsAttachment(
      title: json['title']?.toString() ?? 'Tài liệu đính kèm',
      url: rawUrl,
      size: json['size']?.toString(),
      isPdf: json['isPdf'] == true || rawUrl.toLowerCase().contains('.pdf'),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'size': size,
    'isPdf': isPdf,
  };
}

class ArticleContentBlock {
  final String type; // 'text' | 'image'
  final String? text;
  final String? url;
  final String? caption;

  const ArticleContentBlock({
    required this.type,
    this.text,
    this.url,
    this.caption,
  });

  factory ArticleContentBlock.fromJson(Map<String, dynamic> json) {
    return ArticleContentBlock(
      type: json['type']?.toString() ?? 'text',
      text: json['text']?.toString(),
      url: json['url']?.toString(),
      caption: json['caption']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'text': text,
    'url': url,
    'caption': caption,
  };
}

class NewsModel {
  final String id;
  final String title;
  final String summary;
  final String? content;
  final String? imageUrl;
  final String? publishedAt;
  final String category;
  final String? author;
  final String? link;
  final List<NewsAttachment> attachments;
  final List<ArticleContentBlock> contentBlocks;

  const NewsModel({
    required this.id,
    required this.title,
    required this.summary,
    this.content,
    this.imageUrl,
    this.publishedAt,
    this.category = 'Tin tức',
    this.author,
    this.link,
    this.attachments = const [],
    this.contentBlocks = const [],
  });

  int get numericIndex {
    final digits = id.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? id.hashCode.abs();
  }

  bool get isAnnouncement =>
      category.toLowerCase().contains('thông báo') ||
      category.toLowerCase().contains('announcement') ||
      id.startsWith('ann') ||
      id.contains('-ann-') ||
      id.startsWith('sample-ann');

  static bool _isSampleOrSlideshow(String url) {
    final lower = url.toLowerCase();
    return lower.contains('slideshow') ||
        lower.contains('slideshow2') ||
        lower.contains('unsplash.com') ||
        lower.contains('sample') ||
        lower.contains('demo') ||
        lower.contains('mod_languages') ||
        lower.contains('/banner/') ||
        lower.contains('com_attachments') ||
        lower.contains('file_icons');
  }

  /// Trích xuất ảnh đầu tiên có trong bài viết (từ contentBlocks, mảng images, HTML content, thẻ img)
  /// và loại bỏ các ảnh mẫu/slideshow/stock để hiển thị ảnh thực tế
  static String? extractFirstArticleImage({
    String? rawImageUrl,
    dynamic rawImages,
    List<ArticleContentBlock>? blocks,
    String? content,
    String? summary,
    String? description,
  }) {
    // 1. Kiểm tra rawImageUrl trực tiếp nếu có và KHÔNG phải là ảnh slideshow/mẫu
    if (rawImageUrl != null && rawImageUrl.trim().isNotEmpty) {
      final trimmed = rawImageUrl.trim();
      if (!_isSampleOrSlideshow(trimmed)) {
        return trimmed;
      }
    }

    // 2. Kiểm tra mảng images (json['images'])
    if (rawImages is List && rawImages.isNotEmpty) {
      for (final im in rawImages) {
        final str = im?.toString().trim();
        if (str != null && str.isNotEmpty && !_isSampleOrSlideshow(str)) {
          return str;
        }
      }
    }

    // 3. Kiểm tra parsedBlocks (block đầu tiên có type == 'image')
    if (blocks != null && blocks.isNotEmpty) {
      for (final b in blocks) {
        if (b.type == 'image' && b.url != null && b.url!.trim().isNotEmpty) {
          final str = b.url!.trim();
          if (!_isSampleOrSlideshow(str)) {
            return str;
          }
        }
      }
    }

    // 4. Trích xuất thẻ <img> đầu tiên trong content hoặc summary (HTML)
    final htmlSources = [content, summary, description];
    final imgRegex = RegExp(r'''<img[^>]+src=["']([^"']+)["']''', caseSensitive: false);
    for (final html in htmlSources) {
      if (html != null && html.isNotEmpty) {
        final match = imgRegex.firstMatch(html);
        if (match != null) {
          final src = match.group(1)?.trim();
          if (src != null && src.isNotEmpty && !_isSampleOrSlideshow(src)) {
            return src;
          }
        }
      }
    }

    // 5. Trích xuất markdown image: ![...](...)
    final mdRegex = RegExp(r'!\[.*?\]\((https?://[^\s\)]+|\/[^\s\)]+)\)');
    for (final text in htmlSources) {
      if (text != null && text.isNotEmpty) {
        final match = mdRegex.firstMatch(text);
        if (match != null) {
          final src = match.group(1)?.trim();
          if (src != null && src.isNotEmpty && !_isSampleOrSlideshow(src)) {
            return src;
          }
        }
      }
    }

    return null;
  }

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ??
        json['guid']?.toString() ??
        '${DateTime.now().millisecondsSinceEpoch}';

    final rawAttachments = json['attachments'];
    final List<NewsAttachment> parsedAttachments = [];
    if (rawAttachments is List) {
      for (final a in rawAttachments) {
        if (a is Map<String, dynamic>) {
          parsedAttachments.add(NewsAttachment.fromJson(a));
        } else if (a is Map) {
          parsedAttachments.add(NewsAttachment.fromJson(Map<String, dynamic>.from(a)));
        }
      }
    } else if (rawAttachments is String && rawAttachments.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawAttachments);
        if (decoded is List) {
          for (final a in decoded) {
            if (a is Map) {
              parsedAttachments.add(NewsAttachment.fromJson(Map<String, dynamic>.from(a)));
            }
          }
        }
      } catch (_) {}
    }

    final rawBlocks = json['contentBlocks'] ?? json['content_blocks'];
    final List<ArticleContentBlock> parsedBlocks = [];
    if (rawBlocks is List) {
      for (final b in rawBlocks) {
        if (b is Map<String, dynamic>) {
          parsedBlocks.add(ArticleContentBlock.fromJson(b));
        } else if (b is Map) {
          parsedBlocks.add(ArticleContentBlock.fromJson(Map<String, dynamic>.from(b)));
        }
      }
    }

    // Format display date: DD/MM/YYYY
    String? pubDate = json['published_at']?.toString() ??
        json['date']?.toString() ??
        json['rawDate']?.toString() ??
        json['created_at']?.toString();
    if (pubDate != null && pubDate.contains('T')) {
      try {
        final dt = DateTime.parse(pubDate);
        pubDate = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {}
    }

    // Determine category
    String cat = json['category']?.toString() ?? '';
    final rawType = json['type']?.toString();
    if (cat.isEmpty) {
      cat = rawType == 'announcement' ? 'Thông báo SV' : 'Tin hoạt động';
    }

    final isAnn = rawType == 'announcement' ||
        cat.toLowerCase().contains('thông báo') ||
        rawId.startsWith('ann') ||
        rawId.contains('-ann-') ||
        rawId.startsWith('sample-ann');

    final rawImg = json['image_url'] ?? json['imageUrl'] ?? json['image'];
    final digits = rawId.replaceAll(RegExp(r'[^0-9]'), '');
    final fallbackIdx = int.tryParse(digits) ?? rawId.hashCode.abs();

    // Lấy ảnh đầu tiên trong bài viết (bỏ ảnh mẫu/slideshow)
    String? proxiedImageUrl;
    if (!isAnn) {
      String? firstImage = extractFirstArticleImage(
        rawImageUrl: rawImg?.toString(),
        rawImages: json['images'],
        blocks: parsedBlocks,
        content: json['content']?.toString(),
        summary: json['summary']?.toString(),
        description: json['description']?.toString(),
      );

      if (firstImage != null && firstImage.isNotEmpty) {
        if (!firstImage.startsWith('http')) {
          firstImage = 'https://www.ttn.edu.vn${firstImage.startsWith('/') ? '' : '/'}$firstImage';
        }
        final proxied = getNewsImageUrl(firstImage, fallbackIdx);
        proxiedImageUrl = proxied.isNotEmpty ? proxied : null;
      }
    }

    return NewsModel(
      id: rawId,
      title: json['title']?.toString() ?? 'Thông báo',
      summary: json['summary']?.toString() ?? json['description']?.toString() ?? '',
      content: json['content']?.toString() ?? json['summary']?.toString(),
      imageUrl: proxiedImageUrl,
      publishedAt: pubDate,
      category: cat,
      author: json['author']?.toString() ?? json['sender']?.toString() ?? 'Ban Biên tập TTN',
      link: json['link']?.toString() ?? json['url']?.toString() ?? json['guid']?.toString(),
      attachments: parsedAttachments,
      contentBlocks: parsedBlocks,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'content': content,
    'imageUrl': imageUrl,
    'publishedAt': publishedAt,
    'category': category,
    'author': author,
    'link': link,
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'contentBlocks': contentBlocks.map((b) => b.toJson()).toList(),
  };
}
