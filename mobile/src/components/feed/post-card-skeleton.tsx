import { View } from 'react-native';

/** โครงโหลดการ์ดโพสต์ — ใช้แทน spinner ตามมาตรฐานแอป */
export function PostCardSkeleton() {
  return (
    <View className="border-b border-line bg-white pb-3">
      <View className="flex-row items-center gap-2.5 px-3 py-2.5">
        <View className="h-9 w-9 rounded-full bg-soft" />
        <View className="flex-1 gap-1.5">
          <View className="h-3.5 w-28 rounded bg-soft" />
          <View className="h-3 w-16 rounded bg-soft" />
        </View>
        <View className="h-8 w-20 rounded-lg bg-soft" />
      </View>
      <View className="aspect-square w-full bg-media" />
      <View className="gap-2 px-3 pt-3">
        <View className="h-3.5 w-3/4 rounded bg-soft" />
        <View className="h-3.5 w-1/2 rounded bg-soft" />
      </View>
    </View>
  );
}
