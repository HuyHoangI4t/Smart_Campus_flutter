import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isInitialized;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
  });

  bool get isAuthenticated => user != null;
  bool get isGuest => user?.isGuest ?? false;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isInitialized,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  Dio get _dio => ref.read(dioProvider);

  @override
  AuthState build() {
    Future.microtask(() => checkAuthSession());
    return const AuthState(isLoading: true, isInitialized: false);
  }

  Future<void> checkAuthSession() async {
    final stopwatch = Stopwatch()..start();
    try {
      final storage = ref.read(storageServiceProvider);
      final isGuest = await storage.isGuestMode();

      if (isGuest) {
        UserModel guestUser = UserModel.guest();
        final userJson = await storage.getUserData();
        if (userJson != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(userJson);
            guestUser = UserModel.fromJson(data);
          } catch (_) {}
        }
        final elapsed = stopwatch.elapsedMilliseconds;
        if (elapsed < 900) {
          await Future.delayed(Duration(milliseconds: 900 - elapsed));
        }
        state = AuthState(user: guestUser, isLoading: false, isInitialized: true);
        return;
      }

      final token = await storage.getToken();
      final userJson = await storage.getUserData();

      if (token != null && userJson != null) {
        try {
          final Map<String, dynamic> data = jsonDecode(userJson);
          final user = UserModel.fromJson(data);
          final elapsed = stopwatch.elapsedMilliseconds;
          if (elapsed < 900) {
            await Future.delayed(Duration(milliseconds: 900 - elapsed));
          }
          state = AuthState(user: user, isLoading: false, isInitialized: true);
          return;
        } catch (_) {}
      }

      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < 900) {
        await Future.delayed(Duration(milliseconds: 900 - elapsed));
      }
      state = const AuthState(user: null, isLoading: false, isInitialized: true);
    } catch (e) {
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < 900) {
        await Future.delayed(Duration(milliseconds: 900 - elapsed));
      }
      state = const AuthState(user: null, isLoading: false, isInitialized: true);
    }
  }

  Future<bool> login(String studentId, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'mssv': studentId.trim(),
          'student_id': studentId.trim(),
          'password': password,
          'mat_khau': password,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['token'];
        final userData = response.data['user'];

        final user = UserModel.fromJson(userData);
        final storage = ref.read(storageServiceProvider);

        await storage.saveToken(token);
        await storage.saveUserData(jsonEncode(userData));
        await storage.setGuestMode(false);

        state = AuthState(user: user, isLoading: false, isInitialized: true);
        return true;
      } else {
        final msg = response.data['message'] ?? 'Đăng nhập không thành công';
        state = state.copyWith(isLoading: false, isInitialized: true, error: msg);
        return false;
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Lỗi kết nối máy chủ';
      state = state.copyWith(isLoading: false, isInitialized: true, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, isInitialized: true, error: e.toString());
      return false;
    }
  }

  Future<void> enterGuestMode() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setGuestMode(true);
    state = AuthState(user: UserModel.guest(), isLoading: false, isInitialized: true);
  }

  Future<bool> register({
    required String studentId,
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'mssv': studentId.trim(),
          'student_id': studentId.trim(),
          'fullName': fullName.trim(),
          'full_name': fullName.trim(),
          'ho_ten': fullName.trim(),
          'email': email.trim(),
          'password': password,
          'mat_khau': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(isLoading: false);
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        error: response.data['message'] ?? 'Đăng ký thất bại',
      );
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Lỗi kết nối máy chủ',
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String studentId, String otp) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final payload = {
        'mssv': studentId.trim(),
        'student_id': studentId.trim(),
        'otp': otp.trim(),
        'otpCode': otp.trim(),
      };

      // Thử endpoint registerVerify trước, nếu không thành công gọi verifyOtp
      Response response;
      try {
        response = await _dio.post(ApiEndpoints.registerVerify, data: payload);
      } catch (_) {
        response = await _dio.post(ApiEndpoints.verifyOtp, data: payload);
      }

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.data?['success'] == true ||
          (response.data?['message']?.toString().toLowerCase().contains('thành công') ?? false)) {
        state = state.copyWith(isLoading: false, error: null);
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        error: response.data?['message'] ?? 'Mã OTP không hợp lệ',
      );
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? '';
      if (msg.toLowerCase().contains('thành công')) {
        state = state.copyWith(isLoading: false, error: null);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: msg.isNotEmpty ? msg : 'Lỗi xác thực OTP',
      );
      return false;
    }
  }

  Future<void> logout() async {
    final storage = ref.read(storageServiceProvider);
    await storage.clearAll();
    state = const AuthState(user: null, isLoading: false, isInitialized: true);
  }

  Future<bool> updateUser(UserModel updatedUser) async {
    final storage = ref.read(storageServiceProvider);
    bool apiSuccess = false;

    // Chỉ gọi API backend nếu không phải khách tham quan và có studentId hợp lệ
    if (!updatedUser.isGuest && updatedUser.studentId.isNotEmpty && updatedUser.studentId != 'GUEST') {
      try {
        final res = await _dio.put(
          ApiEndpoints.updateProfile,
          data: {
            'mssv': updatedUser.studentId,
            'student_id': updatedUser.studentId,
            'fullName': updatedUser.fullName,
            'ho_ten': updatedUser.fullName,
            'email': updatedUser.email,
            'phone': updatedUser.phone,
            'so_dien_thoai': updatedUser.phone,
            'lop': updatedUser.studentClass,
            'khoa': updatedUser.faculty,
            'avatar': updatedUser.avatarUrl,
            'avatar_url': updatedUser.avatarUrl,
            'avatarUrl': updatedUser.avatarUrl,
          },
        );
        if (res.statusCode == 200) {
          apiSuccess = true;
        }
      } catch (_) {}
    } else {
      apiSuccess = true;
    }

    // Luôn lưu vào local storage để trải nghiệm người dùng tức thì & offline
    await storage.saveUserData(jsonEncode(updatedUser.toJson()));
    state = state.copyWith(user: updatedUser);
    return apiSuccess;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

