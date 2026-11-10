import { Ionicons } from '@expo/vector-icons';
import { useCallback, useEffect, useRef, useState } from 'react';
import {
  Alert,
  FlatList,
  Pressable,
  RefreshControl,
  ScrollView,
  Share,
  Text,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { PostCard } from '@/components/feed/post-card';
import { PostCardSkeleton } from '@/components/feed/post-card-skeleton';
import { PostMenu, type PostMenuAction } from '@/components/feed/post-menu';
import { StoryRow } from '@/components/feed/story-row';
import { CatColors } from '@/constants/theme';
import { FEED_CATEGORIES } from '@/data/mock-feed';
import { feedService } from '@/services/feed-service';
import type { FeedTab, FeedUser, Post } from '@/types/feed';

const TABS: { key: FeedTab; label: string }[] = [
  { key: 'all', label: 'ทั้งหมด' },
  { key: 'following', label: 'ติดตาม' },
  { key: 'saved', label: 'บันทึกไว้' },
];

const EMPTY_TEXT: Record<FeedTab, { title: string; detail: string }> = {
  all: { title: 'ยังไม่มีโพสต์', detail: 'ลองเปลี่ยนหมวด หรือกลับมาใหม่ภายหลัง' },
  following: { title: 'ยังไม่ได้ติดตามใคร', detail: 'ติดตามบัญชีที่ชอบเพื่อดูโพสต์ของเขาที่นี่' },
  saved: { title: 'ยังไม่มีโพสต์ที่บันทึก', detail: 'กดปุ่มเซฟบนโพสต์เพื่อเก็บไว้ดูภายหลัง' },
};

type LoadStatus = 'loading' | 'ready' | 'error';

export default function CommunityScreen() {
  const [tab, setTab] = useState<FeedTab>('all');
  const [category, setCategory] = useState<string>('ทั้งหมด');
  const [status, setStatus] = useState<LoadStatus>('loading');
  const [posts, setPosts] = useState<Post[]>([]);
  const [storyUsers, setStoryUsers] = useState<FeedUser[]>([]);
  const [refreshing, setRefreshing] = useState(false);
  const [menuPost, setMenuPost] = useState<Post | null>(null);
  const nextCursor = useRef<number | undefined>(0);
  const loadingMore = useRef(false);

  const load = useCallback(
    async (reset: boolean) => {
      if (reset) nextCursor.current = 0;
      try {
        const page = await feedService.fetchPosts({
          tab,
          category,
          cursor: nextCursor.current,
        });
        nextCursor.current = page.nextCursor;
        setPosts((prev) => (reset ? page.posts : [...prev, ...page.posts]));
        setStatus('ready');
      } catch {
        if (reset) setStatus('error');
      }
    },
    [tab, category],
  );

  const changeTab = (key: FeedTab) => {
    setTab(key);
    setStatus('loading');
  };

  const changeCategory = (name: string) => {
    setCategory(name);
    setStatus('loading');
  };

  useEffect(() => {
    load(true);
  }, [load]);

  useEffect(() => {
    feedService.fetchStoryUsers().then(setStoryUsers).catch(() => {});
  }, []);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await load(true);
    setRefreshing(false);
  }, [load]);

  const onEndReached = useCallback(async () => {
    if (loadingMore.current || nextCursor.current === undefined) return;
    loadingMore.current = true;
    await load(false);
    loadingMore.current = false;
  }, [load]);

  const patchPost = (updated: Post) =>
    setPosts((prev) => prev.map((p) => (p.id === updated.id ? updated : p)));

  const onToggleLike = (post: Post) => {
    patchPost({ ...post, isLiked: !post.isLiked, likeCount: post.likeCount + (post.isLiked ? -1 : 1) });
    feedService.toggleLike(post.id).then(patchPost).catch(() => patchPost(post));
  };

  const onToggleSave = (post: Post) => {
    patchPost({ ...post, isSaved: !post.isSaved });
    feedService.toggleSave(post.id).then(patchPost).catch(() => patchPost(post));
  };

  const onToggleFollow = (post: Post) => {
    feedService
      .toggleFollow(post.author.id)
      .then((all) =>
        setPosts((prev) =>
          prev.map((p) => {
            const fresh = all.find((f) => f.id === p.id);
            return fresh ?? p;
          }),
        ),
      )
      .catch(() => {});
  };

  const onMenuAction = async (action: PostMenuAction) => {
    const post = menuPost;
    setMenuPost(null);
    if (!post) return;

    switch (action) {
      case 'not_interested':
      case 'hide_author':
        await feedService.hidePost(post.id).catch(() => {});
        setPosts((prev) => prev.filter((p) => p.id !== post.id));
        break;
      case 'copy_link':
        Share.share({ message: `https://แมว.live/p/${post.id}` }).catch(() => {});
        break;
      case 'report':
        Alert.alert('รายงานโพสต์', 'เลือกเหตุผลที่ต้องการรายงาน', [
          { text: 'สแปมหรือโฆษณา', onPress: () => feedService.reportPost(post.id, 'spam') },
          { text: 'เนื้อหาไม่เหมาะสม', onPress: () => feedService.reportPost(post.id, 'inappropriate') },
          { text: 'ทารุณสัตว์', onPress: () => feedService.reportPost(post.id, 'animal_abuse') },
          { text: 'ยกเลิก', style: 'cancel' },
        ]);
        break;
      case 'delete':
        Alert.alert('ลบโพสต์', 'ลบโพสต์นี้ถาวร ไม่สามารถกู้คืนได้', [
          { text: 'ยกเลิก', style: 'cancel' },
          {
            text: 'ลบ',
            style: 'destructive',
            onPress: async () => {
              await feedService.deletePost(post.id).catch(() => {});
              setPosts((prev) => prev.filter((p) => p.id !== post.id));
            },
          },
        ]);
        break;
    }
  };

  return (
    <SafeAreaView className="flex-1 bg-page" edges={['top']}>
      <View className="flex-row items-center justify-between border-b border-line bg-card px-4 py-2.5">
        <Text className="text-xl font-black text-ink">แมว.live</Text>
        <Pressable
          hitSlop={8}
          onPress={() => Alert.alert('สร้างโพสต์', 'หน้าสร้างโพสต์กำลังพัฒนา — จะมาในเฟสถัดไป')}>
          <Ionicons name="create-outline" size={24} color={CatColors.ink} />
        </Pressable>
      </View>

      <View className="flex-row border-b border-line bg-card">
        {TABS.map((t) => (
          <Pressable
            key={t.key}
            onPress={() => changeTab(t.key)}
            className={`flex-1 items-center border-b-2 py-2.5 ${
              tab === t.key ? 'border-ink-accent' : 'border-transparent'
            }`}>
            <Text
              className={`text-sm ${
                tab === t.key ? 'font-bold text-ink' : 'text-ink-muted'
              }`}>
              {t.label}
            </Text>
          </Pressable>
        ))}
      </View>

      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        className="max-h-12 border-b border-line bg-card"
        contentContainerClassName="items-center gap-2 px-4">
        {FEED_CATEGORIES.map((c) => (
          <Pressable
            key={c}
            onPress={() => changeCategory(c)}
            className={`rounded-full border px-3.5 py-1.5 ${
              category === c ? 'border-btn-border bg-soft' : 'border-line bg-card'
            }`}>
            <Text
              className={`text-xs ${
                category === c ? 'font-bold text-ink' : 'text-ink-muted'
              }`}>
              {c}
            </Text>
          </Pressable>
        ))}
      </ScrollView>

      {status === 'loading' && (
        <View>
          <PostCardSkeleton />
          <PostCardSkeleton />
          <PostCardSkeleton />
        </View>
      )}

      {status === 'error' && (
        <View className="flex-1 items-center justify-center p-6">
          <Text className="text-5xl">📡</Text>
          <Text className="mt-4 text-lg font-bold text-ink">โหลดฟีดไม่สำเร็จ</Text>
          <Text className="mt-1 text-sm text-ink-muted">
            ตรวจสัญญาณอินเทอร์เน็ตแล้วลองใหม่อีกครั้ง
          </Text>
          <Pressable
            onPress={() => load(true)}
            className="mt-5 rounded-xl border border-btn-border bg-btn px-8 py-3 active:opacity-80">
            <Text className="font-bold text-ink-accent">ลองใหม่</Text>
          </Pressable>
        </View>
      )}

      {status === 'ready' && (
        <FlatList
          data={posts}
          keyExtractor={(p) => p.id}
          renderItem={({ item }) => (
            <PostCard
              post={item}
              onToggleLike={onToggleLike}
              onToggleSave={onToggleSave}
              onToggleFollow={onToggleFollow}
              onOpenMenu={setMenuPost}
            />
          )}
          ListHeaderComponent={
            tab === 'all' && category === 'ทั้งหมด' ? (
              <StoryRow users={storyUsers} />
            ) : undefined
          }
          ListEmptyComponent={
            <View className="items-center px-6 py-16">
              <Text className="text-5xl">🐈</Text>
              <Text className="mt-4 text-lg font-bold text-ink">
                {EMPTY_TEXT[tab].title}
              </Text>
              <Text className="mt-1 text-center text-sm text-ink-muted">
                {EMPTY_TEXT[tab].detail}
              </Text>
            </View>
          }
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={onRefresh}
              tintColor={CatColors.inkMuted}
            />
          }
          onEndReached={onEndReached}
          onEndReachedThreshold={0.4}
          contentContainerClassName="pb-28 pt-3"
        />
      )}

      <PostMenu
        visible={menuPost !== null}
        isOwnPost={menuPost?.isOwn ?? false}
        onClose={() => setMenuPost(null)}
        onAction={onMenuAction}
      />
    </SafeAreaView>
  );
}
