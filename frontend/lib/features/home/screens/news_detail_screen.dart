import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../models/news_model.dart';
import '../providers/home_provider.dart';

class NewsDetailScreen extends ConsumerWidget {
  final int id;

  const NewsDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final item = homeState.news.firstWhere(
      (n) => n.id == id,
      orElse: () => homeState.news.isNotEmpty
          ? homeState.news.first
          : const NewsModel(id: 0, title: 'Thông báo', summary: ''),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết thông báo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.category,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textForeground,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đăng ngày: ${item.publishedAt ?? "Mới nhất"} • Ban Thông tin ĐH Tây Nguyên',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const Divider(height: 28),
            Text(
              item.summary,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textForeground,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.content ?? item.summary,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
