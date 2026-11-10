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

  /// Kiểm tra endpoint /health xem server backend Smart Campus có đang hoạt động hay không
  static Future<bool> verifyHealthEndpoint(String baseUrl, {int timeoutMs = 1200}) async {
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
        if (dataStr.contains('ok') || dataStr.contains('campus') || dataStr.contains('smart_campus')) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// Tự động tìm kiếm IP máy chủ backend:
  /// 1. Mặc định ưu tiên kiểm tra cắm dây (USB ADB Reverse qua 127.0.0.1:5000)
  /// 2. Kiểm tra máy ảo Android Emulator (10.0.2.2:5000)
  /// 3. Tự động nhận diện khi dùng Wi-Fi (UDP Broadcast probe + Quét dải subnet Wi-Fi)
  static Future<String?> discoverServer({
    void Function(String status, double progress)? onProgress,
  }) async {
    // A. Nếu chạy trên Web:
    if (kIsWeb) {
      onProgress?.call('Đang kiểm tra máy chủ web...', 0.5);
      final webCandidates = [
        'http://localhost:$port/api',
        'http://127.0.0.1:$port/api',
      ];
      for (final url in webCandidates) {
        if (await verifyHealthEndpoint(url, timeoutMs: 1000)) {
          onProgress?.call('Tìm thấy máy chủ web!', 1.0);
          return url;
        }
      }
      return null;
    }

    // B. ƯU TIÊN SỐ 1: CẮM DÂY MẶC ĐỊNH (USB ADB Reverse -> 127.0.0.1:5000)
    onProgress?.call('Kiểm tra chế độ cắm dây USB (127.0.0.1:$port)...', 0.1);
    const cableUrl = 'http://127.0.0.1:$port/api';
    if (await verifyHealthEndpoint(cableUrl, timeoutMs: 400)) {
      onProgress?.call('Đã kết nối máy chủ qua cắm dây USB!', 1.0);
      return cableUrl;
    }

    // C. ƯU TIÊN SỐ 2: ANDROID EMULATOR (10.0.2.2:5000)
    const emulatorUrl = 'http://10.0.2.2:$port/api';
    if (await verifyHealthEndpoint(emulatorUrl, timeoutMs: 350)) {
      onProgress?.call('Đã kết nối máy chủ qua giả lập Emulator!', 1.0);
      return emulatorUrl;
    }

    // D. TỰ ĐỘNG NHẬN DIỆN KHI DÙNG WI-FI (KHÔNG CẮM DÂY)
    onProgress?.call('Không cắm dây. Đang tự động nhận diện máy chủ qua Wi-Fi...', 0.25);

    // D.1: Gửi UDP Broadcast probe siêu tốc (~10-50ms)
    try {
      final udpFoundIp = await PlatformServerDiscovery.probeUdpBroadcast(timeoutMs: 700);
      if (udpFoundIp != null && udpFoundIp.isNotEmpty) {
        final targetUrl = 'http://$udpFoundIp:$port/api';
        onProgress?.call('Tìm thấy phản hồi Wi-Fi từ $udpFoundIp...', 0.55);
        if (await verifyHealthEndpoint(targetUrl, timeoutMs: 1000)) {
          onProgress?.call('Đã nhận diện máy chủ Wi-Fi: $udpFoundIp:$port', 1.0);
          return targetUrl;
        }
      }
    } catch (_) {}

    // D.2: Lấy dải mạng Wi-Fi thực tế của thiết bị
    onProgress?.call('Đang phát hiện dải mạng Wi-Fi thiết bị...', 0.35);
    final subnets = await PlatformServerDiscovery.getLocalSubnets();
    if (!subnets.contains('192.168.1')) subnets.add('192.168.1');
    if (!subnets.contains('192.168.0')) subnets.add('192.168.0');

    final candidateIps = <String>[
      '192.168.1.39', // Host machine Wi-Fi IP
      '192.168.1.17', // LTDDDNT fallback LAN IP
    ];
    // Các IP phổ biến trong mạng router/Wi-Fi gia đình và trường học
    final commonHostEndings = [39, 17, 34, 5, 8, 9, 1, 2, 3, 4, 10, 15, 20, 50, 54, 100, 101, 102, 105, 110, 254];
    for (final subnet in subnets) {
      for (final ending in commonHostEndings) {
        final ip = '$subnet.$ending';
        if (!candidateIps.contains(ip)) candidateIps.add(ip);
      }
    }

    // D.3: Thử nhanh danh sách IP ưu tiên
    final testedIps = <String>{};
    for (var i = 0; i < candidateIps.length; i++) {
      final ip = candidateIps[i];
      testedIps.add(ip);
      final open = await PlatformServerDiscovery.pingTcp(ip, port, timeoutMs: 250);
      if (open) {
        final targetUrl = 'http://$ip:$port/api';
        if (await verifyHealthEndpoint(targetUrl, timeoutMs: 1200)) {
          onProgress?.call('Đã tìm thấy máy chủ Wi-Fi tại $ip:$port!', 1.0);
          return targetUrl;
        }
      }
    }

    // D.4: Quét toàn dải subnet song song nếu chưa tìm thấy
    for (final subnet in subnets) {
      final remainingIps = <String>[];
      for (var i = 1; i <= 254; i++) {
        final ip = '$subnet.$i';
        if (!testedIps.contains(ip)) remainingIps.add(ip);
      }

      const chunkSize = 35;
      final totalChunks = (remainingIps.length / chunkSize).ceil();
      for (var c = 0; c < totalChunks; c++) {
        final start = c * chunkSize;
        final end = (start + chunkSize > remainingIps.length) ? remainingIps.length : start + chunkSize;
        final chunk = remainingIps.sublist(start, end);

        final scanProgress = 0.5 + (0.45 * (c / totalChunks));
        onProgress?.call('Đang dò dải Wi-Fi $subnet.x (${start + 1}-$end/254)...', scanProgress);

        final results = await Future.wait(
          chunk.map((ip) async {
            final ok = await PlatformServerDiscovery.pingTcp(ip, port, timeoutMs: 300);
            return ok ? ip : null;
          }),
        );

        for (final candidate in results) {
          if (candidate != null) {
            final targetUrl = 'http://$candidate:$port/api';
            if (await verifyHealthEndpoint(targetUrl, timeoutMs: 1500)) {
              onProgress?.call('Đã tìm thấy máy chủ tại $candidate:$port!', 1.0);
              return targetUrl;
            }
          }
        }
      }
    }

    onProgress?.call('Không tìm thấy máy chủ backend trong mạng Wi-Fi.', 1.0);
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
