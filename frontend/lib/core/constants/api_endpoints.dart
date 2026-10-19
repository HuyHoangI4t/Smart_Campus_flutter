class ApiEndpoints {
  ApiEndpoints._();

  // IP máy tính chủ trên mạng Wi-Fi (IPv4: 10.27.250.83)
  static const String lanHost = '10.27.250.83';
  static const int port = 5000;

  // URL cho máy thật (Wi-Fi), máy thật (USB adb reverse), giả lập, web
  static const String lanBaseUrl = 'http://$lanHost:$port/api';
  static const String localhostBaseUrl = 'http://127.0.0.1:$port/api';
  static const String emulatorBaseUrl = 'http://10.0.2.2:$port/api';

  // Mặc định kết nối trực tiếp đến IP máy tính qua Wi-Fi
  static const String defaultBaseUrl = lanBaseUrl;
  static const String webBaseUrl = localhostBaseUrl;

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
  static const String sos = '/student/sos';

  // Campus Endpoints
  static const String campusLocations = '/campus/locations';
  static const String campusPaths = '/campus/paths';
  static const String campusGates = '/campus/gates';

  // General & News Endpoints
  static const String feedback = '/general/feedback';
  static const String news = '/news/all';
  static const String health = '/health';
}

