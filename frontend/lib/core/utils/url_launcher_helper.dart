import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/router.dart';
import '../constants/app_colors.dart';

class AppUrlLauncher {
  AppUrlLauncher._();

  /// Mở phòng học Google Meet tương tự cơ chế Linking chuyên sâu trong React Native:
  /// 1. Ưu tiên mở trực tiếp ứng dụng Google Meet hoặc trình duyệt mặc định ngoài app
  /// 2. Hỗ trợ fallback mở qua platformDefault và inAppBrowserView
  /// 3. Nếu không mở được, tự động sao chép mã phòng vào Clipboard và thông báo cho người dùng
  static Future<bool> openGoogleMeet({
    String? url,
    String? code,
  }) async {
    final cleanCode = (code ?? '').trim();
    String targetUrl = (url ?? '').trim();

    if (targetUrl.isEmpty && cleanCode.isNotEmpty) {
      targetUrl = 'https://meet.google.com/$cleanCode';
    }

    if (targetUrl.isEmpty) {
      _showFeedback(
        'Không tìm thấy liên kết hoặc mã phòng học Google Meet.',
        isError: true,
      );
      return false;
    }

    if (!targetUrl.startsWith('http://') && !targetUrl.startsWith('https://')) {
      targetUrl = 'https://$targetUrl';
    }

    final uri = Uri.tryParse(targetUrl);
    if (uri == null) {
      _showFeedback('Liên kết phòng học không hợp lệ: $targetUrl', isError: true);
      return false;
    }

    bool success = false;

    // Chiến lược 1: Thử mở ứng dụng ngoài (External Application - ưu tiên mở App Google Meet)
    try {
      success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('LaunchMode.externalApplication failed: $e');
    }

    // Chiến lược 2: Thử mở bằng Platform Default
    if (!success) {
      try {
        success = await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        debugPrint('LaunchMode.platformDefault failed: $e');
      }
    }

    // Chiến lược 3: Trên Android, thử mở trực tiếp qua Intent package Google Meet (tương tự React Native Linking intent)
    if (!success && !kIsWeb) {
      try {
        if (Platform.isAndroid && cleanCode.isNotEmpty) {
          final intentUri = Uri.parse(
            'intent://meet.google.com/$cleanCode#Intent;scheme=https;package=com.google.android.apps.meetings;end',
          );
          success = await launchUrl(intentUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('Android Intent launch failed: $e');
      }
    }

    // Chiến lược 4: Fallback mở qua In-App Browser View
    if (!success) {
      try {
        success = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (e) {
        debugPrint('LaunchMode.inAppBrowserView failed: $e');
      }
    }

    // Nếu mở thành công
    if (success) {
      return true;
    }

    // Nếu tất cả các chiến lược mở app/link đều thất bại trên thiết bị:
    // Tự động sao chép mã phòng vào Clipboard để sinh viên dán vào Google Meet thủ công
    final copyText = cleanCode.isNotEmpty ? cleanCode : targetUrl;
    await Clipboard.setData(ClipboardData(text: copyText));
    HapticFeedback.mediumImpact();

    _showFeedback(
      cleanCode.isNotEmpty
          ? 'Không thể mở trực tiếp app Google Meet. Đã sao chép mã phòng "$cleanCode" vào bộ nhớ tạm!'
          : 'Không thể mở liên kết phòng học. Đã sao chép liên kết vào bộ nhớ tạm!',
      isError: false,
    );

    return false;
  }

  /// Mở ứng dụng Google Maps chính thức để dẫn đường ngoài phố
  /// Hỗ trợ cả toạ độ xuất phát (vị trí GPS thực tế) và toạ độ đích đến (công trình hoặc cổng trường)
  static Future<bool> openGoogleMapsDirections({
    LatLng? origin,
    required LatLng destination,
    String? destinationTitle,
    String mode = 'walking',
  }) async {
    final destLat = destination.latitude;
    final destLng = destination.longitude;

    final String url = origin != null
        ? 'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}&destination=$destLat,$destLng&travelmode=$mode'
        : 'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=$mode';

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    // 1. Thử mở native navigation/geo intent trên Android/iOS
    if (!kIsWeb) {
      try {
        final nativeUri = Uri.parse(
          origin != null
              ? 'google.navigation:q=$destLat,$destLng&mode=${mode == "walking" ? "w" : "d"}'
              : 'geo:$destLat,$destLng?q=$destLat,$destLng(${Uri.encodeComponent(destinationTitle ?? "Địa điểm")})',
        );
        if (await canLaunchUrl(nativeUri)) {
          final launched = await launchUrl(nativeUri, mode: LaunchMode.externalNonBrowserApplication);
          if (launched) return true;
        }
      } catch (_) {}
    }

    // 2. Mở qua Universal URL (mở App Google Maps hoặc Trình duyệt)
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) return true;
    } catch (_) {}

    // 3. Fallback qua platformDefault
    try {
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      _showFeedback('Không thể mở Google Maps trên thiết bị.', isError: true);
      return false;
    }
  }

  /// Mở liên kết web bất kỳ với cơ chế fallback an toàn
  static Future<bool> openWebUrl(String rawUrl, {LaunchMode mode = LaunchMode.externalApplication}) async {
    final cleanUrl = rawUrl.trim();
    if (cleanUrl.isEmpty) return false;

    final targetUrl = (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://'))
        ? 'https://$cleanUrl'
        : cleanUrl;

    final uri = Uri.tryParse(targetUrl);
    if (uri == null) return false;

    try {
      final launched = await launchUrl(uri, mode: mode);
      if (launched) return true;
    } catch (_) {}

    try {
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {}

    return false;
  }

  /// Gọi điện thoại khẩn cấp (dùng cho màn hình SOS)
  static Future<bool> makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  static void _showFeedback(String message, {bool isError = false}) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
