import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/my_cat_data.dart';
import '../providers/my_cat_controller.dart';
import '../widgets/cat_forms_sheets.dart';
import '../widgets/cat_id_card.dart';
import '../widgets/cat_id_print_sheet.dart';
import '../widgets/my_cat_l10n.dart';
import '../widgets/my_cat_skeleton.dart';

/// หน้า Cat ID (/my-cat/profile) — บัตรประจำตัวแมวเทียบตรงจากเว็บ www.แมว.live/my-cat/profile
class CatIdPage extends ConsumerStatefulWidget {
  const CatIdPage({super.key});

  @override
  ConsumerState<CatIdPage> createState() => _CatIdPageState();
}

class _CatIdPageState extends ConsumerState<CatIdPage> with ToastMixin {
  String? _selectedCatId;
  final Map<String, GlobalKey> _chipKeys = {};
  String? _lastFocusedCatId;

  @override
  void dispose() {
    disposeToast();
    super.dispose();
  }

  GlobalKey _chipKeyFor(String catId) =>
      _chipKeys.putIfAbsent(catId, GlobalKey.new);

  void _ensureChipVisible(String catId, {required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chipContext = _chipKeys[catId]?.currentContext;
      if (chipContext == null) return;
      Scrollable.ensureVisible(
        chipContext,
        alignment: 0.5,
        duration: animate ? const Duration(milliseconds: 240) : Duration.zero,
        curve: Curves.easeOutCubic,
      );
    });
  }

  CatProfile? _resolveCat(MyCatState state) {
    final cats = state.bundle?.cats ?? const [];
    if (cats.isEmpty) return null;
    final targetId = _selectedCatId ?? state.selectedCat?.id;
    if (targetId != null) {
      for (final cat in cats) {
        if (cat.id == targetId) return cat;
      }
    }
    return cats.first;
  }

  void _openShareSheet(CatProfile cat, bool isEn) {
    final displayCat = MyCatL10n.catName(cat.name, isEn);
    showShareProfileSheet(
      context,
      sheetTitle: isEn ? 'Share Cat ID' : 'แชร์ Cat ID',
      primaryLine: '$displayCat · ${cat.publicId}',
      secondaryLine:
          '${MyCatL10n.breed(cat.breed, isEn)} · ${MyCatL10n.age(cat.ageLabel, isEn)}',
      url: AppConfig.catProfileUrl(cat.publicId),
      avatarSource: cat.avatarSource,
      avatarBg: cat.avatarBg,
      isEn: isEn,
      closeOnCopy: true,
      copyNotifyMessage: isEn ? 'Cat ID shared' : 'แชร์ Cat ID แล้ว',
      onNotify: showToast,
      onSendInApp: () => showToast(
        isEn
            ? 'Messages — Coming soon in the next phase'
            : 'ข้อความ — กำลังพัฒนา จะมาในเฟสถัดไป',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myCatControllerProvider);
    final locale = ref.watch(appLocaleProvider);
    final isEn =
        locale == 'en' || state.bundle?.owner.notifications.locale == 'en';

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _CatIdHeader(
                  title: isEn ? 'Cat ID Card' : 'บัตรประจำตัวแมว',
                  backLabel: isEn ? 'Back' : 'ย้อนกลับ',
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/my-cat');
                    }
                  },
                ),
                Expanded(child: _buildBody(state, isEn)),
              ],
            ),
            if (toastMessage != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Center(child: ToastPill(message: toastMessage!)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(MyCatState state, bool isEn) {
    switch (state.status) {
      case MyCatLoadStatus.loading:
        return const MyCatSkeleton();
      case MyCatLoadStatus.error:
        return ErrorView(
          message:
              state.errorMessage ??
              (isEn
                  ? 'Unable to load Cat ID'
                  : 'โหลดข้อมูลบัตรประจำตัวแมวไม่สำเร็จ'),
          onRetry: () => ref.read(myCatControllerProvider.notifier).load(),
        );
      case MyCatLoadStatus.ready:
        final bundle = state.bundle;
        final cats = bundle?.cats ?? const <CatProfile>[];
        final activeCat = _resolveCat(state);
        if (bundle == null || activeCat == null) {
          return _EmptyCatIdView(
            isEn: isEn,
            onGoMyCat: () => context.go('/my-cat'),
          );
        }

        final skin = state.skinForCat(activeCat);
        final displayCatName = MyCatL10n.catName(activeCat.name, isEn);
        if (_lastFocusedCatId != activeCat.id) {
          final isInitial = _lastFocusedCatId == null;
          _lastFocusedCatId = activeCat.id;
          _ensureChipVisible(activeCat.id, animate: !isInitial);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // แถวสลับแมว (เลื่อนโฟกัสมาที่แคปซูลที่เลือกอยู่เสมอ)
              SizedBox(
                height: 44,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < cats.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        _CatSwitcherChip(
                          key: _chipKeyFor(cats[i].id),
                          cat: cats[i],
                          selected: cats[i].id == activeCat.id,
                          isEn: isEn,
                          onTap: () =>
                              setState(() => _selectedCatId = cats[i].id),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // บัตร Cat ID เดียวคงที่ — เปลี่ยนสี/สลับแมวด้วย morph ลื่น ๆ ไม่มีซ้อนบัตรหรือหูแว็บ
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: CatIdCard(
                  cat: activeCat,
                  ownerHandle: bundle.owner.handle,
                  skin: skin,
                  isEn: isEn,
                ),
              ),
              const SizedBox(height: 16),
              // ตัวเลือกสีบัตร 7 ธีม
              CatIdSkinSelector(
                selected: skin,
                isEn: isEn,
                onSelect: (nextSkin) => ref
                    .read(myCatControllerProvider.notifier)
                    .setCatIdSkin(activeCat.id, nextSkin),
              ),
              const SizedBox(height: 12),
              Text(
                isEn
                    ? 'Scan QR to view $displayCatName\'s public profile'
                    : 'สแกน QR เพื่อดูโปรไฟล์สาธารณะของ$displayCatName',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              // ปุ่มแชร์ Cat ID และ สั่งพิมพ์ป้าย
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: isEn ? 'Share Cat ID' : 'แชร์ Cat ID',
                      child: OutlinedButton.icon(
                        onPressed: () => _openShareSheet(activeCat, isEn),
                        icon: const Icon(LucideIcons.share2, size: 17),
                        label: Text(
                          isEn ? 'Share Cat ID' : 'แชร์ Cat ID',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          backgroundColor: AppColors.btn,
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(
                            color: AppColors.btnBorder,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: isEn ? 'Print tag' : 'สั่งพิมพ์ป้าย',
                      child: OutlinedButton.icon(
                        onPressed: () => showCatIdPrintSheet(
                          context,
                          catName: activeCat.name,
                          isEn: isEn,
                          onNotify: showToast,
                        ),
                        icon: const Icon(LucideIcons.printer, size: 17),
                        label: Text(
                          isEn ? 'Print tag' : 'สั่งพิมพ์ป้าย',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          backgroundColor: AppColors.card,
                          foregroundColor: AppColors.text,
                          side: const BorderSide(color: AppColors.line2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // กล่องคำแนะนำความเป็นส่วนตัว
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        LucideIcons.shieldCheck,
                        size: 17,
                        color: AppColors.ownerTeal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isEn
                            ? 'The public QR page shows only name, photo, and owner contact channels — never your real address or phone number (configurable in Privacy)'
                            : 'หน้าสาธารณะจาก QR แสดงแค่ชื่อ รูป และช่องทางติดต่อเจ้าของ ไม่แสดงที่อยู่หรือเบอร์โทรจริง (ตั้งค่าได้ในความเป็นส่วนตัว)',
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.38,
                          color: AppColors.text2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _CatIdHeader extends StatelessWidget {
  const _CatIdHeader({
    required this.title,
    required this.backLabel,
    required this.onBack,
  });

  final String title;
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      color: AppColors.page,
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 6),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: backLabel,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  LucideIcons.chevronLeft,
                  size: 24,
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
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatSwitcherChip extends StatelessWidget {
  const _CatSwitcherChip({
    super.key,
    required this.cat,
    required this.selected,
    required this.isEn,
    required this.onTap,
  });

  final CatProfile cat;
  final bool selected;
  final bool isEn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = MyCatL10n.catName(cat.name, isEn);
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: Material(
        color: selected ? AppColors.btn : AppColors.card,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.btnBorder : AppColors.line,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppAvatar(source: cat.avatarSource, bg: cat.avatarBg, size: 32),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.ink : AppColors.text2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCatIdView extends StatelessWidget {
  const _EmptyCatIdView({required this.isEn, required this.onGoMyCat});

  final bool isEn;
  final VoidCallback onGoMyCat;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.idCard, size: 42, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(
                isEn ? 'No Cat ID yet' : 'ยังไม่มีบัตร Cat ID',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isEn
                    ? 'Add your first cat in My Cat to generate a digital Cat ID card'
                    : 'เพิ่มแมวตัวแรกในหน้าแมวและฉันเพื่อสร้างบัตรประจำตัวแมว',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onGoMyCat,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  backgroundColor: AppColors.btn,
                  foregroundColor: AppColors.ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(
                      color: AppColors.btnBorder,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Text(
                  isEn ? 'Go to My Cat' : 'ไปหน้าแมวและฉัน',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
