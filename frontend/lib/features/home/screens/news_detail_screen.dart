import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/nav_header.dart';
import '../../../core/widgets/news_card_image.dart';
import '../models/news_model.dart';
import '../providers/home_provider.dart';

class NewsDetailScreen extends ConsumerStatefulWidget {
  final dynamic id;

  const NewsDetailScreen({super.key, required this.id});

  @override
  ConsumerState<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends ConsumerState<NewsDetailScreen> {
  bool _isLoadingDetail = false;
  String? _fetchedContent;
  List<NewsAttachment>? _fetchedAttachments;
  List<String>? _fetchedImages;
  List<ArticleContentBlock>? _fetchedBlocks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArticleDetailIfNeeded();
    });
  }

  Future<void> _loadArticleDetailIfNeeded() async {
    final homeState = ref.read(homeProvider);
    final targetIdStr = widget.id.toString();
    final allArticles = homeState.allArticles;

    final item = allArticles.firstWhere(
      (n) => n.id == targetIdStr || n.id.contains(targetIdStr),
      orElse: () => allArticles.isNotEmpty
          ? allArticles.first
          : const NewsModel(id: '0', title: 'Thông báo', summary: ''),
    );

    if (item.link == null || item.link!.isEmpty || !item.link!.startsWith('http')) {
      return;
    }

    setState(() => _isLoadingDetail = true);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(
        ApiEndpoints.newsArticleDetail,
        queryParameters: {'url': item.link},
      );

      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null && mounted) {
          final fullContent = data['fullContent']?.toString() ?? '';
          final rawAttachments = data['attachments'] as List? ?? [];
          final attachments = rawAttachments
              .map((att) => NewsAttachment.fromJson(Map<String, dynamic>.from(att)))
              .toList();
          final rawImages = data['images'] as List? ?? [];
          final images = rawImages.map((img) => img.toString()).toList();

          final rawBlocks = data['contentBlocks'] as List? ?? [];
          final blocks = rawBlocks
              .whereType<Map<String, dynamic>>()
              .map((b) => ArticleContentBlock.fromJson(b))
              .toList();

          setState(() {
            if (fullContent.isNotEmpty) _fetchedContent = fullContent;
            if (attachments.isNotEmpty) _fetchedAttachments = attachments;
            if (images.isNotEmpty) _fetchedImages = images;
            if (blocks.isNotEmpty) _fetchedBlocks = blocks;
          });
        }
      }
    } catch (_) {
      // Giữ nguyên dữ liệu có sẵn từ cache DB
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetail = false);
      }
    }
  }

  Future<void> _openAttachment(NewsAttachment att) async {
    if (att.url.isEmpty) return;

    // Ưu tiên mở qua backend proxy download để vượt qua chứng chỉ SSL và chặn tải trực tiếp từ TTN
    final proxyUrl = '${ApiEndpoints.activeBaseUrl}${ApiEndpoints.newsDownloadAttachment}?url=${Uri.encodeComponent(att.url)}';
    try {
      final proxyUri = Uri.parse(proxyUrl);
      final canOpen = await canLaunchUrl(proxyUri);
      if (canOpen) {
        await launchUrl(proxyUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // Dự phòng mở trực tiếp URL gốc nếu proxy gặp sự cố
    try {
      final uri = Uri.parse(att.url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải tệp đính kèm. Vui lòng thử lại sau.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _openOriginalArticle(String? link) async {
    if (link == null || link.isEmpty) return;
    try {
      final uri = Uri.parse(link);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở liên kết gốc.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final targetIdStr = widget.id.toString();
    final allArticles = homeState.allArticles;

    final item = allArticles.firstWhere(
      (n) => n.id == targetIdStr || n.id.contains(targetIdStr),
      orElse: () => allArticles.isNotEmpty
          ? allArticles.first
          : const NewsModel(id: '0', title: 'Thông báo sinh viên', summary: ''),
    );

    final resolvedContent = _fetchedContent ?? item.content ?? item.summary;
    final resolvedAttachments = (_fetchedAttachments != null && _fetchedAttachments!.isNotEmpty)
        ? _fetchedAttachments!
        : item.attachments;
    final resolvedBlocks = (_fetchedBlocks != null && _fetchedBlocks!.isNotEmpty)
        ? _fetchedBlocks!
        : item.contentBlocks;

    final rawImages = (_fetchedImages != null && _fetchedImages!.isNotEmpty)
        ? _fetchedImages!
        : (item.imageUrl != null && item.imageUrl!.isNotEmpty ? [item.imageUrl!] : <String>[]);

    final coverImageUrl = rawImages.isNotEmpty ? rawImages.first : item.imageUrl;
    String? leadingCaption;
    try {
      final firstImg = resolvedBlocks.firstWhere((b) => b.type == 'image');
      leadingCaption = firstImg.caption;
    } catch (_) {}

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          NavHeader(
            title: 'Nội dung chi tiết',
            subtitle: item.category,
            showBack: true,
            onBack: () => context.pop(),
          ),
          if (_isLoadingDetail)
            const LinearProgressIndicator(
              minHeight: 2.5,
              backgroundColor: Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge & Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          item.category,
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        item.publishedAt ?? 'Mới nhất',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Author
                  Row(
                    children: [
                      const Icon(Icons.school_outlined, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.author ?? 'Ban Thông tin Trường Đại học Tây Nguyên',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // Cover Hero Image (chuẩn qua proxy và fallbacks đa dạng - giữ lại duy nhất 1 ảnh bìa đầu bài)
                  NewsCardImage(
                    imageUrl: coverImageUrl,
                    fallbackIndex: item.numericIndex,
                    width: double.infinity,
                    height: 210,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  if (leadingCaption != null && leadingCaption.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      leadingCaption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // Content: Nếu có các contentBlocks xen kẽ ảnh thì hiển thị chuẩn như React Native
                  if (resolvedBlocks.isNotEmpty)
                    ..._buildContentBlocks(resolvedBlocks, item.numericIndex, coverImageUrl)
                  else
                    ..._buildParagraphs(resolvedContent),

                  // Attachments Section
                  if (resolvedAttachments.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.attach_file, color: Color(0xFF2563EB), size: 18),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tệp đính kèm (${resolvedAttachments.length})',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...resolvedAttachments.map((att) => _buildAttachmentCard(att)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Open in Original TTN Website Button
                  if (item.link != null && item.link!.startsWith('http')) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openOriginalArticle(item.link),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text(
                          'Xem trên cổng thông tin TTN.edu.vn',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameImage(String? url1, String? url2) {
    if (url1 == null || url2 == null) return false;
    final u1 = url1.trim();
    final u2 = url2.trim();
    if (u1.isEmpty || u2.isEmpty) return false;
    if (u1 == u2) return true;

    try {
      final file1 = u1.split('?').first.split('/').last.trim();
      final file2 = u2.split('?').first.split('/').last.trim();
      if (file1.isNotEmpty && file2.isNotEmpty && file1.toLowerCase() == file2.toLowerCase()) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  List<Widget> _buildContentBlocks(
    List<ArticleContentBlock> blocks,
    int articleId,
    String? coverImageUrl,
  ) {
    bool hasSkippedLeadingImage = false;

    return blocks.map((block) {
      if (block.type == 'image' && block.url != null && block.url!.isNotEmpty) {
        // Tránh trùng lặp 2 hình ở đầu bài viết:
        // Nếu đây là hình đầu tiên trong nội dung và giống ảnh bìa, hoặc là ảnh đầu bài viết ngay dưới bìa
        if (!hasSkippedLeadingImage) {
          final isSame = _isSameImage(block.url, coverImageUrl);
          final isFirstImageBlock = blocks.indexWhere((b) => b.type == 'image') == blocks.indexOf(block);

          if (isSame || (isFirstImageBlock && coverImageUrl != null && coverImageUrl.isNotEmpty)) {
            hasSkippedLeadingImage = true;
            return const SizedBox.shrink();
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              NewsCardImage(
                imageUrl: block.url,
                fallbackIndex: articleId,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(12),
              ),
              if (block.caption != null && block.caption!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  block.caption!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        );
      }

      if (block.type == 'text' && block.text != null && block.text!.trim().isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            block.text!.trim(),
            style: const TextStyle(
              fontSize: 15.5,
              color: Color(0xFF334155),
              height: 1.65,
              letterSpacing: 0.1,
            ),
          ),
        );
      }

      return const SizedBox.shrink();
    }).toList();
  }

  List<Widget> _buildParagraphs(String content) {
    if (content.trim().isEmpty) {
      return [
        const Text(
          'Không có nội dung chi tiết cho bài viết này.',
          style: TextStyle(fontSize: 15, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
        ),
      ];
    }

    final paragraphs = content
        .split('\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return paragraphs.map((p) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          p,
          style: const TextStyle(
            fontSize: 15.5,
            color: Color(0xFF334155),
            height: 1.65,
            letterSpacing: 0.1,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildAttachmentCard(NewsAttachment att) {
    final isPdf = att.isPdf;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPdf ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
              color: isPdf ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  att.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  att.size != null && att.size!.isNotEmpty
                      ? '${isPdf ? "Tài liệu PDF" : "Tệp đính kèm"} • ${att.size}'
                      : (isPdf ? 'Tài liệu PDF chính thức' : 'Tập tin đính kèm'),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _openAttachment(att),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download, size: 14),
                SizedBox(width: 4),
                Text('Mở'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
