import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
import '../services/socket_service.dart';
import '../storage/secure_storage_service.dart';
import 'server_discovery_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class ServerUrlNotifier extends Notifier<String> {
  bool _isAutoDetecting = false;

  @override
  String build() {
    _initServerUrl();
    // Khởi đầu với mặc định CẮM DÂY USB (127.0.0.1:5000/api)
    return ApiEndpoints.activeBaseUrl;
  }

  Future<void> _initServerUrl() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final saved = await storage.getServerUrl();

      // 1. Kiểm tra CẮM DÂY USB (127.0.0.1:5000) TRƯỚC TIÊN
      final isCableAlive = await ServerDiscoveryService.verifyHealthEndpoint(
        ApiEndpoints.defaultCableBaseUrl,
        timeoutMs: 350,
      );
      if (isCableAlive) {
        setUrl(ApiEndpoints.defaultCableBaseUrl);
        return;
      }

      // 2. Kiểm tra Emulator (10.0.2.2:5000)
      final isEmulatorAlive = await ServerDiscoveryService.verifyHealthEndpoint(
        ApiEndpoints.emulatorBaseUrl,
        timeoutMs: 350,
      );
      if (isEmulatorAlive) {
        setUrl(ApiEndpoints.emulatorBaseUrl);
        return;
      }

      // 3. Nếu trước đó đã lưu URL Wi-Fi và vẫn còn online: dùng tiếp
      if (saved != null && saved.isNotEmpty) {
        final isSavedAlive = await ServerDiscoveryService.verifyHealthEndpoint(
          saved,
          timeoutMs: 600,
        );
        if (isSavedAlive) {
          setUrl(saved);
          return;
        }
      }

      // 4. Nếu không cắm dây và không có kết nối khả dụng: Tự động nhận diện Wi-Fi trong nền
      autoDetectWifiServer();
    } catch (_) {}
  }

  Future<String?> autoDetectWifiServer() async {
    if (_isAutoDetecting) return null;
    _isAutoDetecting = true;
    try {
      final found = await ServerDiscoveryService.discoverServer();
      if (found != null && found.isNotEmpty && found != state) {
        setUrl(found);
        return found;
      }
    } catch (_) {
    } finally {
      _isAutoDetecting = false;
    }
    return null;
  }

  void setUrl(String url) {
    ApiEndpoints.customBaseUrl = url;
    state = url;
    try {
      ref.read(storageServiceProvider).saveServerUrl(url);
    } catch (_) {}
    SocketService.instance.updateServerUrl(url);
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
            final mssv = RegExp(r'"(?:student_id|mssv)"\s*:\s*"?([^",\s}]+)"?').firstMatch(userData)?.group(1);
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
        // Tự động nhận diện lại máy chủ khi mất kết nối (rút dây sang Wi-Fi hoặc đổi mạng Wi-Fi)
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.unknown) {
          Future.microtask(() {
            try {
              ref.read(serverUrlProvider.notifier).autoDetectWifiServer();
            } catch (_) {}
          });
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});
