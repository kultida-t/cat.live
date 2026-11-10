import { Ionicons } from '@expo/vector-icons';
import { useState } from 'react';
import { FlatList, Pressable, Text, View, useWindowDimensions } from 'react-native';

import { CatColors } from '@/constants/theme';
import type { Post, PostMedia } from '@/types/feed';

type Props = {
  post: Post;
  onToggleLike: (post: Post) => void;
  onToggleSave: (post: Post) => void;
  onToggleFollow: (post: Post) => void;
  onOpenMenu: (post: Post) => void;
};

/** การ์ดโพสต์สไตล์ Instagram ตาม design-spec §4.2 */
export function PostCard({ post, onToggleLike, onToggleSave, onToggleFollow, onOpenMenu }: Props) {
  const { width } = useWindowDimensions();
  const [mediaIndex, setMediaIndex] = useState(0);

  return (
    <View className="mb-3 bg-card">
      {post.type === 'lost_cat' && (
        <View className="flex-row items-center justify-between bg-danger px-4 py-2">
          <Text className="text-sm font-bold text-white">🚨 ประกาศแมวหาย</Text>
          <Text className="text-sm font-semibold text-white underline">แจ้งเบาะแส</Text>
        </View>
      )}

      <View className="flex-row items-center gap-2.5 px-4 py-3">
        <View className="h-10 w-10 items-center justify-center rounded-full border border-line bg-soft">
          <Text className="text-xl">{post.author.avatarEmoji}</Text>
        </View>
        <View className="flex-1">
          <Text className="text-sm font-bold text-ink" numberOfLines={1}>
            {post.author.handle}
            {post.author.displayName ? ` ${post.author.displayName}` : ''}
          </Text>
          {post.badgeLabel ? (
            <Text className="text-xs text-ink-muted" numberOfLines={1}>
              {post.badgeLabel}
            </Text>
          ) : null}
        </View>
        <Pressable
          onPress={() => onToggleFollow(post)}
          className={`rounded-full border px-3.5 py-1.5 ${
            post.isFollowingAuthor
              ? 'border-line bg-soft'
              : 'border-btn-border bg-btn'
          }`}>
          <Text
            className={`text-xs font-bold ${
              post.isFollowingAuthor ? 'text-ink-secondary' : 'text-ink-accent'
            }`}>
            {post.isFollowingAuthor ? 'ติดตามแล้ว' : 'ติดตาม'}
          </Text>
        </Pressable>
        <Pressable onPress={() => onOpenMenu(post)} hitSlop={8} className="p-1">
          <Ionicons name="ellipsis-horizontal" size={20} color={CatColors.inkMuted} />
        </Pressable>
      </View>

      <View>
        <FlatList
          data={post.media}
          horizontal
          pagingEnabled
          showsHorizontalScrollIndicator={false}
          keyExtractor={(_, i) => String(i)}
          onMomentumScrollEnd={(e) =>
            setMediaIndex(Math.round(e.nativeEvent.contentOffset.x / width))
          }
          renderItem={({ item }) => <MediaTile item={item} width={width} />}
        />
        {post.media.length > 1 && (
          <View className="absolute right-3 top-3 rounded-full bg-black/60 px-2.5 py-1">
            <Text className="text-xs font-semibold text-white">
              {mediaIndex + 1}/{post.media.length}
            </Text>
          </View>
        )}
      </View>

      <View className="flex-row items-center gap-4 px-4 pt-3">
        <ActionButton
          icon={post.isLiked ? 'heart' : 'heart-outline'}
          color={post.isLiked ? CatColors.danger : CatColors.ink}
          onPress={() => onToggleLike(post)}
        />
        <ActionButton icon="chatbubble-outline" color={CatColors.ink} />
        <ActionButton icon="paper-plane-outline" color={CatColors.ink} />
        <ActionButton
          icon={post.isSaved ? 'bookmark' : 'bookmark-outline'}
          color={post.isSaved ? CatColors.inkAccent : CatColors.ink}
          onPress={() => onToggleSave(post)}
        />
        <View className="flex-1" />
        <Pressable className="flex-row items-center gap-1.5 rounded-full border border-btn-border bg-btn px-3.5 py-1.5 active:opacity-80">
          <Ionicons name="fish-outline" size={15} color={CatColors.inkAccent} />
          <Text className="text-xs font-bold text-ink-accent">เลี้ยงขนม</Text>
        </Pressable>
      </View>

      <View className="gap-1 px-4 pb-4 pt-2.5">
        {post.likeCount > 0 && (
          <Text className="text-sm text-ink">
            <Text className="font-bold">{post.likedByHandle ?? 'เพื่อนแมว'}</Text>
            {' และคนอื่น ๆ ถูกใจ '}
            <Text className="font-bold">{post.likeCount.toLocaleString()}</Text>
          </Text>
        )}
        <Text className="text-sm text-ink">
          <Text className="font-bold">{post.author.handle}</Text> {post.caption}
        </Text>
        {post.previewComments.map((c) => (
          <Text key={c.authorHandle + c.body} className="text-sm text-ink-secondary">
            <Text className="font-semibold">{c.authorHandle}</Text> {c.body}
          </Text>
        ))}
        {post.commentCount > 0 && (
          <Text className="text-sm text-ink-muted">
            ดูความคิดเห็นทั้ง {post.commentCount} รายการ
          </Text>
        )}
        <Text className="text-xs text-ink-muted">{post.postedAgoText}</Text>
      </View>
    </View>
  );
}

function ActionButton({
  icon,
  color,
  onPress,
}: {
  icon: keyof typeof Ionicons.glyphMap;
  color: string;
  onPress?: () => void;
}) {
  return (
    <Pressable onPress={onPress} hitSlop={8} className="p-0.5">
      <Ionicons name={icon} size={26} color={color} />
    </Pressable>
  );
}

function MediaTile({ item, width }: { item: PostMedia; width: number }) {
  return (
    <View
      style={{ width, backgroundColor: item.mockColor }}
      className="aspect-square items-center justify-center">
      <Text className="text-5xl">{item.kind === 'video' ? '▶️' : '🐾'}</Text>
      <Text className="mt-2 px-8 text-center text-xs text-ink-muted">{item.alt}</Text>
      {item.kind === 'video' && item.durationSec ? (
        <Text className="mt-1 text-xs font-semibold text-ink-secondary">
          {item.durationSec} วินาที
        </Text>
      ) : null}
    </View>
  );
}
