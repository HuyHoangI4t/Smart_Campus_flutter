import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/nav_header.dart';
import '../../../core/widgets/news_card_image.dart';
import '../models/news_model.dart';
import '../providers/home_provider.dart';

/// Màn hình Danh sách Thông báo & Tin tức sinh viên
/// Chuẩn 1:1 theo thiết kế 05_home_announcements_news.jpg
class NewsScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const NewsScreen({super.key, this.initialCategory});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialCategory == 'news') {
      _tabController.index = 2;
    } else if (widget.initialCategory == 'announcement') {
      _tabController.index = 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final allItems = homeState.news;

    final filteredAll = _searchQuery.isEmpty
        ? allItems
        : allItems.where((n) {
            final q = _searchQuery.toLowerCase();
            return n.title.toLowerCase().contains(q) || n.summary.toLowerCase().contains(q);
          }).toList();

    final announcements = filteredAll.where((n) {
      final cat = n.category.toLowerCase();
      final title = n.title.toLowerCase();
      return cat.contains('thông báo') ||
          cat.contains('đào tạo') ||
          cat.contains('học phí') ||
          cat.contains('khảo thí') ||
          title.contains('thông báo');
    }).toList();

    final newsItems = filteredAll.where((n) {
      final cat = n.category.toLowerCase();
      return cat.contains('tin') ||
          cat.contains('hoạt động') ||
          cat.contains('sự kiện') ||
          cat.contains('hội thảo') ||
          !announcements.contains(n);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // NavHeader chuẩn tông màu trường ĐH Tây Nguyên
          NavHeader(
            title: 'Thông báo & Tin tức',
            subtitle: 'Cổng thông tin đào tạo & hoạt động sinh viên TTN',
            showBack: true,
            onBack: () => context.pop(),
          ),

          // Ô tìm kiếm thông báo & tin tức (chuẩn React Native)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm thông báo, tin tức...',
                        hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.cancel, size: 18, color: Color(0xFF94A3B8)),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Sliding Tab Selector: Tất cả / Thông báo SV / Tin tức & Sự kiện
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF132F73),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'Tất cả'),
                  Tab(text: 'Thông báo SV'),
                  Tab(text: 'Tin tức TTN'),
                ],
              ),
            ),
          ),

          // Danh sách nội dung
          Expanded(
            child: homeState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF132F73),
                      strokeWidth: 2.5,
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Tất cả
                      _buildAllView(announcements, newsItems, allItems),
                      // Tab 2: Thông báo SV
                      _buildListView(
                        announcements.isNotEmpty ? announcements : allItems,
                        isAnnouncement: true,
                      ),
                      // Tab 3: Tin tức TTN
                      _buildListView(
                        newsItems.isNotEmpty ? newsItems : allItems,
                        isAnnouncement: false,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // View hiển thị tổng hợp cả Thông báo & Tin tức giống 05_home_announcements_news.jpg
  Widget _buildAllView(
    List<NewsModel> announcements,
    List<NewsModel> newsItems,
    List<NewsModel> allItems,
  ) {
    final listAnnounce = announcements.isNotEmpty ? announcements : allItems.take(5).toList();
    final listNews = newsItems.isNotEmpty ? newsItems : allItems.skip(3).toList();

    return RefreshIndicator(
      color: const Color(0xFF132F73),
      onRefresh: () => ref.read(homeProvider.notifier).fetchNews(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Section 1: Thông báo Sinh viên
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thông báo Sinh viên',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                '${listAnnounce.length} bài mới',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...listAnnounce.map((item) => _buildAnnouncementCard(item)),

          const SizedBox(height: 24),

          // Section 2: Tin tức & Hoạt động
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tin tức & Hoạt động',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                '${listNews.length} bài mới',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...listNews.map((item) => _buildNewsCard(item)),
        ],
      ),
    );
  }

  Widget _buildListView(List<NewsModel> items, {required bool isAnnouncement}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feed_outlined, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Chưa có dữ liệu bài viết mới',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF132F73),
      onRefresh: () => ref.read(homeProvider.notifier).fetchNews(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return isAnnouncement ? _buildAnnouncementCard(item) : _buildNewsCard(item);
        },
      ),
    );
  }

  // Card Thông báo SV (chuẩn 1:1 theo 05_home_announcements_news.jpg)
  Widget _buildAnnouncementCard(NewsModel item) {
    return GestureDetector(
      onTap: () => context.push('/home/news/${item.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row badge & date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.notifications_outlined, size: 13, color: Color(0xFF059669)),
                      SizedBox(width: 4),
                      Text(
                        'Thông báo SV',
                        style: TextStyle(
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.publishedAt ?? 'Mới nhất',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),

            // Footer author & Chi tiết >
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.school_outlined, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.author ?? 'Ban Biên tập TTN',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: const [
                    Text(
                      'Chi tiết',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 14, color: Color(0xFF2563EB)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Card Tin tức & Hoạt động ảnh lớn (chuẩn 1:1 theo 05_home_announcements_news.jpg)
  Widget _buildNewsCard(NewsModel item) {
    return GestureDetector(
      onTap: () => context.push('/home/news/${item.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NewsCardImage(
              imageUrl: item.imageUrl,
              fallbackIndex: item.id,
              height: 170,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.auto_stories_outlined, size: 13, color: Color(0xFF2563EB)),
                            SizedBox(width: 4),
                            Text(
                              'Tin hoạt động',
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item.publishedAt ?? 'Mới nhất',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      height: 1.35,
                    ),
                  ),
                  if (item.summary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
