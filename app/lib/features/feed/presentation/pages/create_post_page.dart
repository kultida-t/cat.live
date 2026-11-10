import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_video.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/new_post.dart';
import '../../domain/policies/food_ad_policy.dart';
import '../providers/feed_controller.dart';

const _maxImages = 3;
const _maxImageMb = 10;
const _maxVideoMb = 200;
const _maxVideoSeconds = 60;
const _imageExt = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};
const _videoExt = {'mp4', 'mov', 'webm'};

const _bg = Color(0xFF14100E);
const _tile = Color(0xFF2A2320);
const _accent = Color(0xFFE8915C);

/// รูปตัวอย่างในอัลบั้ม "ล่าสุด" — ชุดเดียวกับเว็บ prototype
/// (แอปจริงต้องเปลี่ยนเป็นรูปจากอัลบั้มในเครื่องผู้ใช้)
const _sampleIds = [
  '1759588032622-1388cf9505ad',
  '1514888286974-6c03e2ca1dba',
  '1495360010541-f48722b34f7d',
  '1561948955-570b270e7c36',
  '1573865526739-10659fec78a5',
  '1478098711619-5ab0b478d6e6',
  '1574144611937-0df059b5ef3e',
  '1511044568932-338cba0ad803',
  '1571566882372-1598d88abd90',
  '1765714714461-174be7eaad85',
  '1533738363-b7f9aef128ce',
  '1764708844823-00d2188dafd8',
];

final _sampleLibrary = [
  for (final id in _sampleIds)
    DraftMedia(
      id: id,
      source: 'asset:assets/images/posts/$id.jpg',
      name: 'รูปแมว',
    ),
];

class _Platform {
  const _Platform(this.id, this.label, this.glyph, this.color);
  final String id;
  final String label;
  final String glyph;
  final Color color;
}

const _platforms = [
  _Platform('facebook', 'Facebook', 'f', Color(0xFF1877F2)),
  _Platform('instagram', 'Instagram', 'IG', Color(0xFFD6249F)),
  _Platform('line', 'LINE VOOM', 'L', Color(0xFF06C755)),
  _Platform('tiktok', 'TikTok', '♪', Color(0xFF111111)),
];

/// หน้าสร้างโพสต์ 2 ขั้น (เต็มจอ) ตามเว็บ: เลือกรูป/วิดีโอ → เขียนแคปชัน
/// ปิดหน้าด้วยรายชื่อแอปที่เลือกแชร์เพิ่ม เมื่อโพสต์สำเร็จ (null = ยกเลิก)
class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  static Future<List<String>?> open(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push<List<String>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const CreatePostPage(),
      ),
    );
  }

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage>
    with ToastMixin {
  final _picker = ImagePicker();
  final _caption = TextEditingController();

  var _details = false;
  var _video = false;
  final _picked = <DraftMedia>[];
  final _selected = <DraftMedia>[];
  String? _activeId;
  String? _error;

  final _linked = {'facebook', 'instagram'};
  final _shareTo = <String>{};
  var _shareOpen = false;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    _caption.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    disposeToast();
    _caption.dispose();
    super.dispose();
  }

  DraftMedia? get _active {
    for (final m in _selected) {
      if (m.id == _activeId) return m;
    }
    return _selected.isEmpty ? null : _selected.last;
  }

  List<DraftMedia> get _library => [
    ..._picked.where((m) => m.isVideo == _video),
    if (!_video) ..._sampleLibrary,
  ];

  bool get _looksLikeFoodAd => FoodAdPolicy.looksLikeCatFoodAd(_caption.text);

  void _setMode(bool video) {
    if (video == _video) return;
    setState(() {
      _video = video;
      _selected.clear();
      _activeId = null;
      _error = null;
    });
  }

  void _toggle(DraftMedia m) {
    setState(() {
      _error = null;
      if (m.isVideo) {
        final already = _selected.isNotEmpty && _selected.first.id == m.id;
        _selected
          ..clear()
          ..addAll(already ? const [] : [m]);
        _activeId = m.id;
        return;
      }
      final isSelected = _selected.any((s) => s.id == m.id);
      if (isSelected && _activeId != m.id) {
        _activeId = m.id;
      } else if (isSelected) {
        _selected.removeWhere((s) => s.id == m.id);
        _activeId = null;
      } else if (_selected.length >= _maxImages) {
        _error = 'เลือกได้ครั้งละไม่เกิน $_maxImages รูป';
      } else {
        _selected.add(m);
        _activeId = m.id;
      }
    });
  }

  Future<ImageSource?> _askSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF2A2320),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final (source, label, icon) in [
              (
                ImageSource.camera,
                _video ? 'ถ่ายวิดีโอ' : 'ถ่ายรูป',
                LucideIcons.camera,
              ),
              (
                ImageSource.gallery,
                _video ? 'เลือกคลิปจากเครื่อง' : 'เลือกรูปจากเครื่อง',
                LucideIcons.images,
              ),
            ])
              ListTile(
                leading: Icon(icon, color: Colors.white),
                title: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                onTap: () => Navigator.pop(context, source),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromDevice() async {
    final source = await _askSource();
    if (source == null || !mounted) return;
    try {
      final file = _video
          ? await _picker.pickVideo(
              source: source,
              maxDuration: const Duration(seconds: _maxVideoSeconds),
            )
          : await _picker.pickImage(source: source);
      if (file == null || !mounted) return;
      await _addPicked(file);
    } on Exception {
      if (mounted) {
        setState(
          () => _error =
              'เปิดกล้องหรืออัลบั้มไม่ได้ ตรวจสิทธิ์การเข้าถึงในตั้งค่า',
        );
      }
    }
  }

  Future<void> _addPicked(XFile file) async {
    final ext = file.name.split('.').last.toLowerCase();
    final video = _video;
    if (!(video ? _videoExt : _imageExt).contains(ext)) {
      return setState(
        () => _error = video
            ? 'รองรับเฉพาะ MP4, MOV, WebM'
            : 'รองรับเฉพาะ JPG, PNG, WebP, HEIC',
      );
    }
    final limitMb = video ? _maxVideoMb : _maxImageMb;
    if (await file.length() / 1048576 > limitMb) {
      return setState(() => _error = 'ไฟล์ใหญ่เกิน $limitMb MB');
    }
    double? seconds;
    if (video) {
      seconds = await _videoSeconds(file.path);
      if (seconds != null && seconds > _maxVideoSeconds + 0.5) {
        return setState(
          () => _error =
              'คลิปยาว ${seconds!.round()} วินาที เกิน $_maxVideoSeconds วินาที ตัดให้สั้นลงก่อน',
        );
      }
    }
    final media = DraftMedia(
      id: file.path,
      source: 'file:${file.path}',
      name: file.name,
      isVideo: video,
      seconds: seconds,
    );
    if (!mounted) return;
    setState(() {
      _picked.insert(0, media);
      if (video) {
        _selected
          ..clear()
          ..add(media);
        _activeId = media.id;
        _error = null;
      } else if (_selected.length < _maxImages) {
        _selected.add(media);
        _activeId = media.id;
        _error = null;
      } else {
        _error = 'เลือกได้ครั้งละไม่เกิน $_maxImages รูป';
      }
    });
  }

  Future<double?> _videoSeconds(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      return controller.value.duration.inMilliseconds / 1000;
    } on Exception {
      return null;
    } finally {
      await controller.dispose();
    }
  }

  Future<void> _submit() async {
    if (_submitting || _looksLikeFoodAd || _selected.isEmpty) return;
    setState(() => _submitting = true);
    final shareLabels = [
      for (final p in _platforms)
        if (_shareTo.contains(p.id)) p.label,
    ];
    final failure = await ref
        .read(feedControllerProvider.notifier)
        .createPost(
          NewPost(
            caption: _caption.text.trim(),
            media: List.of(_selected),
            shareTo: shareLabels,
          ),
        );
    if (!mounted) return;
    if (failure == null) {
      Navigator.pop(context, shareLabels);
    } else {
      setState(() => _submitting = false);
      showToast(failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_details && !_submitting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_submitting) setState(() => _details = false);
      },
      child: Stack(
        children: [
          _details ? _buildDetails(context) : _buildPick(context),
          if (toastMessage != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 96,
              child: IgnorePointer(
                child: Center(child: ToastPill(message: toastMessage!)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPick(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final active = _active;
    final library = _library;
    final hasVideo = _picked.any((m) => m.isVideo);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    8,
                    padding.top.clamp(12, 80),
                    8,
                    8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: 'ปิด',
                        onPressed: () => Navigator.pop(context),
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        icon: const Icon(
                          LucideIcons.x,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'โพสต์ใหม่',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: _selected.isEmpty
                            ? null
                            : () => setState(() => _details = true),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          foregroundColor: const Color(0xFFF6C9A6),
                          disabledForegroundColor: const Color(0x59FFFFFF),
                        ),
                        child: const Text(
                          'ถัดไป',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: Colors.black,
                        child: active == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    LucideIcons.image,
                                    size: 40,
                                    color: Color(0x99FFFFFF),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _video
                                        ? 'เลือก 1 คลิป ยาวไม่เกิน $_maxVideoSeconds วินาที'
                                        : 'เลือกได้สูงสุด $_maxImages รูป',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0x99FFFFFF),
                                    ),
                                  ),
                                ],
                              )
                            : active.isVideo
                            ? AppVideo(
                                key: ValueKey(active.id),
                                source: active.source,
                                autoplayLoop: true,
                              )
                            : AppImage(source: active.source),
                      ),
                      if (_selected.length > 1)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x8C000000),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.images,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_selected.length}/$_maxImages',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ล่าสุด',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _video
                            ? 'ไม่เกิน $_maxVideoSeconds วินาที'
                            : 'เลือกแล้ว ${_selected.length}/$_maxImages',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A2318),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.circleAlert,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: GridView(
                    padding: const EdgeInsets.only(bottom: 96),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                        ),
                    children: [
                      Semantics(
                        button: true,
                        label: _video
                            ? 'ถ่ายหรือเลือกวิดีโอจากเครื่อง'
                            : 'ถ่ายหรือเลือกรูปจากเครื่อง',
                        child: GestureDetector(
                          onTap: _pickFromDevice,
                          child: const ColoredBox(
                            color: _tile,
                            child: Center(
                              child: Icon(
                                LucideIcons.camera,
                                size: 28,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      for (final m in library)
                        _PickTile(
                          media: m,
                          order: _selected.indexWhere((s) => s.id == m.id),
                          video: _video,
                          onTap: () => _toggle(m),
                        ),
                      if (_video && !hasVideo)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Center(
                            child: Text(
                              'แตะกล้องเพื่อถ่ายหรือเลือกคลิปจากเครื่อง',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: Color(0x99FFFFFF),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 20 + padding.bottom,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xE63A322E),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x59000000),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (video, label) in [
                        (false, 'รูปภาพ'),
                        (true, 'วิดีโอ'),
                      ])
                        GestureDetector(
                          onTap: () => _setMode(video),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 40),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _video == video
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _video == video
                                    ? const Color(0xFF2A1C14)
                                    : const Color(0xB3FFFFFF),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final invalid = _looksLikeFoodAd;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(8, padding.top.clamp(12, 80), 8, 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'กลับไปเลือกรูป',
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _details = false),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  icon: const Icon(
                    LucideIcons.arrowLeft,
                    size: 24,
                    color: AppColors.text,
                  ),
                ),
                const Text(
                  'โพสต์ใหม่',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(width: 44, height: 44),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                SizedBox(
                  height: 132,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selected.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _DetailThumb(media: _selected[i]),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _caption,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2200,
                  buildCounter: (
                    _, {
                    required currentLength,
                    required isFocused,
                    required maxLength,
                  }) => null,
                  style: const TextStyle(fontSize: 15, color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: 'เล่าเรื่องน้องแมวของคุณ…',
                    hintStyle: const TextStyle(color: AppColors.muted),
                    filled: true,
                    fillColor: const Color(0xFFFFFBF2),
                    contentPadding: const EdgeInsets.all(12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: invalid
                            ? const Color(0xFFC2503B)
                            : AppColors.line2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: invalid
                            ? const Color(0xFFC2503B)
                            : AppColors.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (invalid)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3EF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            LucideIcons.circleAlert,
                            size: 18,
                            color: Color(0xFFC2503B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _RuleNote(
                            'ดูเหมือนโฆษณาหรือขายอาหารแมว ซึ่งทำได้เฉพาะ ',
                            bold: 'แบรนด์อาหารแมวพาร์ทเนอร์ทางการ',
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              color: Color(0xFF6B2A1E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _RuleNote(
                    'ห้ามโฆษณาหรือขายอาหารแมว · ',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.line),
                _shareToggleRow(),
                if (_shareOpen)
                  for (final p in _platforms) _platformRow(p),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + padding.bottom),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Opacity(
              opacity: invalid ? 0.4 : 1,
              child: GestureDetector(
                onTap: invalid ? null : _submit,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.btn,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.btnBorder, width: 1.5),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.ink,
                          ),
                        )
                      : const Text(
                          'แชร์',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shareToggleRow() {
    return InkWell(
      onTap: () => setState(() => _shareOpen = !_shareOpen),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.text, width: 1.7),
              ),
              child: const Icon(
                LucideIcons.arrowUpRight,
                size: 12,
                color: AppColors.text,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'แชร์เพิ่มบน…',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ),
            Text(
              _shareTo.isEmpty ? 'ปิด' : '${_shareTo.length} แอป',
              style: const TextStyle(fontSize: 13.5, color: AppColors.text2),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _shareOpen ? 0.25 : 0,
              duration: const Duration(milliseconds: 150),
              child: const Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: AppColors.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _platformRow(_Platform p) {
    final linked = _linked.contains(p.id);
    final on = _shareTo.contains(p.id);
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              p.glyph,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.label,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  linked ? 'เชื่อมต่อแล้ว' : 'ยังไม่ได้เชื่อมต่อ',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          if (linked)
            Semantics(
              toggled: on,
              label: 'แชร์ไป ${p.label}',
              child: GestureDetector(
                onTap: () => setState(
                  () => on ? _shareTo.remove(p.id) : _shareTo.add(p.id),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48,
                  height: 28,
                  decoration: BoxDecoration(
                    color: on
                        ? const Color(0xFF0F766E)
                        : const Color(0xFFD9DEDD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 150),
                    alignment: on
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Color(0x33000000), blurRadius: 2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            OutlinedButton(
              onPressed: () => setState(() => _linked.add(p.id)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                foregroundColor: AppColors.text,
                side: const BorderSide(color: AppColors.line2),
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'เชื่อมต่อ',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

String _duration(double seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).round().toString().padLeft(2, '0')}';

class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.media,
    required this.order,
    required this.video,
    required this.onTap,
  });

  final DraftMedia media;
  final int order;
  final bool video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = order >= 0;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${media.isVideo ? 'วิดีโอ' : 'รูป'} ${media.name}${selected ? ' เลือกเป็นลำดับที่ ${order + 1}' : ''}',
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: _tile,
              child: media.isVideo
                  ? const Center(
                      child: Icon(
                        LucideIcons.video,
                        size: 28,
                        color: Colors.white70,
                      ),
                    )
                  : Opacity(
                      opacity: selected ? 0.7 : 1,
                      child: AppImage(source: media.source, cacheWidth: 300),
                    ),
            ),
            if (media.seconds != null)
              Positioned(
                right: 6,
                bottom: 4,
                child: Text(
                  _duration(media.seconds!),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
                  ),
                ),
              ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? _accent : const Color(0x33000000),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: selected
                    ? (video
                          ? const Icon(
                              LucideIcons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : Text(
                              '${order + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ))
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailThumb extends StatelessWidget {
  const _DetailThumb({required this.media});

  final DraftMedia media;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 132,
        height: 132,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppColors.line,
              child: media.isVideo
                  ? const ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: Icon(
                          LucideIcons.video,
                          size: 32,
                          color: Colors.white70,
                        ),
                      ),
                    )
                  : AppImage(source: media.source, cacheWidth: 400),
            ),
            if (media.seconds != null)
              Positioned(
                right: 8,
                bottom: 6,
                child: Text(
                  _duration(media.seconds!),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ข้อความกฎ + ลิงก์ "กฎการโพสต์" (ขีดเส้นใต้ กดเปิดหน้ากฎชุมชนได้ เหมือนเว็บ)
class _RuleNote extends StatelessWidget {
  const _RuleNote(this.prefix, {required this.style, this.bold});

  final String prefix;
  final String? bold;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: prefix),
          if (bold != null)
            TextSpan(
              text: bold,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          const TextSpan(text: ' · '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => context.push('/guidelines'),
              child: const Text(
                'กฎการโพสต์',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF8F2E1E),
                  color: Color(0xFF8F2E1E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      style: style,
    );
  }
}
