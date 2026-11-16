import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ระดับขนาดตัวอักษรของแอป (SET-01: เปลี่ยนขนาดตัวอักษรแล้วมีผลทันที)
enum AppTextSizePreset {
  small(0.9),
  normal(1.0),
  large(1.15);

  const AppTextSizePreset(this.factor);
  final double factor;
}

/// จัดการขนาดตัวอักษร UI ปัจจุบันทั้งแอป
class AppTextScaleNotifier extends Notifier<AppTextSizePreset> {
  @override
  AppTextSizePreset build() => AppTextSizePreset.normal;

  void setPreset(AppTextSizePreset preset) {
    if (state != preset) state = preset;
  }
}

final appTextScaleProvider =
    NotifierProvider<AppTextScaleNotifier, AppTextSizePreset>(
      AppTextScaleNotifier.new,
    );
