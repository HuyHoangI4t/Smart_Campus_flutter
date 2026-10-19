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
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return ApiEndpoints.webBaseUrl;
    }
    return ApiEndpoints.defaultBaseUrl;
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
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
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

