import { View } from 'react-native';

/** โครงโหลดการ์ดโพสต์ — ใช้แทน spinner ตามมาตรฐานแอป */
export function PostCardSkeleton() {
  return (
    <View className="mb-3 bg-card">
      <View className="flex-row items-center gap-3 px-4 py-3">
        <View className="h-10 w-10 rounded-full bg-line" />
        <View className="flex-1 gap-1.5">
          <View className="h-3.5 w-28 rounded bg-line" />
          <View className="h-3 w-16 rounded bg-line" />
        </View>
        <View className="h-7 w-16 rounded-full bg-line" />
      </View>
      <View className="aspect-square w-full bg-line" />
      <View className="gap-2 px-4 py-3">
        <View className="h-3.5 w-3/4 rounded bg-line" />
        <View className="h-3.5 w-1/2 rounded bg-line" />
      </View>
    </View>
  );
}
