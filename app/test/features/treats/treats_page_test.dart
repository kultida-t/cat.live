import 'package:catlive/core/config/app_locale.dart';
import 'package:catlive/core/error/failure.dart';
import 'package:catlive/features/treats/data/datasources/mock_treats_data_source.dart';
import 'package:catlive/features/treats/domain/entities/treats_data.dart';
import 'package:catlive/features/treats/domain/repositories/treats_repository.dart';
import 'package:catlive/features/treats/presentation/pages/treats_page.dart';
import 'package:catlive/features/treats/presentation/providers/treats_providers.dart';
import 'package:catlive/features/treats/presentation/widgets/treats_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _EmptyTreatsRepo implements TreatsRepository {
  @override
  Future<TreatsData> loadTreatsData() async =>
      const TreatsData(recipients: [], treats: []);
}

class _SequenceTreatsRepo implements TreatsRepository {
  int calls = 0;

  @override
  Future<TreatsData> loadTreatsData() async {
    calls++;
    if (calls == 1) {
      throw const UnknownFailure('โหลดข้อมูลไม่สำเร็จ');
    }
    return (await const MockTreatsDataSource().fetchTreatsData()).toEntity();
  }
}

class _FixedLocale extends AppLocaleNotifier {
  _FixedLocale(this._initial);
  final String _initial;

  @override
  String build() => _initial;
}

Widget _wrapTreats({
  TreatsRepository? repo,
  String? toId,
  String initialLocale = 'th',
}) {
  final location = toId == null ? '/treats' : '/treats?to=$toId';
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: '/treats',
        builder: (_, state) =>
            TreatsPage(initialRecipientId: state.uri.queryParameters['to']),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      if (repo != null) treatsRepositoryProvider.overrideWithValue(repo),
      appLocaleProvider.overrideWith(() => _FixedLocale(initialLocale)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _pumpLoaded(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 50));
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('TreatsPage', () {
    testWidgets('แสดง Skeleton แล้วแสดงผู้รับและขนมครบ 4 แบบตรงเว็บ', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapTreats());
      expect(find.byType(TreatsSkeleton), findsOneWidget);

      await _pumpLoaded(tester);
      expect(find.text('เลี้ยงขนมแมว'), findsOneWidget);
      expect(find.text('ส่งให้แมวตัวไหน'), findsOneWidget);
      expect(find.text('ดูทั้งหมด'), findsOneWidget);
      expect(find.text('+10'), findsOneWidget);
      expect(find.text('เลือกขนม'), findsOneWidget);
      expect(find.text('ลากหมุนดูแพ็กได้ 360°'), findsOneWidget);
      expect(find.text('ขนมแมวเลีย รสทูน่า'), findsOneWidget);
      expect(find.text('฿59'), findsOneWidget);
      expect(find.text('ใส่ตะกร้า · ฿59'), findsOneWidget);
      expect(find.text('ส่งขนมให้ นุ่น & โมจิ'), findsOneWidget);
    });

    testWidgets('แสดง Empty state พร้อมปุ่มลองใหม่', (tester) async {
      await tester.pumpWidget(_wrapTreats(repo: _EmptyTreatsRepo()));
      await _pumpLoaded(tester);

      expect(find.text('ยังไม่มีรายการขนมในขณะนี้'), findsOneWidget);
      expect(find.text('ลองใหม่'), findsOneWidget);
    });

    testWidgets('แสดง Error state และกดลองใหม่จนโหลดสำเร็จได้', (tester) async {
      await tester.pumpWidget(_wrapTreats(repo: _SequenceTreatsRepo()));
      await _pumpLoaded(tester);

      expect(find.text('โหลดหน้าเลี้ยงขนมไม่สำเร็จ'), findsOneWidget);
      await tester.tap(find.text('ลองใหม่'));
      await _pumpLoaded(tester);

      expect(find.text('ส่งให้แมวตัวไหน'), findsOneWidget);
    });

    testWidgets('รองรับพารามิเตอร์ ?to=vet เพื่อเลือกผู้รับล่วงหน้า', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapTreats(toId: 'vet'));
      await _pumpLoaded(tester);

      expect(find.text('ส่งขนมให้ หมอแมว Vet Note'), findsOneWidget);
      expect(find.text('ข้อความถึง หมอแมว Vet Note'), findsOneWidget);
    });

    testWidgets('เปิดแผ่นล่างดูทั้งหมดและค้นหาผู้รับได้', (tester) async {
      _usePhoneViewport(tester);
      await tester.pumpWidget(_wrapTreats());
      await _pumpLoaded(tester);

      await tester.tap(find.text('ดูทั้งหมด'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('ส่งให้แมวตัวไหน · 14'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'ไม่มีชื่อนี้');
      await tester.pump();
      expect(find.text('ไม่พบแมวชื่อนี้'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'ต้นกล้า');
      await tester.pump();
      await tester.tap(find.text('ต้นกล้า').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('ส่งขนมให้ ต้นกล้า'), findsOneWidget);
    });

    testWidgets('เลือกขนม เพิ่มจำนวน ใส่ตะกร้า ลบออก และชำระเงินจนสำเร็จ', (
      tester,
    ) async {
      _usePhoneViewport(tester);
      await tester.pumpWidget(_wrapTreats());
      await _pumpLoaded(tester);

      // เลือกขนมกรุบกรอบ (฿89) และเพิ่มจำนวนเป็น 2
      await tester.tap(find.text('กรุบกรอบ'));
      await tester.pump();
      expect(find.text('ขนมกรุบกรอบ รสไก่'), findsOneWidget);
      expect(find.text('ใส่ตะกร้า · ฿89'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('เพิ่มจำนวน'));
      await tester.pump();
      expect(find.text('ใส่ตะกร้า · ฿178'), findsOneWidget);

      await tester.tap(find.text('ใส่ตะกร้า · ฿178'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ในตะกร้า 2'), findsOneWidget);
      expect(find.text('รวม 2 ชิ้น · ส่งฟรี'), findsOneWidget);
      expect(find.text('฿178'), findsWidgets);

      // กดส่งขนม -> เข้าหน้าชำระเงิน QR
      await tester.tap(find.text('ส่งขนมให้ นุ่น & โมจิ'));
      await tester.pump();
      expect(find.text('ชำระเงิน'), findsOneWidget);
      expect(find.text('ยอดชำระ · 2 ชิ้น'), findsOneWidget);
      expect(find.textContaining('แมว.live'), findsOneWidget);

      // กดชำระเงินแล้ว -> หน้าสำเร็จ
      await tester.tap(find.text('ชำระเงินแล้ว'));
      await tester.pump();
      expect(find.text('ส่งขนมให้ นุ่น & โมจิ แล้ว'), findsOneWidget);

      // กดเลี้ยงขนมแมวตัวอื่น -> รีเซ็ตกลับหน้าแรก
      await tester.tap(find.text('เลี้ยงขนมแมวตัวอื่น'));
      await tester.pump();
      expect(find.text('รวม 0 ชิ้น · ส่งฟรี'), findsOneWidget);
    });

    testWidgets('สลับเป็นภาษาอังกฤษแสดงข้อความภาษาอังกฤษครบ', (tester) async {
      await tester.pumpWidget(_wrapTreats(initialLocale: 'en'));
      await _pumpLoaded(tester);

      expect(find.text('Send Cat Treats'), findsOneWidget);
      expect(find.text('Which cat to send to?'), findsOneWidget);
      expect(find.text('Choose treats'), findsOneWidget);
      expect(find.text('Drag to rotate pack 360°'), findsOneWidget);
    });
  });
}
