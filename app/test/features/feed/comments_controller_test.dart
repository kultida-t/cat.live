import 'package:catlive/core/error/failure.dart';
import 'package:catlive/features/feed/data/datasources/mock_feed_data_source.dart';
import 'package:catlive/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:catlive/features/feed/domain/entities/comment.dart';
import 'package:catlive/features/feed/domain/entities/feed_tab.dart';
import 'package:catlive/features/feed/domain/entities/new_post.dart';
import 'package:catlive/features/feed/domain/repositories/feed_repository.dart';
import 'package:catlive/features/feed/presentation/providers/comments_controller.dart';
import 'package:catlive/features/feed/presentation/providers/feed_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingWrites extends FeedRepositoryImpl {
  _FailingWrites(super.remote);

  bool fail = false;

  @override
  Future<Comment> addComment(
    String postId,
    String text, {
    String? replyToHandle,
  }) {
    if (fail) throw const NetworkFailure();
    return super.addComment(postId, text, replyToHandle: replyToHandle);
  }
}

ProviderContainer _container(FeedRepository repo) {
  final c = ProviderContainer(
    overrides: [feedRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

FeedRepositoryImpl _repo() =>
    FeedRepositoryImpl(MockFeedDataSource(latency: Duration.zero));

Future<CommentsState> _loaded(ProviderContainer c, String postId) async {
  c.listen(commentsControllerProvider(postId), (_, _) {});
  await pumpEventQueue();
  return c.read(commentsControllerProvider(postId));
}

void main() {
  test(
    'โพสต์ที่มีคอมเมนต์เด่น — คอมเมนต์เด่นมาก่อน ตามด้วยของบัญชีอื่น',
    () async {
      final c = _container(_repo());
      final state = await _loaded(c, 'p1');

      expect(state.status, CommentsStatus.ready);
      expect(state.comments.first.author.handle, 'somjeed.daily');
      expect(state.comments.first.text, 'น่ารักมากกก ขอกอดด้วย');
      // สูตรเดียวกับเว็บ: เหลือคอมเมนต์สำเร็จรูป 4 อัน (ตัดของเจ้าของโพสต์ออก)
      expect(state.comments.length, 1 + 4);
      expect(
        state.comments.any((c) => c.author.handle == 'noon.mochi'),
        isFalse,
      );
    },
  );

  test('ส่งคอมเมนต์ — โผล่ทันที (optimistic) และเพิ่มยอดในโพสต์', () async {
    final repo = _repo();
    final c = _container(repo);
    await _loaded(c, 'p3');
    final before = (await repo.getPost('p3')).commentCount;
    final notifier = c.read(commentsControllerProvider('p3').notifier);

    final pending = notifier.add('  ขอบคุณค่ะ  ');
    expect(
      c.read(commentsControllerProvider('p3')).comments.last.text,
      'ขอบคุณค่ะ',
    );
    expect(await pending, isNull);

    final last = c.read(commentsControllerProvider('p3')).comments.last;
    expect(last.id, isNot(startsWith('tmp-')));
    expect(last.author.handle, 'jutamas.lk');
    expect((await repo.getPost('p3')).commentCount, before + 1);
  });

  test('ข้อความว่าง — ไม่ส่ง', () async {
    final c = _container(_repo());
    final state = await _loaded(c, 'p3');
    final notifier = c.read(commentsControllerProvider('p3').notifier);

    expect(await notifier.add('   '), isNull);
    expect(
      c.read(commentsControllerProvider('p3')).comments.length,
      state.comments.length,
    );
  });

  test('ตอบกลับ — บันทึกชื่อผู้ถูกตอบและล้างโหมดตอบกลับ', () async {
    final c = _container(_repo());
    final state = await _loaded(c, 'p3');
    final notifier = c.read(commentsControllerProvider('p3').notifier);
    final target = state.comments.first;

    notifier.startReply(target);
    expect(c.read(commentsControllerProvider('p3')).replyTo?.id, target.id);
    await notifier.add('จริงค่ะ');

    final after = c.read(commentsControllerProvider('p3'));
    expect(after.replyTo, isNull);
    expect(after.comments.last.replyToHandle, target.author.handle);
  });

  test(
    'ส่งคอมเมนต์แล้วเน็ตหลุด — เอาคอมเมนต์ที่โชว์ไว้ออก คืน Failure',
    () async {
      final repo = _FailingWrites(MockFeedDataSource(latency: Duration.zero));
      final c = _container(repo);
      final state = await _loaded(c, 'p3');
      repo.fail = true;

      final failure = await c
          .read(commentsControllerProvider('p3').notifier)
          .add('ไม่ติด');

      expect(failure, isA<NetworkFailure>());
      expect(
        c.read(commentsControllerProvider('p3')).comments.length,
        state.comments.length,
      );
    },
  );

  test('ถูกใจคอมเมนต์ — เปลี่ยนทันที กดซ้ำคืนค่าเดิม', () async {
    final c = _container(_repo());
    final state = await _loaded(c, 'p3');
    final notifier = c.read(commentsControllerProvider('p3').notifier);
    final first = state.comments.first;

    await notifier.toggleLike(first);
    final liked = c.read(commentsControllerProvider('p3')).comments.first;
    expect(liked.isLiked, isTrue);
    expect(liked.likeCount, first.likeCount + 1);

    await notifier.toggleLike(liked);
    expect(
      c.read(commentsControllerProvider('p3')).comments.first.likeCount,
      first.likeCount,
    );
  });

  test(
    'สร้างโพสต์ — โพสต์ใหม่ของเราขึ้นก่อน ไม่มีไลก์ และเป็นของเรา',
    () async {
      final repo = _repo();
      final post = await repo.createPost(
        const NewPost(
          caption: 'ทดสอบ',
          media: [
            DraftMedia(
              id: 'a',
              source: 'asset:assets/images/posts/x.jpg',
              name: 'รูปแมว',
            ),
          ],
        ),
      );

      expect(post.isOwn, isTrue);
      expect(post.likeCount, 0);
      expect(post.author.handle, 'jutamas.lk');
      expect(post.postedAgoText, 'เมื่อสักครู่');
      final all = await repo.getPosts(tab: FeedTab.all);
      expect(all.posts.first.id, post.id);
    },
  );

  test('เปิดลิงก์โพสต์ที่ไม่มีอยู่ — NotFoundFailure', () async {
    expect(_repo().getPost('nope'), throwsA(isA<NotFoundFailure>()));
  });
}
