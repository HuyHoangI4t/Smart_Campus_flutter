import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/otp_verify_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/feedback/screens/feedback_screen.dart';
import '../features/grades/screens/grades_detail_screen.dart';
import '../features/grades/screens/grades_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/news_detail_screen.dart';
import '../features/map/screens/campus_map_screen.dart';
import '../features/profile/screens/change_password_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/schedule/screens/schedule_screen.dart';
import '../features/sos/screens/sos_screen.dart';
import 'main_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      // Cho phép truy cập nếu đã xác thực hoặc đang ở các màn auth
      if (!isAuth && !isAuthRoute) {
        return '/auth/login';
      }
      if (isAuth && isAuthRoute) {
        return '/home';
      }
      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
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
                  return CampusMapScreen(initialBuildingCode: building);
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
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SosScreen(),
      ),
      GoRoute(
        path: '/feedback',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: '/profile/change-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/grades/detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GradesDetailScreen(),
      ),
      GoRoute(
        path: '/home/news/detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final idStr = state.uri.queryParameters['id'] ?? '1';
          return NewsDetailScreen(id: int.tryParse(idStr) ?? 1);
        },
      ),
    ],
  );
});

