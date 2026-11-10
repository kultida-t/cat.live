import { ScrollView, Text, View } from 'react-native';

import type { FeedUser } from '@/types/feed';

/** แถว avatar บัญชีที่ติดตาม — เหนือฟีดแท็บ "ทั้งหมด" */
export function StoryRow({ users }: { users: FeedUser[] }) {
  if (users.length === 0) return null;
  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      className="border-b border-line bg-card py-3"
      contentContainerClassName="gap-4 px-4">
      {users.map((user) => (
        <View key={user.id} className="w-14 items-center gap-1">
          <View className="h-14 w-14 items-center justify-center rounded-full border-2 border-btn-border bg-soft">
            <Text className="text-2xl">{user.avatarEmoji}</Text>
          </View>
          <Text className="text-xs text-ink-secondary" numberOfLines={1}>
            {user.handle}
          </Text>
        </View>
      ))}
    </ScrollView>
  );
}
