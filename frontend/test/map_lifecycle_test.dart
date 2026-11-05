import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_campus/core/network/api_client.dart';
import 'package:smart_campus/features/map/providers/map_provider.dart';
import 'package:smart_campus/features/home/providers/home_provider.dart';
import 'package:smart_campus/features/home/models/fallback_campus_news.dart';

class _FakeAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString('{"locations":[],"gates":[],"paths":[]}', 200);
  }
}

ProviderContainer _createTestContainer() {
  final dio = Dio()..httpClientAdapter = _FakeAdapter();
  return ProviderContainer(
    overrides: [
      dioProvider.overrideWithValue(dio),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Map Lifecycle & Background Deactivation Tests', () {
    test('Map starts inactive by default and does not start background listeners', () {
      final container = _createTestContainer();
      addTearDown(container.dispose);

      final state = container.read(mapProvider);
      expect(state.isMapActive, isFalse);
      expect(state.isNavigating, isFalse);
      expect(state.activeRoute, isNull);
    });

    test('activateMap sets isMapActive to true', () {
      final container = _createTestContainer();
      addTearDown(container.dispose);

      container.read(mapProvider.notifier).activateMap();
      expect(container.read(mapProvider).isMapActive, isTrue);
    });

    test('deactivateMap cleans up state and sets isMapActive to false', () {
      final container = _createTestContainer();
      addTearDown(container.dispose);

      final notifier = container.read(mapProvider.notifier);
      notifier.activateMap();
      expect(container.read(mapProvider).isMapActive, isTrue);

      notifier.deactivateMap();
      final state = container.read(mapProvider);
      expect(state.isMapActive, isFalse);
      expect(state.isNavigating, isFalse);
      expect(state.activeRoute, isNull);
      expect(state.selectedLocation, isNull);
      expect(state.searchQuery, isEmpty);
    });
  });

  group('News & Announcements Fallback Resilience Tests', () {
    test('defaultFallbackAnnouncements and defaultFallbackNews are populated', () {
      expect(defaultFallbackAnnouncements, isNotEmpty);
      expect(defaultFallbackNews, isNotEmpty);
      expect(defaultFallbackAnnouncements.first.title, contains('Đại học Tây Nguyên'));
      expect(defaultFallbackNews.first.category, isNotEmpty);
    });

    test('HomeState initializes with fallback news to avoid blank screen', () {
      final container = _createTestContainer();
      addTearDown(container.dispose);

      final homeState = container.read(homeProvider);
      expect(homeState.announcements, isNotEmpty);
      expect(homeState.news, isNotEmpty);
      expect(homeState.allArticles.length, equals(homeState.announcements.length + homeState.news.length));
    });
  });
}
