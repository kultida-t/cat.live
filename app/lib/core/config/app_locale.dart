import 'package:flutter_riverpod/flutter_riverpod.dart';

/// จัดการภาษา UI ปัจจุบันของแอป ('th' หรือ 'en') เพื่อให้แถบเมนูล่างและหน้าย่อยเปลี่ยนภาษาพร้อมกัน
class AppLocaleNotifier extends Notifier<String> {
  @override
  String build() => 'th';

  void setLocale(String locale) {
    final normalized = locale == 'en' ? 'en' : 'th';
    if (state != normalized) state = normalized;
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, String>(
  AppLocaleNotifier.new,
);
