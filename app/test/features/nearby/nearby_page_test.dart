import 'dart:async';
import 'dart:typed_data';

import 'package:catlive/core/config/app_locale.dart';
import 'package:catlive/core/theme/app_theme.dart';
import 'package:catlive/core/widgets/error_view.dart';
import 'package:catlive/features/nearby/data/datasources/mock_nearby_data_source.dart';
import 'package:catlive/features/nearby/data/repositories/nearby_repository_impl.dart';
import 'package:catlive/features/nearby/domain/entities/nearby_data.dart';
import 'package:catlive/features/nearby/domain/repositories/nearby_repository.dart';
import 'package:catlive/features/nearby/presentation/pages/nearby_page.dart';
import 'package:catlive/features/nearby/presentation/providers/nearby_providers.dart';
import 'package:catlive/features/nearby/presentation/widgets/nearby_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _kTransparentPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _MemoryTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_kTransparentPng);
}

class _ControlledNearbyRepository implements NearbyRepository {
  _ControlledNearbyRepository(this._inner);

  final NearbyRepository _inner;
  Completer<NearbySnapshot>? pendingFetch;
  bool failFetch = false;

  @override
  Future<NearbySnapshot> fetchNearby() async {
    if (pendingFetch != null) return pendingFetch!.future;
    if (failFetch) throw Exception('network error');
    return _inner.fetchNearby();
  }

  @override
  Future<Set<String>> toggleBookmark(String placeId) =>
      _inner.toggleBookmark(placeId);
}

class _FakeLocationService implements NearbyLocationService {
  NearbyLocationResult nextResult = const NearbyLocationSuccess(13.7800, 100.5500);

  @override
  Future<NearbyLocationResult> getCurrentLocation() async => nextResult;
}

Widget _buildTestApp({
  required NearbyRepository repository,
  NearbyLocationService? locationService,
  String initialLocale = 'th',
}) {
  return ProviderScope(
    overrides: [
      nearbyRepositoryProvider.overrideWithValue(repository),
      nearbyLocationServiceProvider.overrideWithValue(
        locationService ?? _FakeLocationService(),
      ),
    ],
    child: _TestShell(initialLocale: initialLocale),
  );
}

class _TestShell extends ConsumerStatefulWidget {
  const _TestShell({required this.initialLocale});
  final String initialLocale;

  @override
  ConsumerState<_TestShell> createState() => _TestShellState();
}

class _TestShellState extends ConsumerState<_TestShell> {
  @override
  void initState() {
    super.initState();
    if (widget.initialLocale != 'th') {
      Future.microtask(
        () => ref
            .read(appLocaleProvider.notifier)
            .setLocale(widget.initialLocale),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: NearbyPage(tileProvider: _MemoryTileProvider())),
    );
  }
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.descendant(
      of: find.byKey(const Key('nearby-main-list')),
      matching: find.byType(Scrollable),
    ).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _switchToListView(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nearby-list-view-btn')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('แสดง loading skeleton แล้วเข้าแผนที่เต็มจอก่อนสลับดูรายการอารีย์', (
    tester,
  ) async {
    final repo = _ControlledNearbyRepository(
      NearbyRepositoryImpl(MockNearbyDataSource()),
    );
    final completer = Completer<NearbySnapshot>();
    repo.pendingFetch = completer;

    await tester.pumpWidget(_buildTestApp(repository: repo));
    await tester.pump();
    expect(find.byType(NearbySkeleton), findsOneWidget);

    repo.pendingFetch = null;
    completer.complete(
      await NearbyRepositoryImpl(MockNearbyDataSource()).fetchNearby(),
    );
    await tester.pumpAndSettle();

    // เข้าครั้งแรกต้องอยู่โหมดแผนที่เต็มจอ
    expect(find.byKey(const Key('nearby-recenter-btn')), findsOneWidget);
    expect(find.byKey(const Key('nearby-list-view-btn')), findsOneWidget);

    // สลับเป็นโหมดรายการ
    await _switchToListView(tester);

    expect(find.text('ใกล้ฉัน'), findsOneWidget);
    expect(find.text('อารีย์'), findsOneWidget);
    expect(find.text('ในรัศมี 3 กม.'), findsOneWidget);
    expect(find.byKey(const Key('nearby-inline-recenter-btn')), findsOneWidget);

    await _scrollTo(tester, find.text('Meow Corner Café'));
    expect(find.text('เหมียวช็อป อารีย์'), findsOneWidget);
    expect(find.text('คลินิกรักษ์แมว'), findsOneWidget);
    expect(find.text('Meow Corner Café'), findsOneWidget);
    // ย่อไว้ 3 แห่งแรก ยังไม่แสดงแห่งที่ 4 จนกว่าจะกดดูทั้งหมด
    expect(find.text('โรงพยาบาลสัตว์ปากซอย 24 ชม.'), findsNothing);

    await _scrollTo(tester, find.textContaining('น้องข้าวตู'));
    expect(find.textContaining('น้องข้าวตู'), findsOneWidget);
  });

  testWidgets('แสดง ErrorView เมื่อโหลดล้มเหลว และกดลองใหม่ได้', (tester) async {
    final repo = _ControlledNearbyRepository(
      NearbyRepositoryImpl(MockNearbyDataSource()),
    )..failFetch = true;

    await tester.pumpWidget(_buildTestApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('ลองใหม่'), findsOneWidget);

    repo.failFetch = false;
    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();

    await _switchToListView(tester);
    await _scrollTo(tester, find.text('เหมียวช็อป อารีย์'));
    expect(find.text('เหมียวช็อป อารีย์'), findsOneWidget);
  });

  testWidgets('กรองหมวดหมู่ ค้นหา และแสดง empty state เมื่อไม่พบข้อมูล', (
    tester,
  ) async {
    final repo = NearbyRepositoryImpl(MockNearbyDataSource());
    await tester.pumpWidget(_buildTestApp(repository: repo));
    await tester.pumpAndSettle();
    await _switchToListView(tester);

    // เลือกหมวดคลินิก -> แสดงเฉพาะคลินิกและซ่อนส่วนแมวใกล้คุณ
    await tester.tap(find.byKey(const Key('nearby-chip-clinic')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('คลินิกรักษ์แมว'));
    expect(find.text('สถานที่ใกล้คุณ'), findsOneWidget);
    expect(find.text('ดูทั้งหมด'), findsOneWidget);
    expect(find.text('คลินิกรักษ์แมว'), findsOneWidget);
    expect(find.text('เหมียวช็อป อารีย์'), findsNothing);
    expect(find.text('แมวใกล้คุณ'), findsNothing);

    // เลื่อนกลับขึ้นบนสุดก่อนเลือกหมวดประกาศใกล้ฉัน
    await tester.drag(
      find.byKey(const Key('nearby-main-list')),
      const Offset(0, 600),
    );
    await tester.pumpAndSettle();

    // เลือกหมวดประกาศใกล้ฉัน -> เปลี่ยนหัวข้อเป็น ประกาศใกล้คุณ และซ่อนสถานที่
    await tester.tap(find.byKey(const Key('nearby-chip-announcements')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('ประกาศใกล้คุณ'));
    expect(find.text('ประกาศใกล้คุณ'), findsOneWidget);
    expect(find.text('คลินิกรักษ์แมว'), findsNothing);

    // เลื่อนกลับขึ้นบนสุดแล้วกดซ้ำเพื่อยกเลิกตัวกรอง
    await tester.drag(
      find.byKey(const Key('nearby-main-list')),
      const Offset(0, 600),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nearby-chip-announcements')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('สถานที่ใกล้คุณ'));
    expect(find.text('สถานที่ใกล้คุณ'), findsOneWidget);

    // พิมพ์คำค้นที่ไม่มีผล -> แสดง empty state
    await tester.enterText(
      find.byKey(const Key('nearby-search-input')),
      'ไม่มีร้านนี้แน่นอน',
    );
    await tester.pumpAndSettle();
    await _scrollTo(
      tester,
      find.text('ไม่พบข้อมูลที่ตรงกับการค้นหาในพื้นที่นี้'),
    );
    expect(
      find.text('ไม่พบข้อมูลที่ตรงกับการค้นหาในพื้นที่นี้'),
      findsOneWidget,
    );
  });

  testWidgets('สลับรัศมี ขยายดูทั้งหมด และบันทึกสถานที่', (tester) async {
    final repo = NearbyRepositoryImpl(MockNearbyDataSource());
    await tester.pumpWidget(_buildTestApp(repository: repo));
    await tester.pumpAndSettle();
    await _switchToListView(tester);

    // สลับรัศมี 3 -> 5 -> 1 กม.
    await tester.tap(find.byKey(const Key('nearby-radius-cycle')));
    await tester.pumpAndSettle();
    expect(find.text('ในรัศมี 5 กม.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nearby-radius-cycle')));
    await tester.pumpAndSettle();
    expect(find.text('ในรัศมี 1 กม.'), findsOneWidget);

    // กดคืนเป็น 3 กม. แล้วกดดูทั้งหมด (แผนที่ยังอยู่ และแสดง "สถานที่ใกล้คุณ 6 แห่ง")
    await tester.tap(find.byKey(const Key('nearby-radius-cycle')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.byKey(const Key('nearby-places-toggle')));
    await tester.tap(find.byKey(const Key('nearby-places-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('สถานที่ใกล้คุณ 6 แห่ง'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('nearby-main-list')),
      const Offset(0, 600),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nearby-fullscreen-btn')), findsOneWidget);
    await _scrollTo(tester, find.text('Cat Stay บ้านรับฝากแมว'));
    expect(find.text('Cat Stay บ้านรับฝากแมว'), findsOneWidget);

    // เลื่อนกลับขึ้นบนสุดแล้วกดบันทึกสถานที่ -> ไอคอนเปลี่ยนเป็นแบบทึบ
    await tester.drag(
      find.byKey(const Key('nearby-main-list')),
      const Offset(0, 600),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nearby-bookmark-ari-p1')));
    await tester.pumpAndSettle();
    expect(find.text('บันทึก เหมียวช็อป อารีย์ แล้ว'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);

    // กดใช้ตำแหน่งของฉันบนการ์ดแผนที่ -> ขอพิกัดและอัปเดตตำแหน่ง
    await tester.drag(
      find.byKey(const Key('nearby-main-list')),
      const Offset(0, 600),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nearby-inline-recenter-btn')));
    await tester.pumpAndSettle();
    expect(find.text('อัปเดตตำแหน่งแล้ว (13.7800, 100.5500)'), findsOneWidget);
    expect(find.text('ตำแหน่งของฉัน'), findsOneWidget);
  });

  testWidgets('แตะสถานที่เปิดการ์ดพรีวิว และรองรับภาษาอังกฤษ', (tester) async {
    final repo = NearbyRepositoryImpl(MockNearbyDataSource());
    await tester.pumpWidget(
      _buildTestApp(repository: repo, initialLocale: 'en'),
    );
    await tester.pumpAndSettle();

    // เข้าครั้งแรกอยู่โหมดแผนที่เต็มจอ
    expect(find.byKey(const Key('nearby-recenter-btn')), findsOneWidget);
    await _switchToListView(tester);

    expect(find.text('Nearby'), findsOneWidget);
    expect(find.text('Ari'), findsOneWidget);
    expect(find.text('Within 3 km'), findsOneWidget);

    await _scrollTo(tester, find.byKey(const Key('nearby-place-row-ari-p1')));
    expect(find.text('Meow Shop Ari'), findsOneWidget);
    await tester.tap(find.byKey(const Key('nearby-place-row-ari-p1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nearby-map-preview-card')), findsOneWidget);
    expect(find.text('Pet Shop · 0.5 km'), findsOneWidget);
    expect(find.text('Meow Shop Ari'), findsOneWidget);
    expect(
      find.byKey(const Key('nearby-preview-navigate-btn')),
      findsOneWidget,
    );

    // กดปิดการ์ดพรีวิว
    await tester.tap(find.byKey(const Key('nearby-preview-close-btn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nearby-map-preview-card')), findsNothing);
  });
}
