import 'package:catlive/core/config/pet_species_config.dart';
import 'package:catlive/features/feature_flags/domain/entities/feature_flags_data.dart';
import 'package:catlive/features/feature_flags/domain/usecases/feature_flags_usecases.dart';
import 'package:catlive/features/feature_flags/presentation/pages/feature_flags_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _wrapFeatureFlagsPage({PetSpeciesConfig? species}) {
  final router = GoRouter(
    initialLocation: '/feature-flags',
    routes: [
      GoRoute(
        path: '/feature-flags',
        builder: (_, _) => const FeatureFlagsPage(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      if (species != null) petSpeciesConfigProvider.overrideWithValue(species),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  test('ค่าเริ่มต้น Feature Flags ปิดฟีเจอร์ Phase 2 และเปิดกติกา Phase 1', () {
    for (final meta in FeatureFlagMetadata.catalog) {
      if (meta.isPhase2Feature) {
        expect(meta.defaultEnabled, isFalse, reason: meta.key);
      } else {
        expect(meta.defaultEnabled, isTrue, reason: meta.key);
      }
    }
  });

  test('FeatureFlagsRules ตรวจ Force Update ตาม Semantic Version ถูกต้อง', () {
    expect(
      FeatureFlagsRules.isForceUpdateRequired(
        currentVersion: '0.9.9',
        minSupportedVersion: '1.0.0',
      ),
      isTrue,
    );
    expect(
      FeatureFlagsRules.isForceUpdateRequired(
        currentVersion: '1.0.0',
        minSupportedVersion: '1.0.0',
      ),
      isFalse,
    );
    expect(
      FeatureFlagsRules.isForceUpdateRequired(
        currentVersion: '1.2.0',
        minSupportedVersion: '1.1.9',
      ),
      isFalse,
    );
  });

  test('PetSpeciesConfig แยกคอนฟิกแมวและหมาพร้อมต่อยอด หมา.live', () {
    expect(PetSpeciesConfig.cat.brandName(false), 'แมว.live');
    expect(PetSpeciesConfig.dog.brandName(false), 'หมา.live');
    expect(PetSpeciesConfig.cat.aiAssistantName, 'Cat AI');
    expect(PetSpeciesConfig.dog.aiAssistantName, 'Dog AI');
  });

  testWidgets('FeatureFlagsPage เปิดดูและสลับโหมด Phase 1 / Phase 2 ได้', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapFeatureFlagsPage());
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Feature Flags (OPS-04)'), findsOneWidget);
    expect(
      find.text('สถานะ Phase 2 ที่เปิดอยู่: 0 / 8 รายการ'),
      findsOneWidget,
    );

    await tester.tap(find.text('เปิด Phase 2 ทั้งหมด'));
    await tester.pumpAndSettle();
    expect(
      find.text('สถานะ Phase 2 ที่เปิดอยู่: 8 / 8 รายการ'),
      findsOneWidget,
    );

    await tester.tap(find.text('ปิด Phase 2 (MVP)'));
    await tester.pumpAndSettle();
    expect(
      find.text('สถานะ Phase 2 ที่เปิดอยู่: 0 / 8 รายการ'),
      findsOneWidget,
    );
  });

  testWidgets('FeatureFlagsPage แสดงชื่อแบรนด์จาก PetSpeciesConfig (หมา.live)', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapFeatureFlagsPage(species: PetSpeciesConfig.dog));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.textContaining('หมา.live'), findsOneWidget);
  });
}
