import 'dart:async';

/// Bộ làm mịn la bàn — lọc rung lắc marker bản đồ
/// - Ngưỡng thay đổi tối thiểu: [minDegreeChange] (mặc định 8°)
/// - Tần suất phát tối đa: [throttleMs] (mặc định 450ms)
class CompassSmoother {
  final double minDegreeChange;
  final int throttleMs;

  double _lastEmittedHeading = 0.0;
  DateTime _lastEmitTime = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _pendingTimer;
  double? _pendingHeading;

  final void Function(double heading) onSmoothedHeading;

  CompassSmoother({
    this.minDegreeChange = 8.0,
    this.throttleMs = 450,
    required this.onSmoothedHeading,
  });

  /// Nhận giá trị la bàn thô từ sensor
  void update(double rawHeading) {
    final diff = _angleDiff(rawHeading, _lastEmittedHeading);
    if (diff < minDegreeChange) {
      // Thay đổi quá nhỏ → bỏ qua hoàn toàn
      return;
    }

    final now = DateTime.now();
    final elapsed = now.difference(_lastEmitTime).inMilliseconds;

    if (elapsed >= throttleMs) {
      // Đã quá thời gian throttle → phát ngay
      _emit(rawHeading);
    } else {
      // Còn trong cửa sổ throttle → lưu pending, phát sau
      _pendingHeading = rawHeading;
      _pendingTimer?.cancel();
      _pendingTimer = Timer(
        Duration(milliseconds: throttleMs - elapsed),
        () {
          if (_pendingHeading != null) {
            _emit(_pendingHeading!);
            _pendingHeading = null;
          }
        },
      );
    }
  }

  void _emit(double heading) {
    _lastEmittedHeading = heading;
    _lastEmitTime = DateTime.now();
    onSmoothedHeading(heading);
  }

  /// Khoảng cách góc nhỏ nhất giữa 2 hướng (0–180)
  double _angleDiff(double a, double b) {
    double diff = (a - b).abs() % 360;
    if (diff > 180) diff = 360 - diff;
    return diff;
  }

  void dispose() {
    _pendingTimer?.cancel();
  }
}
