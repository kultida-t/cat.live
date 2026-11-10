import { Image } from 'expo-image';
import { Bell, Menu, MessageCircleHeart, SquarePlus, type LucideIcon } from 'lucide-react-native';
import { useCallback, useEffect, useRef, useState } from 'react';
import { Alert, FlatList, Pressable, RefreshControl, Share, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { PostCard } from '@/components/feed/post-card';
import { PostCardSkeleton } from '@/components/feed/post-card-skeleton';
import { PostMenu, type PostMenuAction } from '@/components/feed/post-menu';
import { StoryRow } from '@/components/feed/story-row';
import { Text } from '@/components/ui/text';
import { CatColors } from '@/constants/theme';
import { feedService } from '@/services/feed-service';
import type { FeedTab, FeedUser, Post } from '@/types/feed';

const TABS: { key: FeedTab; label: string }[] = [
  { key: 'all', label: 'ทั้งหมด' },
  { key: 'following', label: 'ติดตาม' },
  { key: 'saved', label: 'บันทึกไว้' },
];

const EMPTY_TEXT: Record<FeedTab, { title: string; detail: string }> = {
  all: { title: 'ยังไม่มีโพสต์', detail: 'กลับมาดูใหม่ภายหลังนะ' },
  following: { title: 'ยังไม่ได้ติดตามใคร', detail: 'ติดตามบัญชีที่ชอบเพื่อดูโพสต์ของเขาที่นี่' },
  saved: { title: 'ยังไม่มีโพสต์ที่บันทึก', detail: 'กดปุ่มบันทึกบนโพสต์เพื่อเก็บไว้ดูภายหลัง' },
};

type LoadStatus = 'loading' | 'ready' | 'error';

const comingSoon = (feature: string) =>
  Alert.alert(feature, 'ฟีเจอร์นี้กำลังพัฒนา — จะมาในเฟสถัดไป');

export default function CommunityScreen() {
  const [tab, setTab] = useState<FeedTab>('all');
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
        const page = await feedService.fetchPosts({ tab, cursor: nextCursor.current });
        nextCursor.current = page.nextCursor;
        setPosts((prev) => (reset ? page.posts : [...prev, ...page.posts]));
        setStatus('ready');
      } catch {
        if (reset) setStatus('error');
      }
    },
    [tab],
  );

  const changeTab = (key: FeedTab) => {
    if (key === tab) return;
    setTab(key);
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

  const patchPost = useCallback(
    (updated: Post) => setPosts((prev) => prev.map((p) => (p.id === updated.id ? updated : p))),
    [],
  );

  const onToggleLike = useCallback(
    (post: Post) => {
      patchPost({ ...post, isLiked: !post.isLiked, likeCount: post.likeCount + (post.isLiked ? -1 : 1) });
      feedService.toggleLike(post.id).then(patchPost).catch(() => patchPost(post));
    },
    [patchPost],
  );

  const onToggleSave = useCallback(
    (post: Post) => {
      patchPost({ ...post, isSaved: !post.isSaved });
      feedService.toggleSave(post.id).then(patchPost).catch(() => patchPost(post));
    },
    [patchPost],
  );

  const onToggleFollow = useCallback((post: Post) => {
    setPosts((prev) =>
      prev.map((p) =>
        p.author.id === post.author.id ? { ...p, isFollowingAuthor: !post.isFollowingAuthor } : p,
      ),
    );
    feedService.toggleFollow(post.author.id).catch(() => {});
  }, []);

  const removeFromList = (postId: string) => setPosts((prev) => prev.filter((p) => p.id !== postId));

  const onMenuAction = async (action: PostMenuAction) => {
    const post = menuPost;
    setMenuPost(null);
    if (!post) return;

    switch (action) {
      case 'not_interested':
      case 'hide_author':
        removeFromList(post.id);
        await feedService.hidePost(post.id).catch(() => {});
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
              removeFromList(post.id);
              await feedService.deletePost(post.id).catch(() => {});
            },
          },
        ]);
        break;
    }
  };

  const renderPost = useCallback(
    ({ item }: { item: Post }) => (
      <PostCard
        post={item}
        onToggleLike={onToggleLike}
        onToggleSave={onToggleSave}
        onToggleFollow={onToggleFollow}
        onOpenMenu={setMenuPost}
        onComingSoon={comingSoon}
      />
    ),
    [onToggleLike, onToggleSave, onToggleFollow],
  );

  return (
    <SafeAreaView className="flex-1 bg-page" edges={['top']}>
      <View className="flex-row items-center gap-0.5 bg-page px-2 pb-1.5 pt-3">
        <HeaderButton label="เปิดเมนู" icon={Menu} onPress={() => comingSoon('เมนู')} />
        <HeaderButton
          label="สร้างโพสต์ รูปหรือวิดีโอ"
          icon={SquarePlus}
          onPress={() => comingSoon('สร้างโพสต์')}
        />
        <View className="flex-1 items-center">
          <Image
            source={require('@/assets/brand/maew-logo.png')}
            accessibilityLabel="แมว.live"
            style={{ width: 123, height: 36 }}
            contentFit="contain"
          />
        </View>
        <HeaderButton
          label="การแจ้งเตือน 3 รายการใหม่"
          icon={Bell}
          showDot
          dotRight={10}
          onPress={() => comingSoon('การแจ้งเตือน')}
        />
        <HeaderButton
          label="ข้อความ 3 รายการยังไม่อ่าน"
          icon={MessageCircleHeart}
          showDot
          dotRight={8}
          onPress={() => comingSoon('ข้อความ')}
        />
      </View>

      <View accessibilityRole="tablist" className="flex-row border-b border-line bg-page">
        {TABS.map((t) => {
          const active = tab === t.key;
          return (
            <Pressable
              key={t.key}
              accessibilityRole="tab"
              accessibilityState={{ selected: active }}
              onPress={() => changeTab(t.key)}
              className="min-h-11 flex-1 items-center justify-center">
              <Text
                className={`text-[15px] ${
                  active ? 'font-bold text-text' : 'font-medium text-muted'
                }`}>
                {t.label}
              </Text>
              {active && (
                <View className="absolute inset-x-6 bottom-0 h-[3px] rounded-full bg-ink" />
              )}
            </Pressable>
          );
        })}
      </View>

      {status === 'loading' && (
        <FlatList
          data={[0, 1, 2]}
          scrollEnabled={false}
          keyExtractor={(i) => String(i)}
          renderItem={() => <PostCardSkeleton />}
        />
      )}

      {status === 'error' && (
        <View className="flex-1 items-center justify-center p-6">
          <Text className="text-5xl">📡</Text>
          <Text className="mt-4 text-lg font-bold text-text">โหลดฟีดไม่สำเร็จ</Text>
          <Text className="mt-1 text-sm text-muted">ตรวจสัญญาณอินเทอร์เน็ตแล้วลองใหม่อีกครั้ง</Text>
          <Pressable
            onPress={() => {
              setStatus('loading');
              load(true);
            }}
            className="mt-5 min-h-11 items-center justify-center rounded-lg border-[1.5px] border-btn-border bg-btn px-8 active:opacity-80">
            <Text className="text-[15px] font-semibold text-ink">ลองใหม่</Text>
          </Pressable>
        </View>
      )}

      {status === 'ready' && (
        <FlatList
          data={posts}
          keyExtractor={(p) => p.id}
          renderItem={renderPost}
          ListHeaderComponent={tab === 'all' ? <StoryRow users={storyUsers} /> : undefined}
          ListEmptyComponent={
            <View className="items-center px-6 py-16">
              <Text className="text-5xl">🐈</Text>
              <Text className="mt-4 text-lg font-bold text-text">{EMPTY_TEXT[tab].title}</Text>
              <Text className="mt-1 text-center text-sm text-muted">{EMPTY_TEXT[tab].detail}</Text>
            </View>
          }
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={onRefresh}
              tintColor={CatColors.muted}
            />
          }
          onEndReached={onEndReached}
          onEndReachedThreshold={0.4}
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

type HeaderButtonProps = {
  label: string;
  icon: LucideIcon;
  onPress: () => void;
  showDot?: boolean;
  dotRight?: number;
};

function HeaderButton({ label, icon: Icon, onPress, showDot, dotRight = 10 }: HeaderButtonProps) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      className="h-11 w-11 items-center justify-center rounded-xl active:bg-soft">
      <Icon size={24} color={CatColors.text} strokeWidth={1.8} />
      {showDot && (
        <View
          className="absolute top-2.5 h-2.5 w-2.5 rounded-full border-2 border-white bg-heart"
          style={{ right: dotRight }}
        />
      )}
    </Pressable>
  );
}
