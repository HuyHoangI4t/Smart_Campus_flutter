import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus/core/theme/app_theme.dart';
import 'package:smart_campus/features/home/models/news_model.dart';
import 'package:smart_campus/features/home/providers/home_provider.dart';
import 'package:smart_campus/features/home/screens/news_detail_screen.dart';

class _MockHomeNotifier extends HomeNotifier {
  @override
  HomeState build() {
    return const HomeState(isLoading: false);
  }
}

void main() {
  testWidgets('NewsDetailScreen renders attachments with ElevatedButton in Row without infinite width crash', (tester) async {
    final articleWithAttachments = NewsModel(
      id: 'test_1',
      title: 'Thông báo danh sách sinh viên nợ học phí năm học 2025-2026',
      summary: 'Chi tiết danh sách sinh viên nợ học phí',
      category: 'Thông báo sinh viên',
      publishedAt: '29/10/2026',
      attachments: const [
        NewsAttachment(
          title: 'Danh sách sinh viên nợ học phí 2025-2026.pdf',
          url: 'https://www.ttn.edu.vn/attachments/article/123/danhsach.pdf',
          size: '245 KB',
          isPdf: true,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeProvider.overrideWith(() => _MockHomeNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: NewsDetailScreen(
            id: 'test_1',
            initialArticle: articleWithAttachments,
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify title and attachment are rendered without BoxConstraints exceptions
    expect(find.text('Thông báo danh sách sinh viên nợ học phí năm học 2025-2026'), findsOneWidget);
    expect(find.text('Danh sách sinh viên nợ học phí 2025-2026.pdf'), findsOneWidget);
    expect(find.text('Mở'), findsOneWidget);
  });
}
