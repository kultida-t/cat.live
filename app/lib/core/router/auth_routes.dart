import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// สร้าง path `/login` พร้อมจำปลายทางหลังล็อกอินสำเร็จ (AUTH-02)
/// - `returnTo` = ปลายทางที่ผู้ใช้ตั้งใจจะไป (เช่น หน้าที่กดไว้ก่อนเจอ guest gate
///   หรือหน้าปลายทางของ action นั้น) — ส่งเฉพาะ path ภายในแอปเท่านั้น
/// - `register` = เปิดแท็บสมัครสมาชิกแทนแท็บเข้าสู่ระบบ (ใช้จากชีตชวนสมัครของ Guest)
String loginLocation({String? returnTo, bool register = false}) {
  final params = <String, String>{};
  final safe = sanitizeAuthReturnTo(returnTo);
  if (safe != null && safe != '/') params['return'] = safe;
  if (register) params['mode'] = 'register';
  if (params.isEmpty) return '/login';
  return Uri(path: '/login', queryParameters: params).toString();
}

/// คืน path ปลายทางที่ปลอดภัย — เฉพาะ path ภายในแอปที่ขึ้นต้น `/`
/// กัน open redirect (`//host`), path ว่าง และการวนกลับเข้า `/login` ซ้ำ
String? sanitizeAuthReturnTo(String? returnTo) {
  if (returnTo == null) return null;
  final trimmed = returnTo.trim();
  if (trimmed.isEmpty) return null;
  if (!trimmed.startsWith('/') || trimmed.startsWith('//')) return null;
  final path = Uri.tryParse(trimmed)?.path ?? '';
  if (path == '/login' || path.startsWith('/login/')) return null;
  return trimmed;
}

/// path ของหน้าที่กำลังแสดงอยู่ — ใช้ได้ทั้งจากบนหน้าเพจและจากชีตที่ลอยอยู่ข้างบน
/// (อ่านจาก routerDelegate ตรง ๆ เพราะ modal bottom sheet ไม่มี GoRouterState ของตัวเอง)
String currentAppLocation(BuildContext context) {
  try {
    final uri = GoRouter.of(context).routerDelegate.currentConfiguration.uri;
    return uri.toString();
  } catch (_) {
    return '/';
  }
}
