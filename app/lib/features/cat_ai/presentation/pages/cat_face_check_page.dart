import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/media/strip_image_metadata.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../providers/cat_ai_controller.dart';
import '../widgets/cat_ai_l10n.dart';

enum _FaceCheckStep { pick, confirm, scan, result }

class _FacePoint {
  const _FacePoint({
    required this.key,
    required this.icon,
    required this.labelTh,
    required this.labelEn,
    required this.calmTh,
    required this.calmEn,
    required this.watchTh,
    required this.watchEn,
    required this.isWatch,
  });

  final String key;
  final IconData icon;
  final String labelTh;
  final String labelEn;
  final String calmTh;
  final String calmEn;
  final String watchTh;
  final String watchEn;
  final bool isWatch;

  String label(bool isEn) => isEn ? labelEn : labelTh;
  String calm(bool isEn) => isEn ? calmEn : calmTh;
  String watch(bool isEn) => isEn ? watchEn : watchTh;
}

const _facePoints = [
  _FacePoint(
    key: 'ears',
    icon: LucideIcons.ear,
    labelTh: 'หู',
    labelEn: 'Ears',
    calmTh: 'ตั้งตรง หันไปข้างหน้า',
    calmEn: 'Erect, facing forward',
    watchTh: 'กางออกข้างหรือลู่',
    watchEn: 'Flattened or rotated out',
    isWatch: false,
  ),
  _FacePoint(
    key: 'eyes',
    icon: LucideIcons.eye,
    labelTh: 'ตา',
    labelEn: 'Eyes',
    calmTh: 'เปิดเต็ม สดใส',
    calmEn: 'Wide open, bright',
    watchTh: 'หรี่หรือปิดครึ่ง',
    watchEn: 'Squinted or half-closed',
    isWatch: true,
  ),
  _FacePoint(
    key: 'muzzle',
    icon: LucideIcons.scanFace,
    labelTh: 'ปากและจมูก',
    labelEn: 'Muzzle',
    calmTh: 'ผ่อนคลาย กลม',
    calmEn: 'Relaxed, round',
    watchTh: 'ตึง ยื่นเป็นวงรี',
    watchEn: 'Tense, elongated oval',
    isWatch: false,
  ),
  _FacePoint(
    key: 'whiskers',
    icon: LucideIcons.cat,
    labelTh: 'หนวด',
    labelEn: 'Whiskers',
    calmTh: 'โค้งลงตามธรรมชาติ',
    calmEn: 'Curved down naturally',
    watchTh: 'ตรงแข็ง ชี้ไปข้างหน้า',
    watchEn: 'Straight, pointing forward',
    isWatch: false,
  ),
  _FacePoint(
    key: 'head',
    icon: LucideIcons.smile,
    labelTh: 'ท่าศีรษะ',
    labelEn: 'Head',
    calmTh: 'อยู่เหนือแนวไหล่',
    calmEn: 'Above shoulder line',
    watchTh: 'ก้มต่ำกว่าไหล่',
    watchEn: 'Dropped below shoulders',
    isWatch: false,
  ),
];

/// หน้าดูสีหน้า (/cat-ai/face-check) — ตรวจสัญญาณความเจ็บปวด 5 จุดบนใบหน้าแมว (UI ตัวอย่าง)
class CatFaceCheckPage extends ConsumerStatefulWidget {
  const CatFaceCheckPage({super.key, this.initialImageBytes});

  /// ใช้ส่งรูปตั้งต้นสำหรับทดสอบ flow ยืนยันและสแกนโดยไม่ต้องเปิดคลังรูปเครื่อง
  @visibleForTesting
  final Uint8List? initialImageBytes;

  @override
  ConsumerState<CatFaceCheckPage> createState() => _CatFaceCheckPageState();
}

class _CatFaceCheckPageState extends ConsumerState<CatFaceCheckPage>
    with TickerProviderStateMixin, ToastMixin {
  late _FaceCheckStep _step = widget.initialImageBytes == null
      ? _FaceCheckStep.pick
      : _FaceCheckStep.confirm;
  late Uint8List? _selectedImage = widget.initialImageBytes;
  bool _saved = false;
  Timer? _scanDoneTimer;

  late final AnimationController _scanLineCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  late final AnimationController _progressCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..addStatusListener(_onScanStatus);

  @override
  void dispose() {
    _scanDoneTimer?.cancel();
    _scanLineCtrl.dispose();
    _progressCtrl.dispose();
    disposeToast();
    super.dispose();
  }

  void _onScanStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    _scanDoneTimer?.cancel();
    _scanDoneTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted && _step == _FaceCheckStep.scan) {
        setState(() => _step = _FaceCheckStep.result);
      }
    });
  }

  Future<void> _pickImage(ImageSource source, bool isEn) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      final clean = await stripImageMetadata(await picked.readAsBytes());
      if (!mounted) return;
      setState(() {
        _selectedImage = clean;
        _saved = false;
        _step = _FaceCheckStep.confirm;
      });
    } catch (_) {
      if (mounted) showToast(CatAiL10n.imagePickFailed(isEn));
    }
  }

  void _startScan() {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _progressCtrl.duration = Duration(milliseconds: reduce ? 450 : 3600);
    setState(() => _step = _FaceCheckStep.scan);
    _progressCtrl.forward(from: 0);
  }

  void _resetToPick() {
    _scanDoneTimer?.cancel();
    _progressCtrl.stop();
    _progressCtrl.reset();
    setState(() {
      _selectedImage = null;
      _saved = false;
      _step = _FaceCheckStep.pick;
    });
  }

  Future<void> _shareResult(String catName, bool isEn) async {
    final watchLabels = _facePoints
        .where((p) => p.isWatch)
        .map((p) => p.label(isEn))
        .join(', ');
    final summary = isEn
        ? 'Cat AI Face Check ($catName): points to watch ($watchLabels) · from แมว.live'
        : 'ผล Cat AI ดูสีหน้า$catName: มีจุดที่ควรสังเกต ($watchLabels) · จาก แมว.live';
    await Clipboard.setData(ClipboardData(text: summary));
    if (mounted) showToast(CatAiL10n.faceCheckShareCopied(isEn));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catAiControllerProvider);
    final isEn = ref.watch(appLocaleProvider) == 'en';
    final cat = state.selectedCat;
    final catName = cat?.name ?? (isEn ? 'your cat' : 'น้องแมว');
    final catPhoto = cat?.avatarAsset ?? 'assets/images/hero/mali.jpg';

    return Scaffold(
      backgroundColor: AppColors.page,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.45, 1],
            colors: [AppColors.page, AppColors.page, AppColors.catAiFaceBgEnd],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _FaceCheckHeader(
                    title: CatAiL10n.faceCheckLabel(isEn),
                    onBack: () => context.pop(),
                  ),
                  Expanded(
                    child: switch (_step) {
                      _FaceCheckStep.pick => _PickBody(
                        catPhoto: catPhoto,
                        scanAnimation: _scanLineCtrl,
                        isEn: isEn,
                      ),
                      _FaceCheckStep.confirm => _ConfirmBody(
                        imageBytes: _selectedImage!,
                        isEn: isEn,
                      ),
                      _FaceCheckStep.scan => _ScanBody(
                        catName: catName,
                        imageBytes: _selectedImage!,
                        progress: _progressCtrl,
                        isEn: isEn,
                      ),
                      _FaceCheckStep.result => _ResultBody(
                        catName: catName,
                        imageBytes: _selectedImage!,
                        isEn: isEn,
                        onShare: () => _shareResult(catName, isEn),
                        onAskMore: () => context.pop(),
                      ),
                    },
                  ),
                  _buildFooter(catName, isEn),
                ],
              ),
              if (toastMessage != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 110,
                  child: Center(child: ToastPill(message: toastMessage!)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(String catName, bool isEn) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: switch (_step) {
        _FaceCheckStep.pick => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CtaPillButton(
              icon: LucideIcons.camera,
              label: CatAiL10n.faceCheckTakePhoto(catName, isEn),
              onTap: () => _pickImage(ImageSource.camera, isEn),
            ),
            const SizedBox(height: 8),
            _GhostPillButton(
              icon: LucideIcons.image,
              label: CatAiL10n.faceCheckPickGallery(isEn),
              onTap: () => _pickImage(ImageSource.gallery, isEn),
            ),
          ],
        ),
        _FaceCheckStep.confirm => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CtaPillButton(
              label: CatAiL10n.faceCheckStartScan(isEn),
              onTap: _startScan,
            ),
            const SizedBox(height: 8),
            _GhostPillButton(
              label: CatAiL10n.faceCheckChooseOther(isEn),
              onTap: _resetToPick,
            ),
          ],
        ),
        _FaceCheckStep.scan => const SizedBox.shrink(),
        _FaceCheckStep.result => Row(
          children: [
            Expanded(
              child: _OutlinePillButton(
                icon: LucideIcons.rotateCcw,
                label: CatAiL10n.faceCheckRetry(isEn),
                onTap: _resetToPick,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CtaPillButton(
                icon: _saved ? LucideIcons.check : LucideIcons.notebookPen,
                label: _saved
                    ? CatAiL10n.faceCheckSaved(isEn)
                    : CatAiL10n.faceCheckSave(isEn),
                onTap: _saved
                    ? null
                    : () {
                        setState(() => _saved = true);
                        showToast(CatAiL10n.recordSaved(isEn));
                      },
              ),
            ),
          ],
        ),
      },
    );
  }
}

class _FaceCheckHeader extends StatelessWidget {
  const _FaceCheckHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.page,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: MaterialLocalizations.of(context).backButtonTooltip,
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(22),
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
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            const SizedBox(width: 44, height: 44),
          ],
        ),
      ),
    );
  }
}

class _PickBody extends StatelessWidget {
  const _PickBody({
    required this.catPhoto,
    required this.scanAnimation,
    required this.isEn,
  });

  final String catPhoto;
  final Animation<double> scanAnimation;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.catAiScanInk.withValues(alpha: 0.18),
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      catPhoto,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CustomPaint(painter: _CornerFramePainter()),
                    ),
                  ),
                  if (!reduce)
                    AnimatedBuilder(
                      animation: scanAnimation,
                      builder: (_, _) => Positioned(
                        left: 16,
                        right: 16,
                        top: 18 + (scanAnimation.value * 160),
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: AppColors.catAiFacePurple.withValues(
                              alpha: 0.75,
                            ),
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.catAiFacePurple,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            CatAiL10n.faceCheckHeroTitle(isEn),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              CatAiL10n.faceCheckHeroSubtitle(isEn),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.text2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final p in _facePoints)
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.catAiScanBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          p.icon,
                          size: 20,
                          color: AppColors.catAiScanInk,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.label(isEn),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.25,
                          color: AppColors.text2,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfirmBody extends StatelessWidget {
  const _ConfirmBody({required this.imageBytes, required this.isEn});

  final Uint8List imageBytes;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final tips = CatAiL10n.faceCheckTips(isEn);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          Text(
            CatAiL10n.faceCheckConfirmTitle(isEn),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CatAiL10n.faceCheckConfirmSubtitle(isEn),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: AppColors.text2),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.text.withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.memory(imageBytes, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.check,
                    size: 16,
                    color: AppColors.catAiFaceGreen,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.text,
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

class _ScanBody extends StatelessWidget {
  const _ScanBody({
    required this.catName,
    required this.imageBytes,
    required this.progress,
    required this.isEn,
  });

  final String catName;
  final Uint8List imageBytes;
  final Animation<double> progress;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final steps = CatAiL10n.faceCheckScanSteps(isEn);
    return AnimatedBuilder(
      animation: progress,
      builder: (_, _) {
        final pct = (progress.value * 100).round().clamp(0, 100);
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CatAiL10n.faceCheckScanningTitle(catName, isEn),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CustomPaint(
                          painter: _ScanRingPainter(progress: progress.value),
                        ),
                      ),
                      ClipOval(
                        child: Image.memory(
                          imageBytes,
                          width: 192,
                          height: 192,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 22,
                        child: Text(
                          '$pct%',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFeatures: [FontFeature.tabularFigures()],
                            shadows: [
                              Shadow(
                                color: Color(0x73000000),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                for (var i = 0; i < steps.length; i++) ...[
                  _ScanStepPill(
                    label: steps[i],
                    done: pct >= ((i + 1) / steps.length * 100 - 1),
                    active:
                        pct < ((i + 1) / steps.length * 100 - 1) &&
                        pct >= (i / steps.length * 100),
                  ),
                  if (i < steps.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScanStepPill extends StatelessWidget {
  const _ScanStepPill({
    required this.label,
    required this.done,
    required this.active,
  });

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: active
            ? Border.all(color: AppColors.catAiFaceRingActive)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done
                  ? AppColors.catAiFaceGreen
                  : active
                  ? AppColors.catAiScanInk
                  : AppColors.soft,
              shape: BoxShape.circle,
            ),
            child: done
                ? const Icon(LucideIcons.check, size: 15, color: Colors.white)
                : active
                ? const Padding(
                    padding: EdgeInsets.all(6),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: done
                    ? AppColors.text
                    : active
                    ? AppColors.catAiScanInk
                    : AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({
    required this.catName,
    required this.imageBytes,
    required this.isEn,
    required this.onShare,
    required this.onAskMore,
  });

  final String catName;
  final Uint8List imageBytes;
  final bool isEn;
  final VoidCallback onShare;
  final VoidCallback onAskMore;

  @override
  Widget build(BuildContext context) {
    final watchPoints = _facePoints.where((p) => p.isWatch).toList();
    final watchLabels = watchPoints.map((p) => p.label(isEn)).join(', ');
    final watchDetails = watchPoints.map((p) => p.watch(isEn)).join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.text.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                    semanticLabel: isEn ? "$catName's face" : 'รูปหน้า$catName',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.catAiFaceWatchDot,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            CatAiL10n.faceCheckResultTag(isEn),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.catAiFaceWatchInk,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CatAiL10n.faceCheckResultTitle(isEn),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        CatAiL10n.faceCheckResultSummary(
                          watchLabels,
                          watchDetails,
                          isEn,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.text2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            CatAiL10n.faceCheckFivePointsTitle(isEn),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < _facePoints.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.line),
            _FacePointRow(point: _facePoints[i], isEn: isEn),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OutlinePillButton(
                  icon: LucideIcons.share2,
                  label: CatAiL10n.faceCheckShare(isEn),
                  onTap: onShare,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  button: true,
                  label: CatAiL10n.faceCheckAskMore(isEn),
                  child: InkWell(
                    onTap: onAskMore,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        CatAiL10n.faceCheckAskMore(isEn),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CatAiL10n.faceCheckDisclaimer(isEn),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _FacePointRow extends StatelessWidget {
  const _FacePointRow({required this.point, required this.isEn});

  final _FacePoint point;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final isWatch = point.isWatch;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.catAiScanBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(point.icon, size: 19, color: AppColors.catAiScanInk),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  point.label(isEn),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  isWatch ? point.watch(isEn) : point.calm(isEn),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.text2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isWatch
                  ? AppColors.catAiFaceWatchBg
                  : AppColors.catAiFaceOkBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isWatch
                  ? CatAiL10n.faceCheckStatusWatch(isEn)
                  : CatAiL10n.faceCheckStatusOk(isEn),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isWatch
                    ? AppColors.catAiFaceWatchInk
                    : AppColors.catAiFaceOkInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaPillButton extends StatelessWidget {
  const _CtaPillButton({this.icon, required this.label, required this.onTap});

  final IconData? icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.7,
        child: Material(
          color: AppColors.btn,
          shape: const StadiumBorder(
            side: BorderSide(color: AppColors.btnBorder, width: 1.5),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: AppColors.text),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostPillButton extends StatelessWidget {
  const _GhostPillButton({this.icon, required this.label, required this.onTap});

  final IconData? icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.text),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlinePillButton extends StatelessWidget {
  const _OutlinePillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white,
        shape: const StadiumBorder(side: BorderSide(color: AppColors.line2)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 17, color: AppColors.text),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// วาดกรอบเล็ง 4 มุมสีม่วงบนรูปแมว
class _CornerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const corner = 24.0;
    const stroke = 3.0;
    final paint = Paint()
      ..color = AppColors.catAiFacePurple
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(0, corner)
      ..lineTo(0, 0)
      ..lineTo(corner, 0)
      ..moveTo(w - corner, 0)
      ..lineTo(w, 0)
      ..lineTo(w, corner)
      ..moveTo(w, h - corner)
      ..lineTo(w, h)
      ..lineTo(w - corner, h)
      ..moveTo(corner, h)
      ..lineTo(0, h)
      ..lineTo(0, h - corner);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// วงกลมความคืบหน้าการสแกนสีหน้า
class _ScanRingPainter extends CustomPainter {
  _ScanRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 7.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = AppColors.catAiFaceTrack
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    final activePaint = Paint()
      ..color = AppColors.catAiFacePurple
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
