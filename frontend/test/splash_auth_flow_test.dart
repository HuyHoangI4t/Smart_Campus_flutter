import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus/app/router.dart';
import 'package:smart_campus/features/auth/models/user_model.dart';
import 'package:smart_campus/features/auth/providers/auth_provider.dart';
import 'package:smart_campus/features/auth/screens/login_screen.dart';
import 'package:smart_campus/features/auth/screens/splash_screen.dart';
import 'package:smart_campus/features/home/screens/home_screen.dart';

class MockUninitializedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return const AuthState(isLoading: true, isInitialized: false);
  }
}

class MockUnauthenticatedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return const AuthState(user: null, isLoading: false, isInitialized: true);
  }
}

class MockAuthenticatedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return AuthState(
      user: UserModel(
        id: 1,
        studentId: '23103023',
        fullName: 'Nguyễn Văn A',
        email: '23103023@sv.ttn.edu.vn',
        role: 'sinh_vien',
      ),
      isLoading: false,
      isInitialized: true,
    );
  }
}

void main() {
  testWidgets('App displays SplashScreen while initializing (isInitialized = false)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => MockUninitializedAuthNotifier()),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(routerProvider);
            return MaterialApp.router(
              routerConfig: router,
            );
          },
        ),
      ),
    );

    await tester.pump();

    // Verify SplashScreen is displayed
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Smart Campus'), findsOneWidget);
    expect(find.text('TRƯỜNG ĐẠI HỌC TÂY NGUYÊN'), findsOneWidget);
    expect(find.text('Đang kiểm tra phiên đăng nhập...'), findsOneWidget);

    // Verify LoginScreen is NOT shown during loading
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('When unauthenticated, user is redirected to LoginScreen after check',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => MockUnauthenticatedAuthNotifier()),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(routerProvider);
            return MaterialApp.router(
              routerConfig: router,
            );
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify LoginScreen is shown
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Đăng Nhập Vào Campus'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('When authenticated, user goes straight to HomeScreen without seeing Auth',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => MockAuthenticatedAuthNotifier()),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(routerProvider);
            return MaterialApp.router(
              routerConfig: router,
            );
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify HomeScreen is shown
    expect(find.byType(HomeScreen), findsOneWidget);
    // Verify LoginScreen is NEVER shown
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(SplashScreen), findsNothing);
  });
}
