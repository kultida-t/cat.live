import 'package:catlive/core/config/app_locale.dart';
import 'package:catlive/core/error/failure.dart';
import 'package:catlive/features/search/data/datasources/mock_search_data_source.dart';
import 'package:catlive/features/search/domain/entities/search_data.dart';
import 'package:catlive/features/search/domain/repositories/search_repository.dart';
import 'package:catlive/features/search/presentation/pages/search_page.dart';
import 'package:catlive/features/search/presentation/providers/search_providers.dart';
import 'package:catlive/features/search/presentation/widgets/search_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FailingSearchRepo implements SearchRepository {
  @override
  Future<SearchData> loadSearchData() async =>
      throw const UnknownFailure('โหลดข้อมูลไม่สำเร็จ');
}

class _SequenceSearchRepo implements SearchRepository {
  int calls = 0;

  @override
  Future<SearchData> loadSearchData() async {
    calls++;
    if (calls == 1) {
      throw const UnknownFailure('โหลดข้อมูลไม่สำเร็จ');
    }
    return (await const MockSearchDataSource().fetchSearchData()).toEntity();
  }
}

class _FixedLocale extends AppLocaleNotifier {
  _FixedLocale(this._initial);
  final String _initial;

  @override
  String build() => _initial;
}

Widget _wrapSearch({SearchRepository? repo, String initialLocale = 'th'}) {
  final router = GoRouter(
    initialLocation: '/search',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(path: '/search', builder: (_, _) => const SearchPage()),
      GoRoute(
        path: '/cat-ai',
        builder: (_, _) => const Scaffold(body: Text('Cat AI')),
      ),
      GoRoute(
        path: '/p/:id',
        builder: (_, state) =>
            Scaffold(body: Text('Post ${state.pathParameters['id']}')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      if (repo != null) searchRepositoryProvider.overrideWithValue(repo),
      appLocaleProvider.overrideWith(() => _FixedLocale(initialLocale)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _pumpLoaded(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

void main() {
  group('SearchPage', () {
    testWidgets('แสดงสถานะโหลด (Skeleton) แล้วแสดงคำค้นยอดนิยมและโพสต์แนะนำ', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapSearch());
      expect(find.byType(SearchSkeleton), findsOneWidget);

      await _pumpLoaded(tester);
      expect(find.text('คำค้นยอดนิยม'), findsOneWidget);
      expect(find.text('กินน้ำ'), findsOneWidget);
      expect(find.text('ลูกแมว'), findsOneWidget);
      expect(find.text('คาเฟ่'), findsOneWidget);
      expect(find.text('แมวสูงวัย'), findsOneWidget);
      expect(find.text('หาบ้าน'), findsOneWidget);
      expect(find.text('โพสต์แนะนำ'), findsOneWidget);
      expect(find.text('นุ่น & โมจิ · 2 ชม.'), findsOneWidget);
    });

    testWidgets('แตะคำค้นยอดนิยมจะเติมช่องค้นหาและกรองโพสต์', (tester) async {
      await tester.pumpWidget(_wrapSearch());
      await _pumpLoaded(tester);

      await tester.tap(find.text('กินน้ำ'));
      await tester.pumpAndSettle();

      expect(find.text('คำค้นยอดนิยม'), findsNothing);
      expect(find.text('โพสต์ (2)'), findsOneWidget);
      expect(find.text('หมอแมว Vet Note · 4 ชม.'), findsOneWidget);
      expect(find.text('กาย · แมวสูงวัย · 5 ชม.'), findsOneWidget);
    });

    testWidgets('พิมพ์ค้นหาพบบัญชีและกดปุ่มล้างคำค้นกลับสู่ค่าเริ่มต้น', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapSearch());
      await _pumpLoaded(tester);

      await tester.enterText(find.byType(TextField), 'หมอแมว');
      await tester.pumpAndSettle();

      expect(find.text('บัญชี'), findsOneWidget);
      expect(find.text('@maew.vetnote'), findsOneWidget);
      expect(find.text('โพสต์ (1)'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('ล้างคำค้นหา'));
      await tester.pumpAndSettle();

      expect(find.text('คำค้นยอดนิยม'), findsOneWidget);
      expect(find.text('โพสต์แนะนำ'), findsOneWidget);
    });

    testWidgets('กรองตามหมวดหมู่ช่วยแมวและเปิดหน้าโพสต์เมื่อแตะการ์ด', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapSearch());
      await _pumpLoaded(tester);

      await tester.tap(find.text('ช่วยแมว').first);
      await tester.pumpAndSettle();

      expect(find.text('คำค้นยอดนิยม'), findsNothing);
      expect(find.text('โพสต์ (1)'), findsOneWidget);
      expect(find.text('ช่วยแมวกรุงเทพ · 30 นาที'), findsOneWidget);

      await tester.tap(find.text('ช่วยแมวกรุงเทพ · 30 นาที'));
      await tester.pumpAndSettle();
      expect(find.text('Post p5'), findsOneWidget);
    });

    testWidgets('แสดงสถานะว่างเมื่อไม่พบผลลัพธ์และมีลิงก์ถาม Cat AI', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapSearch());
      await _pumpLoaded(tester);

      await tester.enterText(find.byType(TextField), 'ไม่มีคำนี้แน่นอน');
      await tester.pumpAndSettle();

      expect(find.text('โพสต์ (0)'), findsOneWidget);
      expect(
        find.textContaining('ไม่พบผลลัพธ์สำหรับ “ไม่มีคำนี้แน่นอน”'),
        findsOneWidget,
      );
      expect(find.textContaining('ถาม Cat AI'), findsOneWidget);
    });

    testWidgets('แสดงสถานะผิดพลาดและโหลดใหม่ได้เมื่อกดลองใหม่', (tester) async {
      final repo = _SequenceSearchRepo();
      await tester.pumpWidget(_wrapSearch(repo: repo));
      await _pumpLoaded(tester);

      expect(find.text('โหลดข้อมูลไม่สำเร็จ'), findsWidgets);
      await tester.tap(find.text('ลองใหม่'));
      await _pumpLoaded(tester);

      expect(find.text('โพสต์แนะนำ'), findsOneWidget);
    });

    testWidgets('รองรับภาษาอังกฤษเมื่อ appLocaleProvider เป็น en', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapSearch(initialLocale: 'en'));
      await _pumpLoaded(tester);

      expect(find.text('Trending searches'), findsOneWidget);
      expect(find.text('Recommended posts'), findsOneWidget);
      expect(find.text('Search cats, people, or topics'), findsOneWidget);
    });

    testWidgets('แสดง error state เมื่อโหลดล้มเหลว', (tester) async {
      await tester.pumpWidget(_wrapSearch(repo: _FailingSearchRepo()));
      await _pumpLoaded(tester);

      expect(find.text('โหลดข้อมูลไม่สำเร็จ'), findsWidgets);
      expect(find.text('ลองใหม่'), findsOneWidget);
    });

    testWidgets('ออกจากหน้าค้นหาแล้วเปิดเข้ามาใหม่ จะรีเซ็ตกลับหน้าเริ่มต้น', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/search'),
                child: const Text('GoSearch'),
              ),
            ),
          ),
          GoRoute(path: '/search', builder: (_, _) => const SearchPage()),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('GoSearch'));
      await _pumpLoaded(tester);

      await tester.enterText(find.byType(TextField), 'หมอแมว');
      await tester.pumpAndSettle();
      expect(find.text('คำค้นยอดนิยม'), findsNothing);

      await tester.tap(find.bySemanticsLabel('ย้อนกลับ'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('GoSearch'));
      await _pumpLoaded(tester);
      expect(find.text('คำค้นยอดนิยม'), findsOneWidget);
      expect(find.text('โพสต์แนะนำ'), findsOneWidget);
    });
  });
}
