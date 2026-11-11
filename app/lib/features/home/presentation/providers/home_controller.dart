import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../feed/domain/entities/feed_tab.dart';
import '../../../feed/domain/entities/post.dart';
import '../../../feed/presentation/providers/feed_controller.dart';
import '../../../feed/presentation/providers/feed_providers.dart';
import '../../domain/entities/hero_photo.dart';
import 'home_providers.dart';

enum HomeUpdatesStatus { loading, ready, error }

class HomeState {
  const HomeState({
    required this.gallery,
    this.presetIndex = 0,
    this.pinnedPhoto,
    this.autoRotate = true,
    this.updatesStatus = HomeUpdatesStatus.loading,
    this.posts = const [],
    this.errorMessage,
  });

  final HomeHeroGallery gallery;
  final int presetIndex;
  final HeroPhotoOption? pinnedPhoto;
  final bool autoRotate;
  final HomeUpdatesStatus updatesStatus;
  final List<Post> posts;
  final String? errorMessage;

  bool get isCustomSelected => pinnedPhoto != null;

  HeroPhotoOption get activeHeroPhoto {
    if (pinnedPhoto != null) return pinnedPhoto!;
    final presets = gallery.presets;
    if (presets.isEmpty) {
      return const HeroPhotoOption(
        id: 'fallback',
        imageSource: 'asset:assets/images/hero/hero-group.webp',
        semanticLabel: 'แมวหลายตัวนั่งรวมกัน',
        group: HeroPhotoGroup.preset,
      );
    }
    return presets[presetIndex % presets.length];
  }

  HomeState copyWith({
    HomeHeroGallery? gallery,
    int? presetIndex,
    Object? pinnedPhoto = _keep,
    bool? autoRotate,
    HomeUpdatesStatus? updatesStatus,
    List<Post>? posts,
    String? errorMessage,
  }) {
    return HomeState(
      gallery: gallery ?? this.gallery,
      presetIndex: presetIndex ?? this.presetIndex,
      pinnedPhoto: identical(pinnedPhoto, _keep)
          ? this.pinnedPhoto
          : pinnedPhoto as HeroPhotoOption?,
      autoRotate: autoRotate ?? this.autoRotate,
      updatesStatus: updatesStatus ?? this.updatesStatus,
      posts: posts ?? this.posts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

const _keep = Object();

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);

/// จัดการสถานะหน้าแรก: รูปแบนเนอร์/สลับอัตโนมัติ และอัปเดตจากชุมชนสูงสุด 5 โพสต์
class HomeController extends Notifier<HomeState> {
  static const _maxPreviewPosts = 5;
  static const _rotateInterval = Duration(milliseconds: 4500);

  Timer? _timer;
  int _requestId = 0;

  @override
  HomeState build() {
    final gallery = ref.read(getHomeHeroGalleryProvider)();
    ref.onDispose(() => _timer?.cancel());

    Future.microtask(_loadUpdates);
    _startTimer();

    return HomeState(gallery: gallery);
  }

  void _startTimer() {
    _timer?.cancel();
    if (!stateOrNullAutoRotate()) return;
    _timer = Timer.periodic(_rotateInterval, (_) {
      if (!ref.mounted || !state.autoRotate || state.pinnedPhoto != null) {
        return;
      }
      nextSlide();
    });
  }

  bool stateOrNullAutoRotate() {
    // ระหว่าง build() ยังไม่มี state — ค่าเริ่มต้นเป็น autoRotate = true
    try {
      return state.autoRotate;
    } catch (_) {
      return true;
    }
  }

  void nextSlide() {
    final count = state.gallery.presets.length;
    if (count == 0) return;
    state = state.copyWith(
      pinnedPhoto: null,
      presetIndex: (state.presetIndex + 1) % count,
    );
  }

  void selectPreset(HeroPhotoOption option) {
    final idx = state.gallery.presets.indexWhere((p) => p.id == option.id);
    state = state.copyWith(pinnedPhoto: null, presetIndex: idx >= 0 ? idx : 0);
    if (state.autoRotate) _startTimer();
  }

  /// เลือกรูปน้องแมวของฉัน หรือรูปที่อัปโหลดเอง → ปิดสลับรูปอัตโนมัติทันทีตามเว็บจริง
  void selectCustomPhoto(HeroPhotoOption option) {
    _timer?.cancel();
    state = state.copyWith(pinnedPhoto: option, autoRotate: false);
  }

  void setUploadedPhoto(String filePath) {
    selectCustomPhoto(
      HeroPhotoOption(
        id: 'custom-upload',
        imageSource: 'file:$filePath',
        semanticLabel: 'รูปหน้าแรกที่คุณเลือก',
        group: HeroPhotoGroup.customUpload,
      ),
    );
  }

  void setAutoRotate(bool enabled) {
    if (enabled) {
      state = state.copyWith(autoRotate: true, pinnedPhoto: null);
      _startTimer();
    } else {
      _timer?.cancel();
      state = state.copyWith(autoRotate: false);
    }
  }

  Future<void> _loadUpdates({bool keepVisible = false}) async {
    final id = ++_requestId;
    try {
      final page = await ref.read(getFeedPageProvider)(
        tab: FeedTab.all,
        cursor: 0,
      );
      if (!ref.mounted || id != _requestId) return;
      state = state.copyWith(
        updatesStatus: HomeUpdatesStatus.ready,
        posts: page.posts.take(_maxPreviewPosts).toList(),
      );
    } on Failure catch (f) {
      if (!ref.mounted || id != _requestId) return;
      if (!keepVisible) {
        state = state.copyWith(
          updatesStatus: HomeUpdatesStatus.error,
          errorMessage: f.message,
        );
      }
    }
  }

  Future<void> retry() async {
    state = state.copyWith(updatesStatus: HomeUpdatesStatus.loading);
    await _loadUpdates();
  }

  Future<void> refresh() => _loadUpdates(keepVisible: true);

  void _replace(Post updated) {
    state = state.copyWith(
      posts: [for (final p in state.posts) p.id == updated.id ? updated : p],
    );
  }

  void _refreshFeedIfLoaded() {
    ref.read(feedControllerProvider.notifier).refresh();
  }

  /// อัปเดตยอดคอมเมนต์บนการ์ดหน้าแรกทันทีเมื่อส่งหรือย้อนกลับคอมเมนต์
  void bumpCommentCount(String postId, {int by = 1}) {
    state = state.copyWith(
      posts: [
        for (final p in state.posts)
          p.id == postId
              ? p.copyWith(
                  commentCount: (p.commentCount + by).clamp(0, 1 << 30),
                )
              : p,
      ],
    );
  }

  Future<Failure?> toggleLike(Post post) async {
    final liked = !post.isLiked;
    _replace(
      post.copyWith(
        isLiked: liked,
        likeCount: post.likeCount + (liked ? 1 : -1),
      ),
    );
    try {
      final server = await ref.read(toggleLikeProvider)(post.id);
      if (ref.mounted) {
        _replace(server);
        _refreshFeedIfLoaded();
      }
      return null;
    } on Failure catch (f) {
      if (ref.mounted) _replace(post);
      return f;
    }
  }

  Future<Failure?> toggleSave(Post post) async {
    _replace(post.copyWith(isSaved: !post.isSaved));
    try {
      final server = await ref.read(toggleSaveProvider)(post.id);
      if (ref.mounted) {
        _replace(server);
        _refreshFeedIfLoaded();
      }
      return null;
    } on Failure catch (f) {
      if (ref.mounted) _replace(post);
      return f;
    }
  }

  Future<Failure?> hide(Post post) =>
      _remove(post, ref.read(hidePostProvider).call);

  Future<Failure?> hideAuthor(Post post) async {
    final before = state.posts;
    state = state.copyWith(
      posts: before.where((p) => p.author.id != post.author.id).toList(),
    );
    try {
      await ref.read(hideAccountPostsProvider)(post.author.id);
      if (ref.mounted) _refreshFeedIfLoaded();
      return null;
    } on Failure catch (f) {
      if (ref.mounted) state = state.copyWith(posts: before);
      return f;
    }
  }

  Future<Failure?> report(Post post, String reason) async {
    try {
      await ref.read(reportPostProvider)(post.id, reason);
      return null;
    } on Failure catch (f) {
      return f;
    }
  }

  Future<Failure?> delete(Post post) =>
      _remove(post, ref.read(deletePostProvider).call);

  Future<Failure?> _remove(
    Post post,
    Future<void> Function(String id) call,
  ) async {
    final before = state.posts;
    state = state.copyWith(
      posts: before.where((p) => p.id != post.id).toList(),
    );
    try {
      await call(post.id);
      if (ref.mounted) {
        await _loadUpdates(keepVisible: true);
        _refreshFeedIfLoaded();
      }
      return null;
    } on Failure catch (f) {
      if (ref.mounted) state = state.copyWith(posts: before);
      return f;
    }
  }
}
