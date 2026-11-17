import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:catlive/features/auth/data/datasources/secure_auth_token_storage.dart';
import 'package:catlive/features/auth/domain/entities/auth_data.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecureStorage storage;
  late SecureAuthTokenStorage sut;

  final expiry = DateTime(2026, 12, 1, 10, 30);
  const session = AuthSession(
    mode: AuthMode.authenticated,
    user: AuthUser(
      id: 'user-lookkaew',
      displayName: 'จุฑามาศ ลูกแก้ว',
      method: AuthMethod.google,
      phoneMasked: '081-xxx-4567',
      email: 'lookkaew@gmail.com',
      birthYear: 1995,
      guardianConsentGranted: true,
    ),
    accessToken: 'access-abc',
    refreshToken: 'refresh-def',
  );

  setUp(() {
    storage = _MockSecureStorage();
    sut = SecureAuthTokenStorage(storage: storage);
  });

  test('บันทึกแล้วอ่านกลับได้ session เดิม (round-trip)', () async {
    String? written;
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((invocation) async {
      written = invocation.namedArguments[#value] as String;
    });
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((_) async => written);

    await sut.saveSession(
      AuthSession(
        mode: session.mode,
        user: session.user,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        expiresAt: expiry,
      ),
    );

    final restored = await sut.readSession();
    expect(
      restored,
      AuthSession(
        mode: AuthMode.authenticated,
        user: session.user,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        expiresAt: expiry,
      ),
    );
  });

  test('อ่าน access token จาก session ที่บันทึกไว้', () async {
    String? written;
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((invocation) async {
      written = invocation.namedArguments[#value] as String;
    });
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((_) async => written);

    await sut.saveSession(session);
    expect(await sut.readAccessToken(), 'access-abc');
  });

  test('session guest บันทึกแล้วอ่านกลับเป็น guest (ไม่มี token)', () async {
    String? written;
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((invocation) async {
      written = invocation.namedArguments[#value] as String;
    });
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((_) async => written);

    await sut.saveSession(const AuthSession.guest());
    final restored = await sut.readSession();
    expect(restored, const AuthSession.guest());
    expect(await sut.readAccessToken(), isNull);
  });

  test('ไม่เคยบันทึก → อ่านได้ null', () async {
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    expect(await sut.readSession(), isNull);
  });

  test('ข้อมูลใน storage เสียหาย → อ่านได้ null แทนที่จะพัง', () async {
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((_) async => '{broken-json!!!');
    expect(await sut.readSession(), isNull);
  });

  test('clearSession ลบคีย์ออกจาก storage', () async {
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    await sut.clearSession();
    verify(() => storage.delete(key: 'catlive.auth.session.v1')).called(1);
  });
}
