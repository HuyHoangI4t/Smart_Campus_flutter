import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus/core/utils/image_utils.dart';
import 'package:smart_campus/features/home/models/fallback_campus_news.dart';
import 'package:smart_campus/features/home/models/news_model.dart';

void main() {
  group('Kiểm tra logic trích xuất ảnh đầu tiên trong bài viết và loại bỏ ảnh mẫu', () {
    test('Loại bỏ ảnh mẫu slideshow/stock trong getNewsImageUrl', () {
      expect(getNewsImageUrl(null), '');
      expect(getNewsImageUrl(''), '');
      expect(getNewsImageUrl('https://www.ttn.edu.vn/images/slideshow2/B02.jpg'), '');
      expect(getNewsImageUrl('https://images.unsplash.com/photo-12345'), '');
      expect(getNewsImageUrl('https://www.ttn.edu.vn/images/demo.jpg'), '');
    });

    test('Trích xuất ảnh đầu tiên từ thẻ HTML <img> trong content khi không có image_url', () {
      final articleJson = {
        'id': 'news_test_1',
        'title': 'Hội thảo khoa học 2026',
        'summary': 'Tóm tắt bài viết',
        'content': '<p>Đoạn mở đầu</p><p><img src="/images/2026tintuc/first_pic.jpg" alt="Ảnh 1" /></p><p><img src="/images/2026tintuc/second_pic.jpg" /></p>',
        'category': 'Tin tức',
      };

      final news = NewsModel.fromJson(articleJson);
      expect(news.imageUrl, contains('first_pic.jpg'));
      expect(news.imageUrl, isNot(contains('second_pic.jpg')));
      expect(news.imageUrl, isNot(contains('slideshow')));
    });

    test('Trích xuất ảnh đầu tiên từ contentBlocks khi image_url chứa ảnh slideshow mẫu', () {
      final articleJson = {
        'id': 'news_test_2',
        'title': 'Lễ ký kết hợp tác quốc tế',
        'image_url': 'https://www.ttn.edu.vn/images/slideshow2/B05.jpg', // Ảnh mẫu -> phải bị bỏ
        'contentBlocks': [
          {'type': 'text', 'text': 'Nội dung bài viết'},
          {'type': 'image', 'url': 'https://www.ttn.edu.vn/images/2026tintuc/event_banner.jpg', 'caption': 'Lễ ký kết'},
        ],
        'category': 'Tin hoạt động',
      };

      final news = NewsModel.fromJson(articleJson);
      expect(news.imageUrl, contains('event_banner.jpg'));
      expect(news.imageUrl, isNot(contains('slideshow')));
    });

    test('Trích xuất ảnh đầu tiên từ mảng images', () {
      final articleJson = {
        'id': 'news_test_3',
        'title': 'Trao học bổng cho sinh viên',
        'images': [
          'https://www.ttn.edu.vn/images/slideshow2/B12.jpg', // Bỏ qua slideshow
          'https://www.ttn.edu.vn/images/2026tintuc/scholarship.jpg',
          'https://www.ttn.edu.vn/images/2026tintuc/scholarship_group.jpg',
        ],
        'category': 'Tin tức',
      };

      final news = NewsModel.fromJson(articleJson);
      expect(news.imageUrl, contains('scholarship.jpg'));
      expect(news.imageUrl, isNot(contains('slideshow')));
    });

    test('Không gán ảnh mẫu nếu bài viết hoàn toàn không có ảnh', () {
      final articleJson = {
        'id': 'news_test_4',
        'title': 'Tin vắn không ảnh',
        'summary': 'Nội dung ngắn gọn',
        'content': 'Toàn bộ nội dung văn bản thuần không có hình ảnh minh họa nào.',
        'category': 'Tin tức',
      };

      final news = NewsModel.fromJson(articleJson);
      expect(news.imageUrl, isNull);
    });

    test('defaultFallbackNews không còn chứa ảnh slideshow2 và có ảnh bài viết thực tế', () {
      for (final news in defaultFallbackNews) {
        expect(news.imageUrl, isNotNull);
        expect(news.imageUrl, isNot(contains('slideshow')));
        expect(news.imageUrl, contains('2026tintuc'));
      }
    });
  });
}
