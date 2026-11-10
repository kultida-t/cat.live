import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/dio_feed_data_source.dart';
import '../../data/datasources/feed_remote_data_source.dart';
import '../../data/datasources/mock_feed_data_source.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/entities/feed_user.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/usecases/feed_usecases.dart';

/// ช่วงยังไม่มี backend ใช้ข้อมูล mock — ต่อ API จริงด้วย `--dart-define=USE_MOCK_DATA=false`
const useMockData = bool.fromEnvironment('USE_MOCK_DATA', defaultValue: true);

final dioProvider = Provider<Dio>((ref) => createApiClient());

final feedDataSourceProvider = Provider<FeedRemoteDataSource>((ref) {
  return useMockData
      ? MockFeedDataSource()
      : DioFeedDataSource(ref.watch(dioProvider));
});

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FeedRepositoryImpl(ref.watch(feedDataSourceProvider)),
);

final getFeedPageProvider = Provider(
  (ref) => GetFeedPage(ref.watch(feedRepositoryProvider)),
);
final getStoryUsersProvider = Provider(
  (ref) => GetStoryUsers(ref.watch(feedRepositoryProvider)),
);
final getAccountsProvider = Provider(
  (ref) => GetAccounts(ref.watch(feedRepositoryProvider)),
);
final toggleLikeProvider = Provider(
  (ref) => ToggleLike(ref.watch(feedRepositoryProvider)),
);
final toggleSaveProvider = Provider(
  (ref) => ToggleSave(ref.watch(feedRepositoryProvider)),
);
final toggleFollowProvider = Provider(
  (ref) => ToggleFollow(ref.watch(feedRepositoryProvider)),
);
final hidePostProvider = Provider(
  (ref) => HidePost(ref.watch(feedRepositoryProvider)),
);
final hideAccountPostsProvider = Provider(
  (ref) => HideAccountPosts(ref.watch(feedRepositoryProvider)),
);
final getPostProvider = Provider(
  (ref) => GetPost(ref.watch(feedRepositoryProvider)),
);
final createPostProvider = Provider(
  (ref) => CreatePost(ref.watch(feedRepositoryProvider)),
);
final getCommentsProvider = Provider(
  (ref) => GetComments(ref.watch(feedRepositoryProvider)),
);
final addCommentProvider = Provider(
  (ref) => AddComment(ref.watch(feedRepositoryProvider)),
);
final toggleCommentLikeProvider = Provider(
  (ref) => ToggleCommentLike(ref.watch(feedRepositoryProvider)),
);
final reportPostProvider = Provider(
  (ref) => ReportPost(ref.watch(feedRepositoryProvider)),
);
final deletePostProvider = Provider(
  (ref) => DeletePost(ref.watch(feedRepositoryProvider)),
);

final storyUsersProvider = FutureProvider<List<FeedUser>>(
  (ref) => ref.watch(getStoryUsersProvider)(),
);

/// ทะเบียนบัญชีทั้งหมด (ใช้ในหน้าแชร์เลือกคนที่จะส่งให้)
final accountsProvider = FutureProvider.autoDispose<List<FeedUser>>(
  (ref) => ref.watch(getAccountsProvider)(),
);

/// โพสต์เดี่ยวตาม id — ใช้หน้าลิงก์โพสต์ `/p/:id`
final postProvider = FutureProvider.autoDispose.family<Post, String>(
  (ref, postId) => ref.watch(getPostProvider)(postId),
);

/// ผู้ใช้ปัจจุบัน — ตอนนี้เป็นค่าคงที่เพราะยังไม่มีระบบล็อกอิน
/// เมื่อมี auth ให้เปลี่ยนมาอ่านจาก session จริง (ที่เดียวนี้ที่เดียว)
final currentUserProvider = Provider<FeedUser>(
  (ref) => const FeedUser(
    id: 'me',
    handle: 'jutamas.lk',
    avatar: 'asset:assets/images/avatars/1494790108377-be9c29b29330.jpg',
    avatarBg: 0xFFFFE89A,
    hasUnseenStory: false,
    name: 'จุฑามาศ ลูกแก้ว',
  ),
);

/// อีเมลของผู้ใช้ปัจจุบัน (ใช้ขึ้นช่อง "จาก" ตอนแชร์ทางอีเมล) — ค่าคงที่ชั่วคราวเช่นกัน
const placeholderCurrentUserEmail = 'jutamas.lk@example.com';
