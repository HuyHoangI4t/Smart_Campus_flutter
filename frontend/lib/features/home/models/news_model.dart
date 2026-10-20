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
  final int id;
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

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    int parsedId = 0;
    if (json['id'] is int) {
      parsedId = json['id'];
    } else if (json['id'] != null) {
      final digits = json['id'].toString().replaceAll(RegExp(r'[^0-9]'), '');
      parsedId = int.tryParse(digits) ?? json['id'].toString().hashCode;
    }

    final rawAttachments = json['attachments'];
    List<NewsAttachment> parsedAttachments = const [];
    if (rawAttachments is List) {
      parsedAttachments = rawAttachments
          .whereType<Map<String, dynamic>>()
          .map((a) => NewsAttachment.fromJson(a))
          .toList();
    } else if (rawAttachments is String && rawAttachments.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawAttachments);
        if (decoded is List) {
          parsedAttachments = decoded
              .whereType<Map<String, dynamic>>()
              .map((a) => NewsAttachment.fromJson(a))
              .toList();
        }
      } catch (_) {}
    }

    final rawBlocks = json['contentBlocks'] ?? json['content_blocks'];
    List<ArticleContentBlock> parsedBlocks = const [];
    if (rawBlocks is List) {
      parsedBlocks = rawBlocks
          .whereType<Map<String, dynamic>>()
          .map((b) => ArticleContentBlock.fromJson(b))
          .toList();
    }

    final rawImg = json['image_url'] ?? json['imageUrl'];
    final proxiedImageUrl = getNewsImageUrl(rawImg?.toString(), parsedId);

    return NewsModel(
      id: parsedId,
      title: json['title'] ?? 'Thông báo',
      summary: json['summary'] ?? json['description'] ?? '',
      content: json['content'] ?? json['summary'],
      imageUrl: proxiedImageUrl,
      publishedAt: json['published_at'] ?? json['date'] ?? json['rawDate'] ?? json['created_at'],
      category: json['category'] ?? (json['type'] == 'news' ? 'Tin tức' : 'Thông báo'),
      author: json['author'] ?? json['sender'] ?? 'Ban Biên tập TTN',
      link: json['link']?.toString() ?? json['url']?.toString(),
      attachments: parsedAttachments,
      contentBlocks: parsedBlocks,
    );
  }
}
