import { ScrollView, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

type PlaceholderScreenProps = {
  title: string;
  subtitle: string;
  notes?: string[];
};

export function PlaceholderScreen({ title, subtitle, notes }: PlaceholderScreenProps) {
  return (
    <SafeAreaView className="flex-1 bg-page" edges={['top']}>
      <ScrollView className="flex-1" contentContainerClassName="p-4 gap-4 pb-28">
        <View className="gap-1">
          <Text className="text-2xl font-bold text-ink">{title}</Text>
          <Text className="text-base text-ink-muted">{subtitle}</Text>
        </View>

        <View className="bg-card border border-line rounded-card-lg p-4">
          <Text className="text-base text-ink-secondary">
            หน้าจอนี้อยู่ระหว่างพอร์ตจากเว็บ prototype — โครงสร้างแอปพร้อมแล้ว
            จะทยอยใส่เนื้อหาจริงทีละจอตาม design-spec
          </Text>
        </View>

        {notes?.map((note) => (
          <View
            key={note}
            className="bg-soft border border-line rounded-card p-3">
            <Text className="text-sm text-ink-secondary">{note}</Text>
          </View>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}
