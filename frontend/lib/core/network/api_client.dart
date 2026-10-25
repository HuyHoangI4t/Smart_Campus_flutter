import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';
import 'server_discovery_service.dart';

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
        ApiEndpoints.customBaseUrl = saved;
        if (saved != state) {
          state = saved;
        }
      }

      // Tự động nhận diện máy chủ trong nền nếu địa chỉ hiện tại không phản hồi
      Future.delayed(const Duration(milliseconds: 300), () async {
        try {
          final isAlive = await ServerDiscoveryService.verifyHealthEndpoint(state, timeoutMs: 1000);
          if (!isAlive) {
            final found = await ServerDiscoveryService.discoverServer();
            if (found != null && found.isNotEmpty && found != state) {
              setUrl(found);
            }
          }
        } catch (_) {}
      });
    } catch (_) {}
  }

  void setUrl(String url) {
    ApiEndpoints.customBaseUrl = url;
    state = url;
    try {
      ref.read(storageServiceProvider).saveServerUrl(url);
    } catch (_) {}
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

