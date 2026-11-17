import 'package:catlive/features/auth/data/datasources/auth_pin_storage.dart';
import 'package:catlive/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:catlive/features/auth/data/datasources/auth_token_storage.dart';
import 'package:catlive/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:catlive/features/auth/domain/entities/auth_data.dart';
import 'package:catlive/features/auth/domain/entities/pin_account_record.dart';
import 'package:catlive/features/auth/domain/repositories/auth_repository.dart';
import 'package:catlive/features/auth/domain/usecases/pin_rules.dart';
import 'package:flutter_test/flutter_test.dart';

AuthRepositoryImpl _repo({
  InMemoryAuthTokenStorage? tokenStorage,
  InMemoryAuthPinStorage? pinStorage,
}) {
  return AuthRepositoryImpl(
    remoteDataSource: MockAuthRemoteDataSource(latency: Duration.zero),
    tokenStorage: tokenStorage ?? InMemoryAuthTokenStorage(),
    pinStorage: pinStorage ?? InMemoryAuthPinStorage(),
  );
}

const _phoneUser = AuthUser(
  id: 'user-newbie',
  displayName: 'สมชาย ทดสอบ',
  method: AuthMethod.phoneOtp,
  phone: '0899998888',
  phoneMasked: '089-xxx-8888',
  birthYear: 1990,
);

void main() {
  group('PinRules', () {
    test('รับเฉพาะตัวเลข 6 หลักพอดี', () {
      expect(PinRules.isValidPin('123456'), isTrue);
      expect(PinRules.isValidPin(''), isFalse);
      expect(PinRules.isValidPin('12345'), isFalse);
      expect(PinRules.isValidPin('1234567'), isFalse);
      expect(PinRules.isValidPin('abcdef'), isFalse);
      expect(PinRules.isValidPin('12 456'), isFalse);
    });

    test('hash เดิมต้องตรงกัน และ salt ต่างกันให้ hash ต่างกัน', () {
      final salt1 = PinRules.generateSalt();
      final salt2 = PinRules.generateSalt();
      expect(salt1, isNot(salt2));

      final h1 = PinRules.hashPin(pin: '123456', salt: salt1, userId: 'u1');
      expect(h1, PinRules.hashPin(pin: '123456', salt: salt1, userId: 'u1'));
      expect(
        h1,
        isNot(PinRules.hashPin(pin: '123456', salt: salt2, userId: 'u1')),
      );
      // userId ต่าง → hash ต่าง (กันเอา hash ย้ายบัญชี)
      expect(
        h1,
        isNot(PinRules.hashPin(pin: '123456', salt: salt1, userId: 'u2')),
      );
    });

    test('verifyPin ผ่านเฉพาะ PIN ตรง', () {
      const salt = 'salt-x';
      final record = PinAccountRecord(
        userId: 'u1',
        phone: '0812345678',
        salt: salt,
        pinHash: PinRules.hashPin(pin: '246810', salt: salt, userId: 'u1'),
        displayName: 'ทดสอบ',
        method: AuthMethod.phoneOtp,
      );
      expect(PinRules.verifyPin(pin: '246810', record: record), isTrue);
      expect(PinRules.verifyPin(pin: '246811', record: record), isFalse);
      expect(PinRules.verifyPin(pin: '24681', record: record), isFalse);
    });
  });

  group('AuthRepositoryImpl PIN', () {
    test(
      'restoreSession seed PIN เดโม → เบอร์ 0812344567 ล็อกอิน PIN 123456 ได้',
      () async {
        final repo = _repo();
        await repo.restoreSession();

        final result = await repo.signInWithPin(
          phone: '081-234-4567', // normalize ขีดออกก่อนเช็ก
          pin: '123456',
        );
        expect(result.failure, isNull);
        expect(result.session!.user!.id, 'user-lookkaew');
        expect(result.session!.isAuthenticated, isTrue);
      },
    );

    test('PIN ผิด → wrongPin, เบอร์ไม่เคยตั้ง → noPinForPhone', () async {
      final repo = _repo();
      await repo.restoreSession();

      final wrongPin = await repo.signInWithPin(
        phone: '0812344567',
        pin: '654321',
      );
      expect(wrongPin.failure, PinSignInFailure.wrongPin);
      expect(wrongPin.session, isNull);

      final noPin = await repo.signInWithPin(
        phone: '0890001111',
        pin: '123456',
      );
      expect(noPin.failure, PinSignInFailure.noPinForPhone);
      expect(noPin.session, isNull);
    });

    test(
      'setPin ผูกเบอร์บัญชี → hasPinForPhone true และล็อกอินด้วย PIN ใหม่ได้',
      () async {
        final repo = _repo();
        await repo.restoreSession();

        expect(await repo.hasPinForPhone(_phoneUser.phone!), isFalse);
        await repo.setPin(user: _phoneUser, pin: '111222');
        expect(await repo.hasPinForPhone('0899998888'), isTrue);

        final result = await repo.signInWithPin(
          phone: '0899998888',
          pin: '111222',
        );
        expect(result.failure, isNull);
        // session ต้องคืนบัญชีเดิมที่ผูกกับ PIN ไม่ใช่บัญชีเดโม
        expect(result.session!.user!.id, 'user-newbie');
      },
    );

    test('setPin ปฏิเสธ PIN ไม่ครบ 6 หลัก และบัญชีไม่มีเบอร์', () async {
      final repo = _repo();
      expect(
        () => repo.setPin(user: _phoneUser, pin: '123'),
        throwsArgumentError,
      );
      const noPhone = AuthUser(
        id: 'u-social',
        displayName: 'Social User',
        method: AuthMethod.apple,
      );
      expect(
        () => repo.setPin(user: noPhone, pin: '123456'),
        throwsArgumentError,
      );
    });

    test(
      'changePin ต้องผ่าน PIN เดิม — เปลี่ยนแล้ว PIN เก่าใช้ไม่ได้',
      () async {
        final repo = _repo();
        await repo.restoreSession();
        await repo.setPin(user: _phoneUser, pin: '111222');

        expect(
          await repo.changePin(
            user: _phoneUser,
            currentPin: '000000',
            newPin: '333444',
          ),
          isFalse,
        );
        expect(
          await repo.verifyCurrentPin(user: _phoneUser, pin: '111222'),
          isTrue,
        );

        expect(
          await repo.changePin(
            user: _phoneUser,
            currentPin: '111222',
            newPin: '333444',
          ),
          isTrue,
        );
        expect(
          await repo.verifyCurrentPin(user: _phoneUser, pin: '111222'),
          isFalse,
        );

        final result = await repo.signInWithPin(
          phone: '0899998888',
          pin: '333444',
        );
        expect(result.failure, isNull);
      },
    );

    test('PIN อยู่รอดการออกจากระบบ (signOut ลบ session ไม่ลบ PIN)', () async {
      final repo = _repo();
      await repo.restoreSession();
      await repo.signInWithPin(phone: '0812344567', pin: '123456');
      await repo.signOut();

      final again = await repo.signInWithPin(
        phone: '0812344567',
        pin: '123456',
      );
      expect(again.failure, isNull);
    });
  });

  group('InMemoryAuthPinStorage', () {
    test('saveRecord แทนที่ตามเบอร์ และลบตาม userId', () async {
      const salt = 's';
      PinAccountRecord rec(String user, String phone) => PinAccountRecord(
        userId: user,
        phone: phone,
        salt: salt,
        pinHash: PinRules.hashPin(pin: '123456', salt: salt, userId: user),
        displayName: user,
        method: AuthMethod.phoneOtp,
      );
      final storage = InMemoryAuthPinStorage()
        ..saveRecord(rec('u1', '0811111111'))
        ..saveRecord(rec('u2', '0811111111')); // เบอร์ซ้ำ → แทนที่

      expect((await storage.findByPhone('0811111111'))!.userId, 'u2');
      expect(await storage.findByUserId('u1'), isNull);

      await storage.deleteForUser('u2');
      expect(await storage.findByPhone('0811111111'), isNull);
    });
  });
}
