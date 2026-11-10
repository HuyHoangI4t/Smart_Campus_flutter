import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/otp_verify_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/feedback/screens/feedback_screen.dart';
import '../features/grades/screens/grades_detail_screen.dart';
import '../features/grades/screens/grades_screen.dart';
import '../features/home/models/news_model.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/news_detail_screen.dart';
import '../features/home/screens/news_screen.dart';
import '../features/map/screens/campus_map_screen.dart';
import '../features/profile/screens/app_settings_screen.dart';
import '../features/profile/screens/change_password_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/schedule/screens/schedule_screen.dart';
import '../features/sos/screens/sos_screen.dart';
import 'main_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Lớp notifier cầu nối giữa AuthProvider và GoRouter
/// Giúp lắng nghe trạng thái đăng nhập và kích hoạt redirect tự động
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isInitialized != next.isInitialized ||
          previous?.isAuthenticated != next.isAuthenticated) {
        notifyListeners();
      }
    });
  }

  AuthState get authState => _ref.read(authProvider);
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = notifier.authState;
      final isInitialized = authState.isInitialized;
      final isAuth = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isSplash = state.matchedLocation == '/splash';

      // 1. Khi đang khởi động / kiểm tra phiên đăng nhập:
      // Luôn giữ ở màn hình Splash / Loading, tuyệt đối không chớp sang Auth
      if (!isInitialized) {
        return isSplash ? null : '/splash';
      }

      // 2. Đã kiểm tra xong nhưng CHƯA đăng nhập:
      if (!isAuth) {
        // Đang ở Splash hoặc các route trong app cần xác thực -> Chuyển về màn hình Đăng nhập
        if (isSplash || !isAuthRoute) {
          return '/auth/login';
        }
        // Đang ở các màn Auth (đăng nhập, đăng ký, OTP, quên mật khẩu) -> Cho phép tiếp tục
        return null;
      }

      // 3. Đã đăng nhập hợp lệ (có token hoặc khách):
      // Nếu đang ở Splash hoặc bất kỳ màn Auth nào -> Chuyển thẳng vào Home, không hiển thị Auth
      if (isSplash || isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Màn hình Splash / Loading ban đầu
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/login',
        redirect: (context, state) => '/auth/login',
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/verify-otp',
        builder: (context, state) {
          final studentId = state.uri.queryParameters['studentId'] ?? '';
          return OtpVerifyScreen(studentId: studentId);
        },
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // App Stateful Shell (Bottom Navigation Bar)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // 0. Trang chủ
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // 1. Thời khóa biểu
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/schedule',
                builder: (context, state) => const ScheduleScreen(),
              ),
            ],
          ),
          // 2. Bản đồ số
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) {
                  final building = state.uri.queryParameters['building'];
                  final room = state.uri.queryParameters['room'];
                  return CampusMapScreen(
                    initialBuildingCode: building,
                    initialRoomName: room,
                  );
                },
              ),
            ],
          ),
          // 3. Kết quả học tập
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/grades',
                builder: (context, state) => const GradesScreen(),
              ),
            ],
          ),
          // 4. Hồ sơ
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Sub-screens & Modals
      GoRoute(
        path: '/sos',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SosScreen(),
      ),
      GoRoute(
        path: '/feedback',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: '/profile/change-password',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/profile/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AppSettingsScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AppSettingsScreen(),
      ),
      GoRoute(
        path: '/grades/detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GradesDetailScreen(),
      ),
      GoRoute(
        path: '/home/news',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'] ?? state.uri.queryParameters['category'];
          return NewsScreen(initialCategory: tab);
        },
      ),
      GoRoute(
        path: '/home/news/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? state.uri.queryParameters['id'] ?? '1';
          final article = state.extra is NewsModel ? state.extra as NewsModel : null;
          return NewsDetailScreen(id: id, initialArticle: article);
        },
      ),
      GoRoute(
        path: '/home/news/detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '1';
          final article = state.extra is NewsModel ? state.extra as NewsModel : null;
          return NewsDetailScreen(id: id, initialArticle: article);
        },
      ),
    ],
  );
});

