import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/media/strip_image_metadata.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/my_cat_data.dart';
import '../providers/my_cat_controller.dart';
import '../widgets/cat_forms_sheets.dart';
import '../widgets/cat_photo_feed_modal.dart';
import '../widgets/cat_profile_hero.dart';
import '../widgets/cat_tabs_section.dart';
import '../widgets/my_cat_dialogs.dart';
import '../widgets/my_cat_header.dart';
import '../widgets/my_cat_l10n.dart';
import '../widgets/my_cat_skeleton.dart';
import '../widgets/owner_edit_sheet.dart';
import '../widgets/owner_profile_view.dart';
import '../widgets/profile_switcher_row.dart';

/// หน้าแมวและฉัน (/my-cat) — เทียบตรงจากเว็บต้นแบบ www.แมว.live
class MyCatPage extends ConsumerStatefulWidget {
  const MyCatPage({super.key});

  @override
  ConsumerState<MyCatPage> createState() => _MyCatPageState();
}

class _MyCatPageState extends ConsumerState<MyCatPage> with ToastMixin {
  final _picker = ImagePicker();

  @override
  void dispose() {
    disposeToast();
    super.dispose();
  }

  bool get _isEn =>
      ref.read(myCatControllerProvider).bundle?.owner.notifications.locale ==
      'en';

  void _comingSoon(String feature) => showToast(
    _isEn
        ? '$feature — Coming soon in the next phase'
        : '$feature — กำลังพัฒนา จะมาในเฟสถัดไป',
  );

  Future<String?> _pickAndStripImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked == null || !mounted) return null;
      final rawBytes = await picked.readAsBytes();
      final cleanBytes = await stripImageMetadata(rawBytes);
      final cleanFile = File(
        '${Directory.systemTemp.path}/mycat_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await cleanFile.writeAsBytes(cleanBytes, flush: true);
      return 'file:${cleanFile.path}';
    } on Exception {
      if (mounted) showToast('ไม่สามารถเปิดรูปจากอุปกรณ์ได้ในขณะนี้');
      return null;
    }
  }

  Future<void> _pickAndAddPhoto(ImageSource source) async {
    final state = ref.read(myCatControllerProvider);
    var targetCat = state.selectedCat;
    if (targetCat == null) {
      final cats = state.bundle?.cats ?? const [];
      if (cats.isEmpty) {
        showToast('กรุณาเพิ่มแมวตัวแรกก่อนเพิ่มรูป');
        return;
      }
      targetCat = cats.length == 1 ? cats.first : await _pickCatForAction(cats);
      if (targetCat == null || !mounted) return;
    }
    final cleanSource = await _pickAndStripImage(source);
    if (cleanSource == null || !mounted) return;
    final failure = await ref
        .read(myCatControllerProvider.notifier)
        .addPhotoToSelectedCat(
          imageSource: cleanSource,
          caption: 'รูปใหม่ของ${targetCat.name}',
        );
    if (!mounted) return;
    showToast(
      failure?.message ?? 'เพิ่มรูปเข้าอัลบั้มของ${targetCat.name}แล้ว',
    );
  }

  Future<CatProfile?> _pickCatForAction(List<CatProfile> cats) {
    return showModalBottomSheet<CatProfile>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'เลือกแมวที่ต้องการเพิ่มรูป',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),
              for (final cat in cats)
                ListTile(
                  onTap: () {
                    ref
                        .read(myCatControllerProvider.notifier)
                        .selectProfile(cat.id);
                    Navigator.of(ctx).pop(cat);
                  },
                  leading: AppAvatar(
                    source: cat.avatarSource,
                    bg: cat.avatarBg,
                    size: 40,
                  ),
                  title: Text(cat.name),
                  subtitle: Text(cat.breed),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCaregiverPhoto(CatCaregiver caregiver) async {
    final cleanSource = await _pickAndStripImage(ImageSource.gallery);
    if (cleanSource == null || !mounted) return;
    ref
        .read(myCatControllerProvider.notifier)
        .updateCaregiverAvatar(caregiver.id, cleanSource);
    showToast('เปลี่ยนรูปของ${caregiver.name}แล้ว');
  }

  Future<void> _openCreateMenu() async {
    final state = ref.read(myCatControllerProvider);
    final isEn = state.bundle?.owner.notifications.locale == 'en';
    final action = await showMyCatCreateSheet(
      context,
      activeCatName: state.selectedCat?.name,
      isEn: isEn,
    );
    if (action == null || !mounted) return;
    switch (action) {
      case MyCatCreateAction.photo:
        await _pickAndAddPhoto(ImageSource.gallery);
      case MyCatCreateAction.camera:
        await _pickAndAddPhoto(ImageSource.camera);
      case MyCatCreateAction.video:
        final catName = state.selectedCat?.name;
        final displayName = catName != null
            ? MyCatL10n.catName(catName, isEn)
            : null;
        _comingSoon(
          isEn
              ? (displayName != null
                    ? 'Short clip for $displayName'
                    : 'Upload short clip')
              : (catName != null
                    ? 'อัปโหลดคลิปสั้นของ$catName'
                    : 'อัปโหลดคลิปสั้น'),
        );
      case MyCatCreateAction.healthRecord:
        context.push('/my-cat/health');
      case MyCatCreateAction.addCat:
        await _openAddCatForm();
    }
  }

  Future<void> _openSettings() async {
    final owner = ref.read(myCatControllerProvider).bundle?.owner;
    if (owner == null) return;
    await showMyCatSettingsSheet(
      context,
      initial: owner.notifications,
      onSaveSettings: (next) {
        final latestOwner =
            ref.read(myCatControllerProvider).bundle?.owner ?? owner;
        ref
            .read(myCatControllerProvider.notifier)
            .updateOwner(latestOwner.copyWith(notifications: next));
      },
      onOpenTagDevice: () => context.push('/my-cat/tracker'),
      onOpenGuidelines: () => context.push('/guidelines'),
      onShowMessage: showToast,
    );
  }

  Future<void> _openAddCatForm() async {
    final bundle = ref.read(myCatControllerProvider).bundle;
    final cats = bundle?.cats ?? const [];
    final isEn = bundle?.owner.notifications.locale == 'en';
    final existingNames = cats.map((c) => c.name.trim().toLowerCase()).toSet();
    await showCatFormSheet(
      context,
      existingCatNames: existingNames,
      isEn: isEn,
      onSubmit: (draft) async {
        final (created, failure) = await ref
            .read(myCatControllerProvider.notifier)
            .addCat(draft);
        if (!mounted) return false;
        if (failure != null) {
          showToast(failure.message);
          return false;
        }
        if (created != null) {
          showToast(
            isEn
                ? 'Added "${created.name}" (@${created.publicId})'
                : 'เพิ่มโปรไฟล์ "${created.name}" แล้ว (@${created.publicId})',
          );
        }
        return true;
      },
    );
  }

  Future<void> _openEditCatForm(CatProfile cat) async {
    final bundle = ref.read(myCatControllerProvider).bundle;
    final cats = bundle?.cats ?? const [];
    final isEn = bundle?.owner.notifications.locale == 'en';
    final existingNames = cats
        .where((c) => c.id != cat.id)
        .map((c) => c.name.trim().toLowerCase())
        .toSet();
    await showCatFormSheet(
      context,
      existingCat: cat,
      existingCatNames: existingNames,
      isEn: isEn,
      onSubmit: (updated) async {
        final failure = await ref
            .read(myCatControllerProvider.notifier)
            .updateCat(updated);
        if (!mounted) return false;
        showToast(
          failure?.message ??
              (isEn
                  ? 'Saved ${updated.name}\'s profile'
                  : 'บันทึกโปรไฟล์ของ${updated.name}แล้ว'),
        );
        return failure == null;
      },
    );
  }

  Future<void> _openOwnerEdit(OwnerProfile owner) async {
    final isEn = owner.notifications.locale == 'en';
    await showOwnerEditSheet(
      context,
      owner: owner,
      isEn: isEn,
      onSave: (updated) async {
        final failure = await ref
            .read(myCatControllerProvider.notifier)
            .updateOwner(updated);
        if (!mounted) return false;
        showToast(
          failure?.message ?? (isEn ? 'Profile saved' : 'บันทึกโปรไฟล์แล้ว'),
        );
        return failure == null;
      },
    );
  }

  Future<void> _toggleCareTask(String taskId) async {
    final failure = await ref
        .read(myCatControllerProvider.notifier)
        .toggleCareTask(taskId);
    if (failure != null && mounted) showToast(failure.message);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myCatControllerProvider);
    final isEn = state.bundle?.owner.notifications.locale == 'en';
    final headerTitle = state.isOwnerSelected
        ? (isEn ? 'Me' : 'ตัวฉัน')
        : (isEn ? 'My cats' : 'แมวของฉัน');

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                MyCatHeader(
                  title: headerTitle,
                  isEn: isEn,
                  onCreateTap: _openCreateMenu,
                  onSettingsTap: _openSettings,
                ),
                Expanded(child: _buildBody(state)),
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

  Widget _buildBody(MyCatState state) {
    switch (state.status) {
      case MyCatLoadStatus.loading:
        return const MyCatSkeleton();
      case MyCatLoadStatus.error:
        return ErrorView(
          message: state.errorMessage ?? 'โหลดข้อมูลหน้าแมวและฉันไม่สำเร็จ',
          onRetry: () => ref.read(myCatControllerProvider.notifier).load(),
        );
      case MyCatLoadStatus.ready:
        final bundle = state.bundle;
        if (bundle == null) {
          return ErrorView(
            message: 'ไม่พบข้อมูลบัญชี',
            onRetry: () => ref.read(myCatControllerProvider.notifier).load(),
          );
        }
        return _buildReadyContent(state, bundle);
    }
  }

  Widget _buildReadyContent(MyCatState state, MyCatBundle bundle) {
    final selectedCat = state.selectedCat;
    final selectedId =
        state.selectedTargetId ??
        (bundle.cats.isNotEmpty ? bundle.cats.first.id : ownerTargetId);
    final isEn = bundle.owner.notifications.locale == 'en';

    return RefreshIndicator(
      color: AppColors.ink,
      onRefresh: () => ref.read(myCatControllerProvider.notifier).load(),
      child: ListView(
        children: [
          ColoredBox(
            color: AppColors.page,
            child: ProfileSwitcherRow(
              owner: bundle.owner,
              cats: bundle.cats,
              selectedTargetId: selectedId,
              isEn: isEn,
              onSelect: (id) =>
                  ref.read(myCatControllerProvider.notifier).selectProfile(id),
              onAddCat: _openAddCatForm,
            ),
          ),
          if (state.isOwnerSelected)
            OwnerProfileView(
              owner: bundle.owner,
              cats: bundle.cats,
              isEn: isEn,
              onEditProfile: () => _openOwnerEdit(bundle.owner),
              onShareProfile: () => showShareProfileSheet(
                context,
                sheetTitle: isEn ? 'Share my profile' : 'แชร์โปรไฟล์ของฉัน',
                primaryLine: MyCatL10n.ownerName(
                  bundle.owner.displayName,
                  isEn,
                ),
                secondaryLine: isEn
                    ? '@${bundle.owner.handle} · ${bundle.cats.length} cats'
                    : '@${bundle.owner.handle} · ${bundle.cats.length} แมว',
                url: '${AppConfig.webOrigin}/u/${bundle.owner.handle}',
                avatarSource: bundle.owner.avatarSource,
                avatarBg: bundle.owner.avatarBg,
                isEn: isEn,
                onNotify: showToast,
                onSendInApp: () => _comingSoon(isEn ? 'Messages' : 'ข้อความ'),
              ),
              onOpenVerification: () => showVerificationTrustSheet(
                context,
                owner: bundle.owner,
                isEn: isEn,
                onOpenEditProfile: () => _openOwnerEdit(bundle.owner),
              ),
              onOpenMessages: () => _comingSoon(isEn ? 'Messages' : 'ข้อความ'),
              onSelectCat: (catId) => ref
                  .read(myCatControllerProvider.notifier)
                  .selectProfile(catId),
            )
          else if (selectedCat == null)
            _EmptyCatsView(isEn: isEn, onAddCat: _openAddCatForm)
          else ...[
            CatProfileHero(
              cat: selectedCat,
              isEn: isEn,
              onOpenHealth: () => context.push('/my-cat/health'),
              onOpenCatId: () => context.push('/my-cat/profile'),
              onOpenTracker: () => context.push('/my-cat/tracker'),
              onShare: () => showShareProfileSheet(
                context,
                sheetTitle: isEn
                    ? 'Share profile ${MyCatL10n.catName(selectedCat.name, true)}'
                    : 'แชร์โปรไฟล์${selectedCat.name}',
                primaryLine:
                    '${MyCatL10n.catName(selectedCat.name, isEn)} · ${selectedCat.publicId}',
                secondaryLine:
                    '${MyCatL10n.breed(selectedCat.breed, isEn)} · ${MyCatL10n.age(selectedCat.ageLabel, isEn)}',
                url: AppConfig.catProfileUrl(selectedCat.publicId),
                avatarSource: selectedCat.avatarSource,
                avatarBg: selectedCat.avatarBg,
                isEn: isEn,
                onNotify: showToast,
                onSendInApp: () => _comingSoon(isEn ? 'Messages' : 'ข้อความ'),
              ),
              onEdit: () => _openEditCatForm(selectedCat),
            ),
            CatTabsSection(
              cat: selectedCat,
              activeTab: state.activeTab,
              isEn: isEn,
              onSelectTab: (tab) =>
                  ref.read(myCatControllerProvider.notifier).selectTab(tab),
              onPhotoTap: (index) => showCatPhotoFeedModal(
                context,
                cat: selectedCat,
                initialIndex: index,
                owner: bundle.owner,
                isEn: isEn,
              ),
              onToggleCareTask: _toggleCareTask,
              onFindClinic: () => context.go('/nearby'),
              onOpenAllHealth: () => context.push('/my-cat/health'),
              onCaregiverAvatarTap: _pickCaregiverPhoto,
              onInviteCaregiver: () => showInviteCaregiverSheet(
                context,
                ownerName: bundle.owner.displayName,
                cat: selectedCat,
                isEn: isEn,
                onNotify: showToast,
                onSendInApp: () => _comingSoon(isEn ? 'Messages' : 'ข้อความ'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCatsView extends StatelessWidget {
  const _EmptyCatsView({required this.onAddCat, this.isEn = false});

  final VoidCallback onAddCat;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            const Icon(LucideIcons.cat, size: 42, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              isEn ? 'No cat profiles yet' : 'ยังไม่มีโปรไฟล์แมว',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isEn
                  ? 'Add your first cat to start health logs and Cat ID'
                  : 'เพิ่มแมวตัวแรกเพื่อเริ่มบันทึกสุขภาพและสร้าง Cat ID',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAddCat,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(
                isEn ? 'Add your first cat' : 'เพิ่มแมวตัวแรก',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
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
            ),
          ],
        ),
      ),
    );
  }
}
