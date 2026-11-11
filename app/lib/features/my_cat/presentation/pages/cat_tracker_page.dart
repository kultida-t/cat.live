import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/my_cat_data.dart';
import '../providers/my_cat_controller.dart';
import '../widgets/cat_tracker_device_panel.dart';
import '../widgets/cat_tracker_map.dart';
import '../widgets/cat_tracker_sheet.dart';
import '../widgets/my_cat_l10n.dart';
import '../widgets/my_cat_skeleton.dart';

/// หน้าตามหาแมว (/my-cat/tracker และ ?device=1) — เทียบตรงจาก www.แมว.live/my-cat/tracker
class CatTrackerPage extends ConsumerStatefulWidget {
  const CatTrackerPage({
    super.key,
    this.initialDeviceMode = false,
    this.tileProvider,
  });

  final bool initialDeviceMode;
  final TileProvider? tileProvider;

  @override
  ConsumerState<CatTrackerPage> createState() => _CatTrackerPageState();
}

class _CatTrackerPageState extends ConsumerState<CatTrackerPage>
    with ToastMixin {
  String? _selectedCatId;
  bool _isFullscreen = false;
  late bool _isDeviceMode = widget.initialDeviceMode;
  String? _selectedTagCatId;
  String? _playingSoundCatId;
  Timer? _soundTimer;

  @override
  void didUpdateWidget(covariant CatTrackerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDeviceMode != oldWidget.initialDeviceMode) {
      _isDeviceMode = widget.initialDeviceMode;
      _selectedTagCatId = null;
      if (_isDeviceMode) _isFullscreen = false;
    }
  }

  @override
  void dispose() {
    _soundTimer?.cancel();
    disposeToast();
    super.dispose();
  }

  void _stopSound() {
    _soundTimer?.cancel();
    _soundTimer = null;
    if (_playingSoundCatId != null) {
      setState(() => _playingSoundCatId = null);
    }
  }

  void _toggleSound(CatProfile cat, bool isEn) {
    if (_playingSoundCatId == cat.id) {
      _stopSound();
      return;
    }
    _soundTimer?.cancel();
    final name = MyCatL10n.catName(cat.name, isEn);
    setState(() => _playingSoundCatId = cat.id);
    showToast(
      isEn
          ? "$name's collar is playing a sound (demo)"
          : 'ปลอกคอของ$nameกำลังส่งเสียง (จำลอง)',
    );
    _soundTimer = Timer(const Duration(milliseconds: 4500), () {
      if (mounted) setState(() => _playingSoundCatId = null);
    });
  }

  Future<void> _openDirections(CatProfile cat, bool isEn) async {
    final info = cat.trackerInfo;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${info.latitude},${info.longitude}&travelmode=walking',
    );
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        showToast(
          isEn
              ? 'Unable to open maps app right now'
              : 'ไม่สามารถเปิดแอปแผนที่ได้ในขณะนี้',
        );
      }
    } on Exception {
      if (mounted) {
        showToast(
          isEn
              ? 'Unable to open maps app right now'
              : 'ไม่สามารถเปิดแอปแผนที่ได้ในขณะนี้',
        );
      }
    }
  }

  CatProfile? _findCat(List<CatProfile> cats, String? id) {
    if (id == null) return null;
    for (final c in cats) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myCatControllerProvider);
    final locale = ref.watch(appLocaleProvider);
    final isEn =
        locale == 'en' || state.bundle?.owner.notifications.locale == 'en';
    final cats = state.bundle?.cats ?? const <CatProfile>[];
    final activeCat = _findCat(cats, _selectedCatId);
    final headerCat = activeCat ?? (cats.isNotEmpty ? cats.first : null);

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _TrackerHeader(
                  title: isEn ? 'Find my cat' : 'ตามหาแมว',
                  backLabel: isEn ? 'Back' : 'ย้อนกลับ',
                  settingsLabel: headerCat == null
                      ? (isEn ? 'Device settings' : 'ตั้งค่าอุปกรณ์')
                      : (isEn
                            ? 'Device settings for ${MyCatL10n.catName(headerCat.name, true)}'
                            : 'ตั้งค่าอุปกรณ์ของ${headerCat.name}'),
                  isDeviceMode: _isDeviceMode,
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/my-cat');
                    }
                  },
                  onToggleSettings: () {
                    setState(() {
                      _isDeviceMode = !_isDeviceMode;
                      _selectedTagCatId = null;
                      if (_isDeviceMode) _isFullscreen = false;
                    });
                  },
                ),
                Expanded(child: _buildBody(state, cats, activeCat, isEn)),
              ],
            ),
            if (toastMessage != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Center(child: ToastPill(message: toastMessage!)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    MyCatState state,
    List<CatProfile> cats,
    CatProfile? activeCat,
    bool isEn,
  ) {
    switch (state.status) {
      case MyCatLoadStatus.loading:
        return const MyCatSkeleton();
      case MyCatLoadStatus.error:
        return ErrorView(
          message:
              state.errorMessage ??
              (isEn
                  ? 'Unable to load tracker data'
                  : 'โหลดข้อมูลติดตามแมวไม่สำเร็จ'),
          onRetry: () => ref.read(myCatControllerProvider.notifier).load(),
        );
      case MyCatLoadStatus.ready:
        if (cats.isEmpty) {
          return _EmptyTrackerView(
            isEn: isEn,
            onGoMyCat: () => context.go('/my-cat'),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final totalH = constraints.maxHeight;
            final normalMapH = (totalH * 0.42).clamp(220.0, 340.0);
            final collapsedBarH = 112.0;
            final mapHeight = _isFullscreen
                ? (totalH - collapsedBarH + 20).clamp(240.0, totalH)
                : normalMapH;
            final sheetTop = _isFullscreen
                ? (totalH - collapsedBarH).clamp(160.0, totalH - 80)
                : (normalMapH - 20);

            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  top: 0,
                  left: 0,
                  right: 0,
                  height: mapHeight,
                  child: CatTrackerMap(
                    cats: cats,
                    selectedCat: activeCat,
                    isFullscreen: _isFullscreen,
                    isEn: isEn,
                    tileProvider: widget.tileProvider,
                    onToggleFullscreen: (full) => setState(() {
                      _isFullscreen = full;
                      if (full) _isDeviceMode = false;
                    }),
                    onSelectCat: (cat) => setState(() {
                      _selectedCatId = cat.id;
                      _isDeviceMode = false;
                      _isFullscreen = false;
                    }),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  top: sheetTop,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(26),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1F4A3428),
                          blurRadius: 24,
                          offset: Offset(0, -8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(26),
                      ),
                      child: Column(
                        children: [
                          // ขีดจับด้านบนของชีต
                          const SizedBox(height: 8),
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.line2,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _isFullscreen
                                ? _FullscreenCollapsedSheetBar(
                                    isEn: isEn,
                                    onExpand: () =>
                                        setState(() => _isFullscreen = false),
                                  )
                                : SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      14,
                                      16,
                                      44,
                                    ),
                                    child: _buildSheetContent(
                                      cats: cats,
                                      activeCat: activeCat,
                                      isEn: isEn,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
    }
  }

  Widget _buildSheetContent({
    required List<CatProfile> cats,
    required CatProfile? activeCat,
    required bool isEn,
  }) {
    final controller = ref.read(myCatControllerProvider.notifier);

    if (_isDeviceMode) {
      return CatTrackerDevicePanel(
        cats: cats,
        selectedTagCatId: _selectedTagCatId,
        backTargetName: activeCat?.name,
        isEn: isEn,
        onBackToTracker: () => setState(() {
          _isDeviceMode = false;
          _selectedTagCatId = null;
        }),
        onSelectTagCat: (catId) => setState(() => _selectedTagCatId = catId),
        onUpdateDevice: (catId, updater) => controller.updateTrackerInfo(
          catId,
          (info) => info.device == null
              ? info
              : info.copyWith(device: updater(info.device!)),
        ),
        onBuyTagForCat: (cat) {
          final name = MyCatL10n.catName(cat.name, isEn);
          showToast(
            isEn
                ? 'Buy tag for $name — Coming soon in the next phase'
                : 'เลือกซื้อแท็กสำหรับ$name — กำลังพัฒนา จะมาในเฟสถัดไป',
          );
        },
        onNotify: showToast,
      );
    }

    if (activeCat != null) {
      final name = MyCatL10n.catName(activeCat.name, isEn);
      return CatTrackerCatDetailContent(
        cat: activeCat,
        isEn: isEn,
        isPlayingSound: _playingSoundCatId == activeCat.id,
        onClose: () {
          _stopSound();
          setState(() => _selectedCatId = null);
        },
        onToggleSound: () => _toggleSound(activeCat, isEn),
        onDirections: () => _openDirections(activeCat, isEn),
        onChangeRadius: (radius) => controller.updateTrackerInfo(
          activeCat.id,
          (info) => info.copyWith(safeZoneRadiusMeters: radius),
        ),
        onToggleAlertLeaveZone: (val) => controller.updateTrackerInfo(
          activeCat.id,
          (info) => info.copyWith(alertOnLeaveZone: val),
        ),
        onToggleLostMode: (val) {
          controller.updateTrackerInfo(
            activeCat.id,
            (info) => info.copyWith(lostMode: val),
          );
          if (val) {
            showToast(
              isEn
                  ? 'Lost mode enabled for $name'
                  : 'เปิดโหมดแมวหายของ$nameแล้ว',
            );
          }
        },
        onToggleShowContact: (val) => controller.updateTrackerInfo(
          activeCat.id,
          (info) => info.copyWith(showContactNumber: val),
        ),
        onToggleShareCommunity: (val) => controller.updateTrackerInfo(
          activeCat.id,
          (info) => info.copyWith(shareWithCommunity: val),
        ),
        onPostMissing: () => showToast(
          isEn
              ? 'Missing alert for $name (Help) — Coming soon in the next phase'
              : 'ประกาศตามหา$name (หน้าช่วยเหลือ) — กำลังพัฒนา จะมาในเฟสถัดไป',
        ),
        onInviteHelper: () =>
            showToast(isEn ? 'Invite sent (demo)' : 'ส่งคำเชิญแล้ว (จำลอง)'),
        onBuyTag: () => showToast(
          isEn
              ? 'แมว.live Tag store — Coming soon in the next phase'
              : 'ร้านค้า แมว.live Tag — กำลังพัฒนา จะมาในเฟสถัดไป',
        ),
        onConnectCollar: () => showToast(
          isEn
              ? 'Scan the QR on the collar to connect (demo)'
              : 'สแกน QR บนปลอกคอเพื่อเชื่อมต่อ (จำลอง)',
        ),
      );
    }

    return CatTrackerCatsListContent(
      cats: cats,
      isEn: isEn,
      onSelectCat: (cat) {
        _stopSound();
        setState(() => _selectedCatId = cat.id);
      },
    );
  }
}

class _TrackerHeader extends StatelessWidget {
  const _TrackerHeader({
    required this.title,
    required this.backLabel,
    required this.settingsLabel,
    required this.isDeviceMode,
    required this.onBack,
    required this.onToggleSettings,
  });

  final String title;
  final String backLabel;
  final String settingsLabel;
  final bool isDeviceMode;
  final VoidCallback onBack;
  final VoidCallback onToggleSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      color: AppColors.page,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: backLabel,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(14),
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
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          Semantics(
            button: true,
            toggled: isDeviceMode,
            label: settingsLabel,
            child: InkWell(
              onTap: onToggleSettings,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  LucideIcons.settings2,
                  size: 22,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenCollapsedSheetBar extends StatelessWidget {
  const _FullscreenCollapsedSheetBar({
    required this.isEn,
    required this.onExpand,
  });

  final bool isEn;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isEn ? 'My cats' : 'แมวของฉัน',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: isEn ? 'Show list' : 'ดูรายการ',
            child: InkWell(
              onTap: onExpand,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEn ? 'Show list' : 'ดูรายการ',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      LucideIcons.chevronUp,
                      size: 16,
                      color: AppColors.text2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTrackerView extends StatelessWidget {
  const _EmptyTrackerView({required this.isEn, required this.onGoMyCat});

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
              const Icon(LucideIcons.mapPin, size: 42, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(
                isEn ? 'No cats to track yet' : 'ยังไม่มีแมวที่ติดตาม',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isEn
                    ? 'Add your first cat in My Cat to track their location and safe zone'
                    : 'เพิ่มแมวตัวแรกในหน้าแมวและฉันเพื่อเริ่มติดตามตำแหน่งและเขตปลอดภัย',
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
