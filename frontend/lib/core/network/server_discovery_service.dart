import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
import 'api_client.dart';
import 'server_discovery_io.dart' if (dart.library.html) 'server_discovery_web.dart';

class ServerDiscoveryService {
  ServerDiscoveryService._();

  static const int port = ApiEndpoints.port;

  /// Kiểm tra endpoint /health xem có phải server backend Smart Campus đang chạy hay không
  static Future<bool> verifyHealthEndpoint(String baseUrl, {int timeoutMs = 1800}) async {
    try {
      final clean = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
      final healthUrl = clean.endsWith('/api') ? '$clean/health' : '$clean/api/health';

      final dio = Dio(
        BaseOptions(
          connectTimeout: Duration(milliseconds: timeoutMs),
          receiveTimeout: Duration(milliseconds: timeoutMs),
        ),
      );

      final res = await dio.get(healthUrl);
      if (res.statusCode == 200 && res.data != null) {
        final dataStr = res.data.toString().toLowerCase();
        if (dataStr.contains('ok') || dataStr.contains('campus') || dataStr.contains('cron')) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// Tự động tìm kiếm IP của máy chủ backend trong mạng nội bộ hoặc localhost / emulator
  static Future<String?> discoverServer({
    void Function(String status, double progress)? onProgress,
  }) async {
    onProgress?.call('Đang kiểm tra kết nối hiện tại...', 0.05);

    // 1. Kiểm tra cấu hình hiện tại nếu đang hoạt động
    final activeUrl = ApiEndpoints.activeBaseUrl;
    if (await verifyHealthEndpoint(activeUrl, timeoutMs: 1200)) {
      onProgress?.call('Máy chủ đang hoạt động!', 1.0);
      return activeUrl;
    }

    // Nếu chạy trên Web
    if (kIsWeb) {
      onProgress?.call('Đang kiểm tra máy chủ web...', 0.5);
      final webCandidates = [
        'http://localhost:$port/api',
        'http://127.0.0.1:$port/api',
      ];
      for (final url in webCandidates) {
        if (await verifyHealthEndpoint(url, timeoutMs: 1200)) {
          onProgress?.call('Tìm thấy máy chủ!', 1.0);
          return url;
        }
      }
      return null;
    }

    final testedIps = <String>{};
    final candidateIps = <String>[];

    // 2. Thêm các IP ưu tiên thường dùng nhất
    candidateIps.addAll([
      '127.0.0.1',   // Cáp USB qua adb reverse (khi cắm điện thoại vào máy tính)
      '10.196.33.54', // IP máy tính mạng hiện tại
      '192.168.1.8', // IP Wi-Fi
      '192.168.1.9', // IP cấu hình cũ
      '10.0.2.2',    // Android Emulator host loopback
    ]);

    // 3. Quét các Network Interfaces nội bộ của thiết bị để tìm dải mạng Wi-Fi
    onProgress?.call('Đang phát hiện dải mạng Wi-Fi thiết bị...', 0.15);
    final subnets = await PlatformServerDiscovery.getLocalSubnets();
    if (!subnets.contains('192.168.1')) {
      subnets.add('192.168.1');
    }
    if (!subnets.contains('192.168.0')) {
      subnets.add('192.168.0');
    }

    // Các số host phổ biến trong mạng router/Wi-Fi
    final commonHostEndings = [8, 9, 1, 2, 3, 4, 5, 10, 100, 101, 102, 103, 105, 110, 254];
    for (final subnet in subnets) {
      for (final ending in commonHostEndings) {
        final ip = '$subnet.$ending';
        if (!candidateIps.contains(ip)) {
          candidateIps.add(ip);
        }
      }
    }

    // 4. Kiểm tra nhanh danh sách IP ưu tiên
    final totalPriority = candidateIps.length;
    for (var i = 0; i < totalPriority; i++) {
      final ip = candidateIps[i];
      testedIps.add(ip);
      final currentProgress = 0.2 + (0.35 * (i / totalPriority));
      onProgress?.call('Đang thử kết nối $ip:$port...', currentProgress);

      final open = await PlatformServerDiscovery.pingTcp(ip, port, timeoutMs: 350);
      if (open) {
        final targetUrl = 'http://$ip:$port/api';
        onProgress?.call('Đang xác thực phản hồi từ $ip...', 0.55);
        if (await verifyHealthEndpoint(targetUrl, timeoutMs: 1500)) {
          onProgress?.call('Đã tìm thấy máy chủ tại $ip:$port!', 1.0);
          return targetUrl;
        }
      }
    }

    // 5. Quét song song toàn dải subnet nếu vẫn chưa tìm thấy
    for (final subnet in subnets) {
      final remainingIps = <String>[];
      for (var i = 1; i <= 254; i++) {
        final ip = '$subnet.$i';
        if (!testedIps.contains(ip)) {
          remainingIps.add(ip);
        }
      }

      const chunkSize = 25;
      final totalChunks = (remainingIps.length / chunkSize).ceil();

      for (var c = 0; c < totalChunks; c++) {
        final start = c * chunkSize;
        final end = (start + chunkSize > remainingIps.length) ? remainingIps.length : start + chunkSize;
        final chunk = remainingIps.sublist(start, end);

        final scanProgress = 0.55 + (0.4 * (c / totalChunks));
        onProgress?.call('Đang dò dải $subnet.x (${start + 1}-$end/254)...', scanProgress);

        final results = await Future.wait(
          chunk.map((ip) async {
            final ok = await PlatformServerDiscovery.pingTcp(ip, port, timeoutMs: 380);
            return ok ? ip : null;
          }),
        );

        for (final candidate in results) {
          if (candidate != null) {
            final targetUrl = 'http://$candidate:$port/api';
            onProgress?.call('Đang xác thực phản hồi từ $candidate...', 0.95);
            if (await verifyHealthEndpoint(targetUrl, timeoutMs: 1800)) {
              onProgress?.call('Đã tìm thấy máy chủ tại $candidate:$port!', 1.0);
              return targetUrl;
            }
          }
        }
      }
    }

    onProgress?.call('Không tìm thấy máy chủ backend trong mạng.', 1.0);
    return null;
  }

  /// Tự động dò tìm và cập nhật vào State Provider + Storage
  static Future<String?> autoDetectAndApply(
    WidgetRef ref, {
    void Function(String status, double progress)? onProgress,
  }) async {
    final found = await discoverServer(onProgress: onProgress);
    if (found != null && found.isNotEmpty) {
      ref.read(serverUrlProvider.notifier).setUrl(found);
    }
    return found;
  }
}
