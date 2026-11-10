import { LinearGradient } from 'expo-linear-gradient';
import { ScrollView, View } from 'react-native';

import { Avatar } from '@/components/ui/avatar';
import { Text } from '@/components/ui/text';
import { CatColors } from '@/constants/theme';
import type { FeedUser } from '@/types/feed';

/** แถวสตอรี่เหนือฟีด — วงแหวนฟ้า = ยังไม่ได้ดู, เทา = ดูแล้ว */
export function StoryRow({ users }: { users: FeedUser[] }) {
  if (users.length === 0) return null;
  return (
    <View className="border-b border-line bg-page">
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerClassName="gap-3.5 px-4 pb-3 pt-3">
        {users.map((user) => (
          <View key={user.id} className="w-[68px] items-center gap-1.5">
            <LinearGradient
              colors={
                user.hasUnseenStory
                  ? [CatColors.ringUnseenFrom, CatColors.ringUnseenTo]
                  : [CatColors.unchecked, CatColors.unchecked]
              }
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={{ borderRadius: 999, padding: 2.5 }}>
              <View className="rounded-full bg-white p-[2px]">
                <Avatar source={user.avatar} bg={user.avatarBg} size={56} />
              </View>
            </LinearGradient>
            <Text numberOfLines={1} className="w-full text-center text-[11.5px] text-text-2">
              {user.handle}
            </Text>
          </View>
        ))}
      </ScrollView>
    </View>
  );
}
