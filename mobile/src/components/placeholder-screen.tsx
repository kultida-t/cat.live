import { ScrollView, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Text } from '@/components/ui/text';

type PlaceholderScreenProps = {
  title: string;
  subtitle: string;
  notes?: string[];
};

export function PlaceholderScreen({ title, subtitle, notes }: PlaceholderScreenProps) {
  return (
    <SafeAreaView className="flex-1 bg-page" edges={['top']}>
      <ScrollView className="flex-1" contentContainerClassName="p-4 gap-4 pb-6">
        <View className="gap-1">
          <Text className="text-2xl font-bold text-text">{title}</Text>
          <Text className="text-base text-muted">{subtitle}</Text>
        </View>

        <View className="rounded-2xl border border-line bg-white p-4">
          <Text className="text-base text-text-2">
            หน้าจอนี้อยู่ระหว่างพอร์ตจากเว็บ prototype — โครงสร้างแอปพร้อมแล้ว
            จะทยอยใส่เนื้อหาจริงทีละจอตาม design-spec
          </Text>
        </View>

        {notes?.map((note) => (
          <View key={note} className="rounded-xl border border-line bg-soft p-3">
            <Text className="text-sm text-text-2">{note}</Text>
          </View>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}
