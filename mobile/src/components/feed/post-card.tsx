import { Image } from 'expo-image';
import {
  Bookmark,
  Check,
  ChevronRight,
  Ellipsis,
  Gift,
  Heart,
  MapPin,
  MessageCircle,
  Send,
  type LucideIcon,
} from 'lucide-react-native';
import { memo, useRef, useState } from 'react';
import { FlatList, Pressable, View, useWindowDimensions } from 'react-native';

import { Avatar } from '@/components/ui/avatar';
import { Text } from '@/components/ui/text';
import { CatColors } from '@/constants/theme';
import type { Post } from '@/types/feed';

type Props = {
  post: Post;
  onToggleLike: (post: Post) => void;
  onToggleSave: (post: Post) => void;
  onToggleFollow: (post: Post) => void;
  onOpenMenu: (post: Post) => void;
  onComingSoon: (feature: string) => void;
};

/** การ์ดโพสต์ฟีด — layout/สี/ขนาดตามเว็บ prototype (www.แมว.live) */
function PostCardBase({
  post,
  onToggleLike,
  onToggleSave,
  onToggleFollow,
  onOpenMenu,
  onComingSoon,
}: Props) {
  const { width } = useWindowDimensions();
  const [mediaIndex, setMediaIndex] = useState(0);
  const listRef = useRef<FlatList>(null);
  const hasMany = post.media.length > 1;

  const goTo = (index: number) => {
    listRef.current?.scrollToOffset({ offset: index * width, animated: true });
    setMediaIndex(index);
  };

  return (
    <View className="border-b border-line bg-white pb-3">
      {post.type === 'lost_cat' && (
        <View className="flex-row items-center justify-between bg-danger px-3 py-2">
          <Text className="text-[13px] font-bold text-white">🚨 ประกาศแมวหาย</Text>
          <Text className="text-[13px] font-semibold text-white underline">แจ้งเบาะแส</Text>
        </View>
      )}

      <View className="flex-row items-center gap-2.5 px-3 py-2.5">
        <Avatar source={post.author.avatar} bg={post.author.avatarBg} size={36} />
        <View className="min-w-0 flex-1">
          <Text numberOfLines={1} className="text-[14px] font-semibold text-text">
            {post.author.handle}
          </Text>
          {post.subtitle ? (
            <View className="flex-row items-center gap-1">
              {post.subtitleHasPin && <MapPin size={12} color={CatColors.muted} strokeWidth={2} />}
              <Text numberOfLines={1} className="shrink text-[12px] text-muted">
                {post.subtitle}
              </Text>
            </View>
          ) : null}
        </View>
        <FollowButton following={post.isFollowingAuthor} onPress={() => onToggleFollow(post)} />
        <IconButton
          label="ตัวเลือกเพิ่มเติม"
          icon={Ellipsis}
          strokeWidth={2}
          onPress={() => onOpenMenu(post)}
        />
      </View>

      <View>
        <FlatList
          ref={listRef}
          data={post.media}
          horizontal
          pagingEnabled
          showsHorizontalScrollIndicator={false}
          keyExtractor={(_, i) => String(i)}
          onMomentumScrollEnd={(e) =>
            setMediaIndex(Math.round(e.nativeEvent.contentOffset.x / width))
          }
          renderItem={({ item }) => (
            <View style={{ width, aspectRatio: 1 }} className="bg-media">
              <Image
                source={item.source}
                accessibilityLabel={item.alt}
                style={{ width, height: width }}
                contentFit="cover"
              />
            </View>
          )}
        />
        {hasMany && (
          <>
            <View className="absolute right-3 top-3 rounded-full bg-[#4A3428]/70 px-2.5 py-0.5">
              <Text className="text-xs font-semibold text-white">
                {mediaIndex + 1}/{post.media.length}
              </Text>
            </View>
            {mediaIndex < post.media.length - 1 && (
              <Pressable
                accessibilityLabel="รูปถัดไป"
                onPress={() => goTo(mediaIndex + 1)}
                hitSlop={6}
                className="absolute right-2 top-1/2 -mt-4 h-8 w-8 items-center justify-center rounded-full bg-white/85"
                style={{
                  shadowColor: '#000',
                  shadowOpacity: 0.18,
                  shadowRadius: 4,
                  shadowOffset: { width: 0, height: 1 },
                  elevation: 2,
                }}>
                <ChevronRight size={18} color={CatColors.text} strokeWidth={2} />
              </Pressable>
            )}
            <View className="absolute inset-x-0 bottom-2.5 flex-row justify-center gap-1">
              {post.media.map((_, i) => (
                <View
                  key={i}
                  className="h-1.5 w-1.5 rounded-full"
                  style={{
                    backgroundColor: i === mediaIndex ? '#fff' : 'rgba(255,255,255,0.55)',
                  }}
                />
              ))}
            </View>
          </>
        )}
      </View>

      <View className="mt-1 flex-row items-center gap-0.5 px-1.5">
        <CountButton
          label="ถูกใจ"
          icon={Heart}
          count={post.likeCount}
          color={post.isLiked ? CatColors.heart : CatColors.text}
          filled={post.isLiked}
          onPress={() => onToggleLike(post)}
        />
        <CountButton
          label={`ความคิดเห็น ${post.commentCount} รายการ`}
          icon={MessageCircle}
          count={post.commentCount}
          color={CatColors.text}
          onPress={() => onComingSoon('ความคิดเห็น')}
        />
        <CountButton
          label="แชร์"
          icon={Send}
          count={post.shareCount}
          color={CatColors.text}
          onPress={() => onComingSoon('แชร์โพสต์')}
        />
        <IconButton
          label="บันทึก"
          icon={Bookmark}
          filled={post.isSaved}
          onPress={() => onToggleSave(post)}
        />
        <View className="flex-1" />
        <IconButton
          label={`เลี้ยงขนม ${post.author.handle}`}
          icon={Gift}
          onPress={() => onComingSoon('เลี้ยงขนม')}
        />
      </View>

      <View className="gap-1 px-3">
        <View className="flex-row items-center gap-2">
          <View className="flex-row">
            {post.likedBy.avatars.map((a, i) => (
              <View
                key={i}
                className="rounded-full border-2 border-white"
                style={{ marginLeft: i === 0 ? 0 : -8 }}>
                <Avatar source={a.source} bg={a.bg} size={22} />
              </View>
            ))}
          </View>
          <Text className="flex-1 text-[14px] text-text">
            <Text className="font-semibold">{post.likedBy.handle}</Text> และคนอื่น ๆ ถูกใจ
          </Text>
        </View>
        <Text className="text-[14px] leading-[21px] text-text">
          <Text className="font-semibold">{post.author.handle}</Text> {post.caption}
        </Text>
        {post.previewComments.map((c) => (
          <Text key={c.authorHandle + c.body} className="text-[14px] leading-[21px] text-text">
            <Text className="font-semibold">{c.authorHandle}</Text> {c.body}
          </Text>
        ))}
        {post.commentCount > 0 && (
          <Pressable className="self-start" onPress={() => onComingSoon('ความคิดเห็น')}>
            <Text className="text-[13px] text-muted">
              ดูความคิดเห็นทั้ง {post.commentCount} รายการ
            </Text>
          </Pressable>
        )}
        <Text className="text-[11px] text-muted">{post.postedAgoText}</Text>
      </View>
    </View>
  );
}

export const PostCard = memo(PostCardBase);

function FollowButton({ following, onPress }: { following: boolean; onPress: () => void }) {
  return (
    <Pressable
      onPress={onPress}
      accessibilityRole="button"
      className={`h-8 flex-row items-center justify-center gap-1.5 rounded-lg px-3 ${
        following ? 'border border-line-2 bg-white' : 'border-[1.5px] border-btn-border bg-btn'
      }`}>
      {following && <Check size={14} color={CatColors.text} strokeWidth={2} />}
      <Text className={`text-[13px] font-semibold ${following ? 'text-text' : 'text-ink'}`}>
        {following ? 'ติดตามแล้ว' : 'ติดตาม'}
      </Text>
    </Pressable>
  );
}

type IconButtonProps = {
  label: string;
  icon: LucideIcon;
  onPress: () => void;
  color?: string;
  filled?: boolean;
  strokeWidth?: number;
};

function IconButton({
  label,
  icon: Icon,
  onPress,
  color = CatColors.text,
  filled = false,
  strokeWidth = 1.8,
}: IconButtonProps) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      className="h-11 w-11 items-center justify-center rounded-xl active:bg-soft">
      <Icon size={24} color={color} fill={filled ? color : 'none'} strokeWidth={strokeWidth} />
    </Pressable>
  );
}

function CountButton({
  label,
  icon: Icon,
  count,
  color,
  filled = false,
  onPress,
}: {
  label: string;
  icon: LucideIcon;
  count: number;
  color: string;
  filled?: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      className="h-11 min-w-11 flex-row items-center justify-center gap-1 rounded-xl px-1.5 active:bg-soft">
      <Icon size={24} color={color} fill={filled ? color : 'none'} strokeWidth={1.8} />
      {count > 0 && <Text className="text-[14px] font-semibold text-text">{count}</Text>}
    </Pressable>
  );
}
