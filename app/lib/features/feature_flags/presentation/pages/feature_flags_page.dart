import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/config/pet_species_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/feature_flags_data.dart';
import '../../domain/usecases/feature_flags_usecases.dart';
import '../providers/feature_flags_controller.dart';

/// หน้าจัดการ Feature Flags (OPS-04 / DEC-01..11) สำหรับสลับเปิด-ปิดฟีเจอร์ Phase 1 / Phase 2
class FeatureFlagsPage extends ConsumerStatefulWidget {
  const FeatureFlagsPage({super.key});

  @override
  ConsumerState<FeatureFlagsPage> createState() => _FeatureFlagsPageState();
}

class _FeatureFlagsPageState extends ConsumerState<FeatureFlagsPage>
    with ToastMixin {
  @override
  void dispose() {
    disposeToast();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(featureFlagsControllerProvider);
    final controller = ref.read(featureFlagsControllerProvider.notifier);
    final isEn = ref.watch(appLocaleProvider) == 'en';
    final species = ref.watch(petSpeciesConfigProvider);

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Header(
                  title: isEn ? 'Feature Flags (OPS-04)' : 'Feature Flags (OPS-04)',
                  backLabel: isEn ? 'Back' : 'ย้อนกลับ',
                  onBack: () => context.pop(),
                ),
                Expanded(
                  child: switch (state.status) {
                    FeatureFlagsLoadStatus.loading => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    FeatureFlagsLoadStatus.error => ErrorView(
                      title: isEn
                          ? 'Unable to load feature flags'
                          : 'โหลดข้อมูล Feature Flags ไม่สำเร็จ',
                      message: state.errorMessage ?? '',
                      onRetry: controller.retry,
                    ),
                    FeatureFlagsLoadStatus.ready => _buildContent(
                      snapshot: state.snapshot!,
                      isForceUpdate: state.isForceUpdateRequired,
                      isEn: isEn,
                      species: species,
                      controller: controller,
                    ),
                  },
                ),
              ],
            ),
            if (toastMessage != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: IgnorePointer(
                  child: Center(child: ToastPill(message: toastMessage!)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent({
    required FeatureFlagsSnapshot snapshot,
    required bool isForceUpdate,
    required bool isEn,
    required PetSpeciesConfig species,
    required FeatureFlagsController controller,
  }) {
    final phase2EnabledCount = FeatureFlagsRules.countEnabledPhase2Features(
      snapshot,
    );
    final phase2Items = FeatureFlagMetadata.catalog
        .where((e) => e.isPhase2Feature)
        .toList();
    final phase1Items = FeatureFlagMetadata.catalog
        .where((e) => !e.isPhase2Feature)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 36),
      children: [
        _SummaryCard(
          snapshot: snapshot,
          phase2EnabledCount: phase2EnabledCount,
          totalPhase2Count: phase2Items.length,
          isForceUpdate: isForceUpdate,
          species: species,
          isEn: isEn,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  await controller.setAllPhase2(false);
                  showToast(
                    isEn
                        ? 'Phase 1 MVP preset applied'
                        : 'ตั้งค่าเป็นโหมด Phase 1 (MVP) แล้ว',
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.line2),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                child: Text(
                  isEn ? 'Phase 1 Only' : 'ปิด Phase 2 (MVP)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () async {
                  await controller.setAllPhase2(true);
                  showToast(
                    isEn
                        ? 'All Phase 2 features enabled'
                        : 'เปิดฟีเจอร์ Phase 2 ทั้งหมดแล้ว',
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ownerTeal,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                child: Text(
                  isEn ? 'Enable Phase 2' : 'เปิด Phase 2 ทั้งหมด',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionTitle(
          title: isEn
              ? 'Phase 2 Features (Hidden in MVP)'
              : 'ฟีเจอร์ Phase 2 (ซ่อนใน Phase 1 ตามมติ)',
        ),
        _FlagCardGroup(
          items: phase2Items,
          snapshot: snapshot,
          isEn: isEn,
          onToggle: (flag, val) async {
            await controller.toggleFlag(flag, val);
            final meta = FeatureFlagMetadata.of(flag);
            showToast(
              '${meta.title(isEn)}: ${val ? (isEn ? 'ON' : 'เปิด') : (isEn ? 'OFF' : 'ปิด')}',
            );
          },
        ),
        const SizedBox(height: 18),
        _SectionTitle(
          title: isEn
              ? 'Phase 1 Policy & Store Rules'
              : 'กติกา Phase 1 & App Store (DEC-01 / DEC-09)',
        ),
        _FlagCardGroup(
          items: phase1Items,
          snapshot: snapshot,
          isEn: isEn,
          onToggle: (flag, val) async {
            await controller.toggleFlag(flag, val);
            final meta = FeatureFlagMetadata.of(flag);
            showToast(
              '${meta.title(isEn)}: ${val ? (isEn ? 'ON' : 'เปิด') : (isEn ? 'OFF' : 'ปิด')}',
            );
          },
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () async {
            await controller.resetToDefault();
            showToast(
              isEn ? 'Reset to server defaults' : 'รีเซ็ตกลับค่ามาตรฐานแล้ว',
            );
          },
          icon: const Icon(LucideIcons.rotateCcw, size: 16),
          label: Text(
            isEn ? 'Reset overrides' : 'รีเซ็ตค่าเริ่มต้นตามสเปก',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.backLabel,
    required this.onBack,
  });

  final String title;
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: backLabel,
            excludeSemantics: true,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  LucideIcons.chevronLeft,
                  size: 22,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.snapshot,
    required this.phase2EnabledCount,
    required this.totalPhase2Count,
    required this.isForceUpdate,
    required this.species,
    required this.isEn,
  });

  final FeatureFlagsSnapshot snapshot;
  final int phase2EnabledCount;
  final int totalPhase2Count;
  final bool isForceUpdate;
  final PetSpeciesConfig species;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ownerPillBg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${species.brandName(isEn)} · ${snapshot.platform.toUpperCase()} v${snapshot.appVersion}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ownerTeal,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                isForceUpdate
                    ? (isEn ? 'Update Required' : 'ต้องอัปเดตแอป')
                    : (isEn ? 'Version OK' : 'เวอร์ชันรองรับ'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isForceUpdate
                      ? AppColors.danger
                      : AppColors.statusSafe,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isEn
                ? 'Phase 2 active: $phase2EnabledCount / $totalPhase2Count flags'
                : 'สถานะ Phase 2 ที่เปิดอยู่: $phase2EnabledCount / $totalPhase2Count รายการ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isEn
                ? 'Mock baseline ready to swap with GET /api/v1/config/flags.'
                : 'โครงสร้างแยก Logic ออกจาก UI พร้อมสลับต่อ API จริง (/api/v1/config/flags)',
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _FlagCardGroup extends StatelessWidget {
  const _FlagCardGroup({
    required this.items,
    required this.snapshot,
    required this.isEn,
    required this.onToggle,
  });

  final List<FeatureFlagMetadata> items;
  final FeatureFlagsSnapshot snapshot;
  final bool isEn;
  final Future<void> Function(AppFeatureFlag flag, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.line),
            _FlagRow(
              meta: items[i],
              enabled: snapshot.isEnabled(items[i].flag),
              isEn: isEn,
              onChanged: (val) => onToggle(items[i].flag, val),
            ),
          ],
        ],
      ),
    );
  }
}

class _FlagRow extends StatelessWidget {
  const _FlagRow({
    required this.meta,
    required this.enabled,
    required this.isEn,
    required this.onChanged,
  });

  final FeatureFlagMetadata meta;
  final bool enabled;
  final bool isEn;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.title(isEn),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta.decisionRef,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ownerTeal,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meta.description(isEn),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch.adaptive(
            value: enabled,
            activeTrackColor: AppColors.ownerTeal,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
