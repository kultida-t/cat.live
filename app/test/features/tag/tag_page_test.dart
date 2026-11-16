import 'package:catlive/core/config/app_locale.dart';
import 'package:catlive/core/error/failure.dart';
import 'package:catlive/features/tag/domain/entities/tag_product_data.dart';
import 'package:catlive/features/tag/domain/repositories/tag_repository.dart';
import 'package:catlive/features/tag/presentation/pages/tag_page.dart';
import 'package:catlive/features/tag/presentation/providers/tag_providers.dart';
import 'package:catlive/features/tag/presentation/widgets/tag_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _EmptyTagRepo implements TagRepository {
  @override
  Future<TagProductData> loadTagProduct() async => const TagProductData(
    priceThb: 990,
    tagColors: [],
    collarColors: [],
    engraveColors: [],
    specs: [],
  );
}

class _FailingTagRepo implements TagRepository {
  @override
  Future<TagProductData> loadTagProduct() async =>
      throw const UnknownFailure('เชื่อมต่อไม่สำเร็จ');
}

Widget _wrapTag({TagRepository? repo, String initialLocale = 'th'}) {
  final router = GoRouter(
    initialLocation: '/tag',
    routes: [
      GoRoute(path: '/tag', builder: (_, _) => const TagPage()),
    ],
  );
  return ProviderScope(
    overrides: [
      if (repo != null) tagRepositoryProvider.overrideWithValue(repo),
    ],
    child: Consumer(
      builder: (context, ref, child) {
        if (initialLocale == 'en' && ref.read(appLocaleProvider) != 'en') {
          Future.microtask(
            () => ref.read(appLocaleProvider.notifier).setLocale('en'),
          );
        }
        return MaterialApp.router(routerConfig: router);
      },
    ),
  );
}

void main() {
  testWidgets('แสดง loading skeleton แล้วโหลดหน้า แมว.live Tag สำเร็จ (TH)', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapTag());
    expect(find.byType(TagSkeleton), findsOneWidget);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('แมว.live Tag'), findsWidgets);
    expect(find.text('น้องหลง\nไม่ต้องหลงหา'), findsOneWidget);
    expect(find.text('฿990'), findsOneWidget);
    expect(find.text('ซื้อเลย'), findsOneWidget);
  });

  testWidgets('เลือกสีแท็กและสีปลอกคอแล้วกดซื้อเลย แสดงชีตสรุปแบบที่เลือก', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapTag());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.scrollUntilVisible(
      find.bySemanticsLabel('สีตัวเรือน ชมพู'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.bySemanticsLabel('สีตัวเรือน ชมพู'));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.scrollUntilVisible(
      find.bySemanticsLabel('สีปลอกคอ เหลืองบัตเตอร์'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.bySemanticsLabel('สีปลอกคอ เหลืองบัตเตอร์'));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('ซื้อเลย'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('สรุปแบบที่เลือกไว้'), findsOneWidget);
    expect(find.text('ชมพู'), findsOneWidget);
    expect(find.text('เหลืองบัตเตอร์'), findsOneWidget);
  });

  testWidgets('กดปุ่มส่งเสียงและไฟฉายแสดง toast แจ้งเตือน', (tester) async {
    await tester.pumpWidget(_wrapTag());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.scrollUntilVisible(
      find.bySemanticsLabel('เสียง'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.bySemanticsLabel('เสียง'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('กำลังส่งเสียงเรียกแท็กของ ส้มจี๊ด'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('ไฟฉาย'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('เปิดไฟฉายแล้ว (ตัวอย่าง)'), findsOneWidget);
  });

  testWidgets('แสดง Empty state พร้อมปุ่มลองใหม่', (tester) async {
    await tester.pumpWidget(_wrapTag(repo: _EmptyTagRepo()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('ยังไม่มีข้อมูลสินค้า'), findsOneWidget);
    expect(find.text('ลองใหม่'), findsOneWidget);
  });

  testWidgets('แสดง Error state พร้อมปุ่มลองใหม่', (tester) async {
    await tester.pumpWidget(_wrapTag(repo: _FailingTagRepo()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('โหลดข้อมูลแท็กไม่สำเร็จ'), findsOneWidget);
    expect(find.text('เชื่อมต่อไม่สำเร็จ'), findsOneWidget);
    expect(find.text('ลองใหม่'), findsOneWidget);
  });

  testWidgets('รองรับภาษาอังกฤษ (EN)', (tester) async {
    await tester.pumpWidget(_wrapTag(initialLocale: 'en'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Lost cat\nNever search blindly'), findsOneWidget);
    expect(find.text('Buy now'), findsOneWidget);
  });
}
