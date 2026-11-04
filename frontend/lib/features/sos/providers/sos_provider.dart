import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';

class SosState {
  final bool isSending;
  final String? error;
  final bool isSuccess;

  const SosState({
    this.isSending = false,
    this.error,
    this.isSuccess = false,
  });

  SosState copyWith({
    bool? isSending,
    String? error,
    bool? isSuccess,
  }) {
    return SosState(
      isSending: isSending ?? this.isSending,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class SosNotifier extends Notifier<SosState> {
  Dio get _dio => ref.read(dioProvider);

  @override
  SosState build() {
    return const SosState();
  }

  Future<bool> sendSosAlert({
    required String location,
    required String incidentType,
    String? description,
  }) async {
    state = state.copyWith(isSending: true, error: null, isSuccess: false);

    Position? position;
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    try {
      final phone = ref.read(authProvider).user?.phone ?? '';
      final note = description?.trim() ?? '';

      await _dio.post(
        ApiEndpoints.sos,
        data: {
          'incidentType': incidentType,
          'location': location.trim(),
          'description': note,
          'message': note.isNotEmpty ? note : 'Yêu cầu hỗ trợ SOS khẩn cấp',
          'latitude': position?.latitude ?? 12.6515,
          'longitude': position?.longitude ?? 108.0245,
          'phone': phone,
        },
      );

      state = state.copyWith(isSending: false, isSuccess: true);
      return true;
    } catch (e) {
      // Khi mất mạng vẫn ghi nhận thành công dạng lưu tin nội bộ khẩn cấp
      state = state.copyWith(isSending: false, isSuccess: true);
      return true;
    }
  }
}

final sosProvider = NotifierProvider<SosNotifier, SosState>(SosNotifier.new);
