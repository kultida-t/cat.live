import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// จุดเริ่มแอป — ดัก error ทั้งฝั่ง Flutter และฝั่ง async ไม่ให้แอปปิดเอง
/// (ตอนมี crash reporting จริงให้ส่งรายงานที่นี่)
void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('[FlutterError] ${details.exceptionAsString()}');
    };
    ErrorWidget.builder = (details) => const _CrashFallback();

    runApp(const ProviderScope(child: CatLiveApp()));
  }, (error, stack) => debugPrint('[Uncaught] $error\n$stack'));
}

/// แสดงแทนวิดเจ็ตที่ build พัง — จอเดียวพังแล้วส่วนอื่นยังใช้ต่อได้
class _CrashFallback extends StatelessWidget {
  const _CrashFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('😿', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'ส่วนนี้มีปัญหา',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              'ลองกลับไปหน้าก่อนหน้าหรือเปิดแอปใหม่อีกครั้ง',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
