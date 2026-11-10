import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_endpoints.dart';
import 'notification_service.dart';

class SocketService {
  SocketService._() {
    deviceId = 'client_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000000)}';
  }
  static final SocketService instance = SocketService._();

  late final String deviceId;
  final Set<String> _selfSentSosIds = <String>{};
  io.Socket? _socket;
  final Map<String, Set<void Function(dynamic)>> _listeners = {};

  bool get isConnected => _socket?.connected ?? false;

  void markSosAsSelfSent(dynamic sosId) {
    if (sosId != null) {
      _selfSentSosIds.add(sosId.toString());
    }
  }

  bool isSelfSentSos(dynamic alertData) {
    if (alertData == null || alertData is! Map) return false;
    final map = alertData;
    final idStr = map['id']?.toString() ?? '';
    if (idStr.isNotEmpty && _selfSentSosIds.contains(idStr)) {
      return true;
    }
    final incomingClientId = map['client_id']?.toString() ?? '';
    if (incomingClientId.isNotEmpty && incomingClientId == deviceId) {
      return true;
    }
    return false;
  }

  String getSocketUrl([String? baseUrl]) {
    final raw = baseUrl ?? ApiEndpoints.activeBaseUrl;
    return raw.replaceAll(RegExp(r'/api/?$'), '');
  }

  void updateServerUrl(String newBaseUrl) {
    final targetUrl = getSocketUrl(newBaseUrl);
    if (_socket != null) {
      try {
        _socket!.disconnect();
        _socket!.dispose();
      } catch (_) {}
      _socket = null;
    }
    initSocket(serverUrl: targetUrl);
  }

  void initSocket({String? serverUrl}) {
    if (_socket != null && _socket!.connected) return;

    final targetUrl = getSocketUrl(serverUrl);
    try {
      _socket?.dispose();
      _socket = io.io(
        targetUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setTimeout(20000)
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('⚡ [Socket.IO] Đã kết nối thành công tới: $targetUrl');
      });

      _socket!.onDisconnect((reason) {
        debugPrint('⚠️ [Socket.IO] Mất kết nối ($reason)');
      });

      _socket!.onConnectError((err) {
        // Chỉ ghi nhận vắn tắt để tránh tràn log khi chưa hoàn tất nhận diện máy chủ
        final msg = err.toString();
        if (msg.contains('Connection refused')) {
          debugPrint('⏳ [Socket.IO] Đang chờ kết nối tới máy chủ ($targetUrl)...');
        } else {
          debugPrint('❌ [Socket.IO] Lỗi kết nối: $err');
        }
      });

      // Lắng nghe sự kiện new_sos toàn cục
      _socket!.on('new_sos', (data) {
        _handleIncomingSos(data);
        _dispatch('new_sos', data);
      });

      // Đăng ký các sự kiện chung
      for (final ev in [
        'sos_status_changed',
        'sos_deleted',
        'feedback_status_changed',
        'notifications_changed',
        'notification_created',
        'notification_updated',
        'notification_deleted',
      ]) {
        _socket!.on(ev, (data) => _dispatch(ev, data));
      }

      _socket!.connect();
    } catch (e) {
      debugPrint('Lỗi khởi tạo Socket.IO: $e');
    }
  }

  void _handleIncomingSos(dynamic data) {
    try {
      if (data == null || data is! Map) return;
      if (isSelfSentSos(data)) {
        debugPrint('🛡️ [Socket] Bỏ qua thông báo SOS do chính thiết bị này gửi đi.');
        return;
      }

      final loc = data['location']?.toString() ?? 'Khuôn viên trường';
      final type = data['incidentType']?.toString() ?? 'Khẩn cấp';
      final title = '🚨 CẢNH BÁO SOS: $type';
      final body = 'Vị trí: $loc. Nhấn để xem và hỗ trợ kịp thời.';

      NotificationService.instance.showSosAlertNotification(
        title: title,
        body: body,
        payload: 'sos_alert_${data['id']}',
      );
    } catch (e) {
      debugPrint('Lỗi xử lý SOS realtime: $e');
    }
  }

  void _dispatch(String event, dynamic data) {
    final cbs = _listeners[event];
    if (cbs != null) {
      for (final cb in cbs) {
        try {
          cb(data);
        } catch (e) {
          debugPrint('Lỗi callback socket event [$event]: $e');
        }
      }
    }
  }

  VoidCallback on(String event, void Function(dynamic) callback) {
    _listeners.putIfAbsent(event, () => <void Function(dynamic)>{});
    _listeners[event]!.add(callback);
    return () {
      _listeners[event]?.remove(callback);
    };
  }

  VoidCallback onNewSos(void Function(dynamic) callback) => on('new_sos', callback);
  VoidCallback onSosStatusChanged(void Function(dynamic) callback) => on('sos_status_changed', callback);

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _listeners.clear();
  }
}
