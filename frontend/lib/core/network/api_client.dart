import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class ServerUrlNotifier extends Notifier<String> {
  @override
  String build() {
    _initFromStorage();
    return ApiEndpoints.activeBaseUrl;
  }

  Future<void> _initFromStorage() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final saved = await storage.getServerUrl();
      if (saved != null && saved.isNotEmpty) {
        if (saved.contains('192.168.1.') && !saved.contains(ApiEndpoints.lanHost)) {
          final updated = saved.replaceAll(RegExp(r'192\.168\.1\.\d+'), ApiEndpoints.lanHost);
          await storage.saveServerUrl(updated);
          state = updated;
          return;
        }
        if (saved != state) {
          state = saved;
        }
      }
    } catch (_) {}
  }

  void setUrl(String url) {
    state = url;
  }
}

final serverUrlProvider = NotifierProvider<ServerUrlNotifier, String>(ServerUrlNotifier.new);

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final activeBaseUrl = ref.watch(serverUrlProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: activeBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        final userData = await storage.getUserData();
        if (userData != null && userData.isNotEmpty) {
          try {
            final mssv = RegExp(r'"(?:student_id|mssv)"\s*:\s*"([^"]+)"').firstMatch(userData)?.group(1);
            if (mssv != null && mssv.isNotEmpty) {
              options.headers['x-mssv'] = mssv;
            }
          } catch (_) {}
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        if (kDebugMode) {
          print('⚠️ [API Error] ${error.requestOptions.path}: ${error.message}');
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});

