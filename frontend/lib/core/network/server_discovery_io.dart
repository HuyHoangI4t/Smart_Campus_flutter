import 'dart:async';
import 'dart:io';

class PlatformServerDiscovery {
  /// Lấy danh sách dải mạng con (subnets) cục bộ từ các network interface (IPv4)
  static Future<List<String>> getLocalSubnets() async {
    final subnets = <String>{};
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (!addr.isLoopback && ip.contains('.')) {
            final parts = ip.split('.');
            if (parts.length == 4) {
              subnets.add('${parts[0]}.${parts[1]}.${parts[2]}');
            }
          }
        }
      }
    } catch (_) {}
    return subnets.toList();
  }

  /// Thử kết nối TCP Socket siêu nhanh tới IP và Port cụ thể
  static Future<bool> pingTcp(String ip, int port, {int timeoutMs = 450}) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip, port, timeout: Duration(milliseconds: timeoutMs));
      return true;
    } catch (_) {
      return false;
    } finally {
      try {
        socket?.destroy();
      } catch (_) {}
    }
  }
}

