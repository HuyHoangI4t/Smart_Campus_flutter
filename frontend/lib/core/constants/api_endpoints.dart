import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // IP máy tính chủ trên mạng Wi-Fi (IPv4: 192.168.1.14)
  static const String lanHost = '192.168.1.14';
  static const int port = 5000;

  // URL cho máy thật (Wi-Fi), máy thật (USB adb reverse), giả lập, web
  static const String lanBaseUrl = 'http://$lanHost:$port/api';
  static const String localhostBaseUrl = 'http://127.0.0.1:$port/api';
  static const String emulatorBaseUrl = 'http://10.0.2.2:$port/api';

  // Mặc định kết nối trực tiếp đến IP máy tính qua Wi-Fi
  static const String defaultBaseUrl = lanBaseUrl;
  static const String webBaseUrl = localhostBaseUrl;

  static String get activeBaseUrl {
    if (kIsWeb) {
      final host = (Uri.base.host.isNotEmpty && Uri.base.host != '0.0.0.0') ? Uri.base.host : 'localhost';
      return 'http://$host:$port/api';
    }
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return localhostBaseUrl;
    }
    return defaultBaseUrl;
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

