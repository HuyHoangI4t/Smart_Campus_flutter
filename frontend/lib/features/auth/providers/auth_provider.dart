import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;
  bool get isGuest => user?.isGuest ?? false;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  Dio get _dio => ref.read(dioProvider);

  @override
  AuthState build() {
    Future.microtask(() => checkAuthSession());
    return const AuthState(isLoading: true);
  }

  Future<void> checkAuthSession() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final isGuest = await storage.isGuestMode();

      if (isGuest) {
        state = AuthState(user: UserModel.guest(), isLoading: false);
        return;
      }

      final token = await storage.getToken();
      final userJson = await storage.getUserData();

      if (token != null && userJson != null) {
        try {
          final Map<String, dynamic> data = jsonDecode(userJson);
          state = AuthState(user: UserModel.fromJson(data), isLoading: false);
          return;
        } catch (_) {}
      }

      state = const AuthState(user: null, isLoading: false);
    } catch (e) {
      state = const AuthState(user: null, isLoading: false);
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

        state = AuthState(user: user, isLoading: false);
        return true;
      } else {
        final msg = response.data['message'] ?? 'Đăng nhập không thành công';
        state = state.copyWith(isLoading: false, error: msg);
        return false;
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Lỗi kết nối máy chủ';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> enterGuestMode() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setGuestMode(true);
    state = AuthState(user: UserModel.guest(), isLoading: false);
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
    state = const AuthState(user: null, isLoading: false);
  }

  Future<void> updateUser(UserModel updatedUser) async {
    final storage = ref.read(storageServiceProvider);
    try {
      await _dio.put(
        ApiEndpoints.updateProfile,
        data: {
          'mssv': updatedUser.studentId,
          'fullName': updatedUser.fullName,
          'ho_ten': updatedUser.fullName,
          'email': updatedUser.email,
          'phone': updatedUser.phone,
          'so_dien_thoai': updatedUser.phone,
          'lop': updatedUser.studentClass,
          'khoa': updatedUser.faculty,
          'avatar': updatedUser.avatarUrl,
        },
      );
    } catch (_) {}
    await storage.saveUserData(jsonEncode(updatedUser.toJson()));
    state = state.copyWith(user: updatedUser);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

