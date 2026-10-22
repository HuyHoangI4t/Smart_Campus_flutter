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

    final rawImg = json['image_url'] ?? json['imageUrl'] ?? json['image'];
    final digits = rawId.replaceAll(RegExp(r'[^0-9]'), '');
    final fallbackIdx = int.tryParse(digits) ?? rawId.hashCode.abs();
    final proxiedImageUrl = getNewsImageUrl(rawImg?.toString(), fallbackIdx);

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
    if (cat.isEmpty) {
      final type = json['type']?.toString();
      cat = type == 'announcement' ? 'Thông báo SV' : 'Tin hoạt động';
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
}
