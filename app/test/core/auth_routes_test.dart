import 'package:flutter_test/flutter_test.dart';

import 'package:catlive/core/router/auth_routes.dart';

void main() {
  group('loginLocation', () {
    test('ไม่ส่งอะไรเลยได้ /login เปล่า', () {
      expect(loginLocation(), '/login');
    });

    test('แนบ return เป็น query param และ encode ให้ถูกต้อง', () {
      expect(
        loginLocation(returnTo: '/treats?to=mali'),
        '/login?return=%2Ftreats%3Fto%3Dmali',
      );
      final parsed = Uri.parse(loginLocation(returnTo: '/treats?to=mali'));
      expect(parsed.path, '/login');
      expect(parsed.queryParameters['return'], '/treats?to=mali');
    });

    test('mode=register แนบมาด้วยเมื่อขอเปิดแท็บสมัคร', () {
      final parsed = Uri.parse(
        loginLocation(returnTo: '/my-cat', register: true),
      );
      expect(parsed.queryParameters['mode'], 'register');
      expect(parsed.queryParameters['return'], '/my-cat');
    });

    test('returnTo เป็นหน้าแรกไม่ต้องแนบ (ค่าเริ่มต้นอยู่แล้ว)', () {
      expect(loginLocation(returnTo: '/'), '/login');
    });
  });

  group('sanitizeAuthReturnTo', () {
    test('รับเฉพาะ path ภายในแอป', () {
      expect(sanitizeAuthReturnTo('/treats?to=mali'), '/treats?to=mali');
      expect(sanitizeAuthReturnTo('/my-cat'), '/my-cat');
    });

    test('ปฏิเสธค่าที่ไม่ใช่ path ภายใน (กัน open redirect)', () {
      expect(sanitizeAuthReturnTo('https://evil.com'), isNull);
      expect(sanitizeAuthReturnTo('//evil.com'), isNull);
      expect(sanitizeAuthReturnTo('treats'), isNull);
      expect(sanitizeAuthReturnTo(''), isNull);
      expect(sanitizeAuthReturnTo('   '), isNull);
      expect(sanitizeAuthReturnTo(null), isNull);
    });

    test('ปฏิเสธ /login กันวนลูปกลับเข้าหน้าล็อกอินเอง', () {
      expect(sanitizeAuthReturnTo('/login'), isNull);
      expect(sanitizeAuthReturnTo('/login?return=/treats'), isNull);
    });
  });
}
