import 'dart:async';
import 'dart:convert';
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

  /// Gửi gói tin UDP Broadcast tới mạng Wi-Fi để tìm backend server tức thì (~10-50ms)
  static Future<String?> probeUdpBroadcast({
    List<int> ports = const [5055, 5056, 5057, 5088],
    int timeoutMs = 800,
  }) async {
    RawDatagramSocket? socket;
    Timer? timer;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final completer = Completer<String?>();
      timer = Timer(Duration(milliseconds: timeoutMs), () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        socket?.close();
      });

      socket.listen(
        (event) {
          if (event == RawSocketEvent.read) {
            final dg = socket?.receive();
            if (dg != null) {
              try {
                final text = utf8.decode(dg.data);
                if (text.contains('smart_campus_backend')) {
                  timer?.cancel();
                  if (!completer.isCompleted) {
                    completer.complete(dg.address.address);
                  }
                  socket?.close();
                }
              } catch (_) {}
            }
          }
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(null);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(null);
        },
      );

      final msg = utf8.encode('SMART_CAMPUS_DISCOVERY');
      for (final p in ports) {
        socket.send(msg, InternetAddress('255.255.255.255'), p);
      }

      return await completer.future;
    } catch (_) {
      return null;
    } finally {
      timer?.cancel();
      try {
        socket?.close();
      } catch (_) {}
    }
  }
}
