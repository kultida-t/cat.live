import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/fill_icon.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/my_cat_data.dart';
import '../providers/my_cat_controller.dart';
import 'cat_forms_sheets.dart';
import 'my_cat_l10n.dart';

const _reactions = ['❤️', '🥹', '😹', '👏', '🙏'];

/// หน้าดูรูปภาพแมวแบบเต็มจอ — คง Header ที่คลีนแบบแอป + แถว Action 5 ปุ่มตรงตามเว็บ
/// (สไลด์เข้าจากขวาและปัดขอบซ้ายกลับได้)
Future<void> showCatPhotoFeedModal(
  BuildContext context, {
  required CatProfile cat,
  required int initialIndex,
  OwnerProfile? owner,
  bool isEn = false,
}) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      builder: (_) => _CatPhotoFeedPage(
        cat: cat,
        initialIndex: initialIndex,
        owner: owner,
        isEn: isEn,
      ),
    ),
  );
}

class _CatPhotoFeedPage extends ConsumerStatefulWidget {
  const _CatPhotoFeedPage({
    required this.cat,
    required this.initialIndex,
    this.owner,
    this.isEn = false,
  });

  final CatProfile cat;
  final int initialIndex;
  final OwnerProfile? owner;
  final bool isEn;

  @override
  ConsumerState<_CatPhotoFeedPage> createState() => _CatPhotoFeedPageState();
}

class _CatPhotoFeedPageState extends ConsumerState<_CatPhotoFeedPage>
    with ToastMixin {
  final _scrollController = ScrollController();

  String get _ownerHandle => widget.owner?.handle ?? 'jutamas.lk';
  String get _ownerAvatar =>
      widget.owner?.avatarSource ??
      'asset:assets/images/avatars/1494790108377-be9c29b29330.jpg';
  int get _ownerBg => widget.owner?.avatarBg ?? 0xFFFFE89A;

  @override
  void initState() {
    super.initState();
    if (widget.initialIndex > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final approxOffset = widget.initialIndex * 500.0;
        final maxScroll = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(approxOffset.clamp(0.0, maxScroll));
      });
    }
  }

  @override
  void dispose() {
    disposeToast();
    _scrollController.dispose();
    super.dispose();
  }

  CatProfile _resolveCat(MyCatState state) {
    final cats = state.bundle?.cats;
    if (cats == null) return widget.cat;
    for (final c in cats) {
      if (c.id == widget.cat.id) return c;
    }
    return widget.cat;
  }

  void _openComments(
    CatProfile cat,
    CatPhotoItem p,
    Map<String, List<CatPhotoComment>> photoComments,
  ) {
    final currentComments =
        photoComments[p.id] ?? _seedComments(p.commentCount, widget.isEn);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.sheetBarrier,
      builder: (_) => _PhotoCommentsSheet(
        ownerHandle: _ownerHandle,
        ownerAvatar: _ownerAvatar,
        ownerBg: _ownerBg,
        caption: MyCatL10n.photoCaption(p.caption, widget.isEn),
        initialComments: currentComments,
        isEn: widget.isEn,
        onCommentsUpdated: (updated) {
          ref
              .read(myCatControllerProvider.notifier)
              .setPhotoComments(cat.id, p.id, updated);
        },
      ),
    );
  }

  void _openShare(CatProfile cat, CatPhotoItem p) {
    final isEn = widget.isEn;
    final displayName = MyCatL10n.catName(cat.name, isEn);
    showShareProfileSheet(
      context,
      sheetTitle: isEn ? 'Share photo' : 'แชร์รูป',
      primaryLine: '$displayName · @${cat.publicId}',
      secondaryLine: MyCatL10n.photoCaption(p.caption, isEn),
      url: AppConfig.catProfileUrl(cat.publicId),
      avatarSource: p.imageSource,
      avatarBg: cat.avatarBg,
      isEn: isEn,
      showPrivacyNote: false,
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
    final isEn = widget.isEn;
    final state = ref.watch(myCatControllerProvider);
    final cat = _resolveCat(state);
    final photos = cat.photos;
    final notifier = ref.read(myCatControllerProvider.notifier);
    final catName = MyCatL10n.catName(cat.name, isEn);
    final breed = MyCatL10n.breed(cat.breed, isEn);

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        backgroundColor: AppColors.page,
        surfaceTintColor: Colors.transparent,
        leading: Semantics(
          button: true,
          label: isEn ? 'Back' : 'ย้อนกลับ',
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.chevronLeft),
          ),
        ),
        title: Text(
          isEn ? 'Photos · $catName' : 'รูปภาพ $catName',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView.separated(
            controller: _scrollController,
            itemCount: photos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final photo = photos[index];
              final caption = MyCatL10n.photoCaption(photo.caption, isEn);
              final timeText = MyCatL10n.relativeTime(photo.relativeTime, isEn);

              return ColoredBox(
                color: AppColors.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.btnBorder,
                            ),
                            child: AppAvatar(
                              source: cat.avatarSource,
                              bg: cat.avatarBg,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  catName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                                Text(
                                  '$breed · @${cat.publicId}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: isEn ? 'More options' : 'ตัวเลือกเพิ่มเติม',
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  LucideIcons.ellipsis,
                                  size: 18,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AspectRatio(
                      aspectRatio: 1,
                      child: AppImage(source: photo.imageSource),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
                      child: Row(
                        children: [
                          _PhotoActionButton(
                            label: isEn ? 'Like' : 'ถูกใจ',
                            icon: Icon(
                              photo.isLiked
                                  ? Icons.favorite
                                  : LucideIcons.heart,
                              size: 23,
                              color: photo.isLiked
                                  ? AppColors.heart
                                  : AppColors.text,
                            ),
                            count: photo.likeCount,
                            onTap: () =>
                                notifier.togglePhotoLike(cat.id, photo.id),
                          ),
                          _PhotoActionButton(
                            label: isEn
                                ? '${photo.commentCount} comments'
                                : 'ความคิดเห็น ${photo.commentCount} รายการ',
                            icon: const Icon(
                              LucideIcons.messageCircle,
                              size: 23,
                              color: AppColors.text,
                            ),
                            count: photo.commentCount,
                            onTap: () =>
                                _openComments(cat, photo, state.photoComments),
                          ),
                          _PhotoActionButton(
                            label: isEn
                                ? (photo.isReposted ? 'Undo repost' : 'Repost')
                                : (photo.isReposted
                                      ? 'ยกเลิกการรีโพสต์'
                                      : 'รีโพสต์'),
                            icon: Icon(
                              LucideIcons.repeat2,
                              size: 23,
                              color: photo.isReposted
                                  ? AppColors.ink
                                  : AppColors.text,
                            ),
                            count: photo.repostCount,
                            onTap: () =>
                                notifier.togglePhotoRepost(cat.id, photo.id),
                          ),
                          _PhotoActionButton(
                            label: isEn ? 'Share' : 'แชร์',
                            icon: const Icon(
                              LucideIcons.send,
                              size: 22,
                              color: AppColors.text,
                            ),
                            count: photo.shareCount,
                            onTap: () => _openShare(cat, photo),
                          ),
                          const Spacer(),
                          _PhotoActionButton(
                            label: isEn
                                ? (photo.isSaved ? 'Unsave' : 'Save')
                                : (photo.isSaved
                                      ? 'ยกเลิกการบันทึก'
                                      : 'บันทึก'),
                            icon: Icon(
                              photo.isSaved
                                  ? Icons.bookmark
                                  : LucideIcons.bookmark,
                              size: 23,
                              color: AppColors.text,
                            ),
                            onTap: () =>
                                notifier.togglePhotoSave(cat.id, photo.id),
                          ),
                        ],
                      ),
                    ),
                    if (caption.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: AppColors.text,
                            ),
                            children: [
                              TextSpan(
                                text: '$catName ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: caption),
                            ],
                          ),
                        ),
                      ),
                    if (photo.commentCount > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: GestureDetector(
                          onTap: () =>
                              _openComments(cat, photo, state.photoComments),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              isEn
                                  ? 'View all ${photo.commentCount} items'
                                  : 'ดูความคิดเห็นทั้งหมด ${photo.commentCount} รายการ',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                      child: Text(
                        timeText,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
    );
  }
}

class _PhotoActionButton extends StatelessWidget {
  const _PhotoActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.count = 0,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<CatPhotoComment> _seedComments(int count, bool isEn) {
  final pool = [
    CatPhotoComment(
      id: 'c1',
      author: 'noon.mochi',
      body: isEn ? 'So adorable 🥹' : 'น่ารักมากกก 🥹',
      time: isEn ? '2h' : '2 ชม.',
      avatar: 'asset:assets/images/avatars/1503777119540-ce54b422baff.jpg',
      avatarBg: 0xFFDCEBFF,
      likes: 12,
    ),
    CatPhotoComment(
      id: 'c2',
      author: 'maew.vetnote',
      body: isEn
          ? 'Looking so bright and healthy today!'
          : 'ตาใสสุขภาพดีมากเลยนะคะ ชอบโมเมนต์นี้',
      time: isEn ? '1h' : '1 ชม.',
      avatar: 'asset:assets/images/avatars/1543852786-1cf6624b9987.jpg',
      avatarBg: 0xFFD5F0EB,
      likes: 34,
    ),
    CatPhotoComment(
      id: 'c3',
      author: 'pim.kittenhouse',
      body: isEn
          ? 'Ours does the exact same thing haha 555'
          : 'บ้านเราก็เป็นแบบนี้เลยค่ะ 555',
      time: isEn ? '45m' : '45 นาที',
      avatar: 'asset:assets/images/avatars/1592194996308-7b43878e84a6.jpg',
      avatarBg: 0xFFEDE4FB,
      likes: 3,
    ),
    CatPhotoComment(
      id: 'c4',
      author: 'tonkla_meow',
      body: isEn
          ? 'Such a photogenic pose! ❤️'
          : 'โพสนี้มุมกล้องดีมากเลยครับ น้องน่ารักสุด ๆ ❤️',
      time: isEn ? '30m' : '30 นาที',
      avatar: 'asset:assets/images/avatars/1533738363-b7f9aef128ce.jpg',
      avatarBg: 0xFFFCE7D6,
      likes: 5,
    ),
    CatPhotoComment(
      id: 'c5',
      author: 'somjeed.daily',
      body: isEn
          ? 'Sending lots of head pats 🐾'
          : 'ขอลูบหัวน้องหน่อยน้า เอ็นดูไม่ไหว 🐾',
      time: isEn ? '12m' : '12 นาที',
      avatar: 'asset:assets/images/avatars/1596854407944-bf87f6fdd49e.jpg',
      avatarBg: 0xFFFFF1C9,
      likes: 7,
    ),
    CatPhotoComment(
      id: 'c6',
      author: 'nat_catcafe',
      body: isEn
          ? 'So sweet! Drop by our cafe anytime'
          : 'น่ารักละมุนมาก แวะมาเล่นที่ร้านได้นะคะ',
      time: isEn ? '9m' : '9 นาที',
      avatar: 'asset:assets/images/avatars/1511044568932-338cba0ad803.jpg',
      avatarBg: 0xFFFFEEF3,
      likes: 2,
    ),
    CatPhotoComment(
      id: 'c7',
      author: 'muk.ari',
      body: isEn ? 'Coat looks super glossy!' : 'ขนนุ่มเงาสวยมากเลยค่า',
      time: isEn ? '7m' : '7 นาที',
      avatar: 'asset:assets/images/avatars/1787404200329-78b2aaee13c1.jpg',
      avatarBg: 0xFFEAF3FF,
      likes: 1,
    ),
    CatPhotoComment(
      id: 'c8',
      author: 'guy.oldcat',
      body: isEn ? '10/10 cuteness' : 'ให้สิบเต็มสิบเลยครับภาพนี้',
      time: isEn ? '5m' : '5 นาที',
      avatar: 'asset:assets/images/avatars/1574144611937-0df059b5ef3e.jpg',
      avatarBg: 0xFFFFF1E6,
      likes: 4,
    ),
    CatPhotoComment(
      id: 'c9',
      author: 'rescue.bkk',
      body: isEn ? 'Lovely mood!' : 'ดูอารมณ์ดีมากเลยค่ะวันนี้ 👏',
      time: isEn ? '3m' : '3 นาที',
      avatar: 'asset:assets/images/avatars/1514888286974-6c03e2ca1dba.jpg',
      avatarBg: 0xFFD5F0EB,
      likes: 2,
    ),
  ];

  return [for (var i = 0; i < count; i++) pool[i % pool.length].copyWith()];
}

class _PhotoCommentsSheet extends StatefulWidget {
  const _PhotoCommentsSheet({
    required this.ownerHandle,
    required this.ownerAvatar,
    required this.ownerBg,
    required this.caption,
    required this.initialComments,
    required this.isEn,
    required this.onCommentsUpdated,
  });

  final String ownerHandle;
  final String ownerAvatar;
  final int ownerBg;
  final String caption;
  final List<CatPhotoComment> initialComments;
  final bool isEn;
  final ValueChanged<List<CatPhotoComment>> onCommentsUpdated;

  @override
  State<_PhotoCommentsSheet> createState() => _PhotoCommentsSheetState();
}

class _PhotoCommentsSheetState extends State<_PhotoCommentsSheet> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  late List<CatPhotoComment> _comments;
  CatPhotoComment? _replyTo;
  int _nextId = 100;

  @override
  void initState() {
    super.initState();
    _comments = List.of(widget.initialComments);
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = (preset ?? _ctrl.text).trim();
    if (text.isEmpty) return;
    if (preset == null) _ctrl.clear();
    final next = CatPhotoComment(
      id: 'new-${DateTime.now().microsecondsSinceEpoch}-${_nextId++}',
      author: widget.ownerHandle,
      body: text,
      time: widget.isEn ? 'Just now' : 'เมื่อสักครู่',
      avatar: widget.ownerAvatar,
      avatarBg: widget.ownerBg,
      likes: 0,
      replyToHandle: _replyTo?.author,
    );
    setState(() {
      _comments = [..._comments, next];
      _replyTo = null;
    });
    widget.onCommentsUpdated(_comments);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.isEn;
    final media = MediaQuery.of(context);
    final available = media.size.height - media.viewInsets.bottom;
    final bottomInset = media.padding.bottom;
    final canSend = _ctrl.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: available * 0.55,
          maxHeight: available * 0.82,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // หัวชีตแบบเดียวกับหน้าฟีด (ขีดลากบน + ความคิดเห็นตรงกลาง + X ขวา)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.line)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line2,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 40, height: 40),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: isEn ? 'Comments ' : 'ความคิดเห็น ',
                              ),
                              TextSpan(
                                text: '${_comments.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: IconButton(
                            tooltip: isEn ? 'Close' : 'ปิด',
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              LucideIcons.x,
                              size: 20,
                              color: AppColors.text2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (widget.caption.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.only(bottom: 16),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.line),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppAvatar(
                              source: widget.ownerAvatar,
                              bg: widget.ownerBg,
                              size: 34,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${widget.ownerHandle} ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(text: widget.caption),
                                  ],
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (var i = 0; i < _comments.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          top: 16,
                          left: _comments[i].replyToHandle != null ? 40 : 0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppAvatar(
                              source: _comments[i].avatar,
                              bg: _comments[i].avatarBg,
                              size: _comments[i].replyToHandle != null
                                  ? 28
                                  : 34,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${_comments[i].author} ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (_comments[i].replyToHandle != null)
                                          TextSpan(
                                            text:
                                                '@${_comments[i].replyToHandle} ',
                                            style: const TextStyle(
                                              color: AppColors.ink,
                                            ),
                                          ),
                                        TextSpan(text: _comments[i].body),
                                      ],
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.6,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  DefaultTextStyle(
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                      height: 1.5,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(_comments[i].time),
                                        if (_comments[i].likes > 0) ...[
                                          const SizedBox(width: 12),
                                          Text(
                                            isEn
                                                ? '${_comments[i].likes} likes'
                                                : 'ถูกใจ ${_comments[i].likes}',
                                          ),
                                        ],
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: () {
                                            setState(
                                              () => _replyTo = _comments[i],
                                            );
                                            _focus.requestFocus();
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              minHeight: 24,
                                            ),
                                            child: Center(
                                              child: Text(
                                                isEn ? 'Reply' : 'ตอบกลับ',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.text2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Semantics(
                              button: true,
                              label: _comments[i].liked
                                  ? (isEn
                                        ? 'Unlike comment'
                                        : 'เลิกถูกใจความคิดเห็น')
                                  : (isEn
                                        ? 'Like comment'
                                        : 'ถูกใจความคิดเห็น'),
                              child: InkResponse(
                                onTap: () {
                                  final c = _comments[i];
                                  setState(() {
                                    _comments[i] = c.copyWith(
                                      liked: !c.liked,
                                      likes: c.liked
                                          ? c.likes - 1
                                          : c.likes + 1,
                                    );
                                  });
                                  widget.onCommentsUpdated(_comments);
                                },
                                radius: 20,
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Center(
                                    child: FillIcon(
                                      shape: FillIconShape.heart,
                                      size: 15,
                                      filled: _comments[i].liked,
                                      color: _comments[i].liked
                                          ? AppColors.heart
                                          : AppColors.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 16 + bottomInset),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          for (final emoji in _reactions)
                            Semantics(
                              button: true,
                              label: isEn ? 'Send $emoji' : 'ส่ง $emoji',
                              excludeSemantics: true,
                              child: InkResponse(
                                onTap: () => _send(emoji),
                                radius: 22,
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Center(
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_replyTo != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                        decoration: BoxDecoration(
                          color: AppColors.soft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: isEn
                                          ? 'Replying to '
                                          : 'กำลังตอบกลับ ',
                                    ),
                                    TextSpan(
                                      text: _replyTo!.author,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.text2,
                                ),
                              ),
                            ),
                            InkResponse(
                              onTap: () => setState(() => _replyTo = null),
                              radius: 16,
                              child: const SizedBox(
                                width: 24,
                                height: 24,
                                child: Icon(
                                  LucideIcons.x,
                                  size: 14,
                                  color: AppColors.text2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        AppAvatar(
                          source: widget.ownerAvatar,
                          bg: widget.ownerBg,
                          size: 34,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 44),
                            padding: const EdgeInsets.only(left: 16, right: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.line2),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _ctrl,
                                    focusNode: _focus,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => _send(),
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      color: AppColors.text,
                                    ),
                                    decoration: InputDecoration(
                                      isCollapsed: true,
                                      border: InputBorder.none,
                                      hintText: isEn
                                          ? 'Comment as ${widget.ownerHandle}…'
                                          : 'แสดงความคิดเห็นถึง ${widget.ownerHandle}…',
                                      hintStyle: const TextStyle(
                                        fontSize: 14.5,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                                Opacity(
                                  opacity: canSend ? 1 : 0.35,
                                  child: IconButton(
                                    tooltip: isEn
                                        ? 'Send comment'
                                        : 'ส่งความคิดเห็น',
                                    onPressed: canSend ? _send : null,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    icon: const Icon(
                                      LucideIcons.send,
                                      size: 18,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
