import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const int port = 5000;

  // 1. CẮM DÂY MẶC ĐỊNH (USB ADB Reverse & Localhost)
  // Khi cắm dây USB (adb reverse tcp:5000 tcp:5000), máy thật Android truy cập trực tiếp qua 127.0.0.1
  static const String localhostBaseUrl = 'http://127.0.0.1:$port/api';
  // Khi chạy trên máy ảo Android Emulator
  static const String emulatorBaseUrl = 'http://10.0.2.2:$port/api';

  // Tương thích ngược:
  static const String lanBaseUrl = localhostBaseUrl;
  static const String lanHost = '127.0.0.1';

  // Mặc định toàn bộ logic là cắm dây (127.0.0.1:5000)
  static const String defaultCableBaseUrl = localhostBaseUrl;
  static const String defaultBaseUrl = defaultCableBaseUrl;
  static const String webBaseUrl = localhostBaseUrl;

  // URL tùy chỉnh / Tự động nhận diện khi dùng Wi-Fi
  static String? customBaseUrl;

  static String get activeBaseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }
    if (kIsWeb) {
      final host = (Uri.base.host.isNotEmpty && Uri.base.host != '0.0.0.0') ? Uri.base.host : 'localhost';
      return 'http://$host:$port/api';
    }
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return localhostBaseUrl;
    }
    // Mặc định thiết bị di động (Android / iOS): Ưu tiên cắm dây 127.0.0.1:5000
    return defaultCableBaseUrl;
  }

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String registerVerify = '/auth/register-verify';
  static const String verifyOtp = '/auth/verify-otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';

  // Student Endpoints
  static const String profile = '/student/profile';
  static const String updateProfile = '/student/profile';
  static const String schedule = '/student/schedule';
  static const String customSchedule = '/student/schedule/custom';
  static const String grades = '/student/grades';
  static const String sos = '/campus/sos';

  // Campus Endpoints
  static const String campusLocations = '/campus/locations';
  static const String campusPaths = '/campus/paths';
  static const String campusGates = '/campus/gates';
  static const String campusRoadRoute = '/campus/road-route';

  static const String campusDashboard = '/campus/dashboard';
  static const String feedback = '/campus/feedback';

  // General & News Endpoints
  static const String notifications = '/general/notifications';
  static const String news = '/news';
  static const String newsImageProxy = '/news/image-proxy';
  static const String newsArticleDetail = '/news/article-detail';
  static const String newsDownloadAttachment = '/news/download-attachment';
  static const String health = '/health';
}

