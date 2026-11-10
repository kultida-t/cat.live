import { Image, type ImageProps } from 'expo-image';
import { View } from 'react-native';

type Props = { source: ImageProps['source']; bg: string; size: number };

/** อวตารวงกลม — รูปแมวเต็มวง สีพื้นหลังโชว์ระหว่างรอรูปโหลด */
export function Avatar({ source, bg, size }: Props) {
  return (
    <View
      className="overflow-hidden rounded-full"
      style={{ width: size, height: size, backgroundColor: bg }}>
      <Image source={source} style={{ width: size, height: size }} contentFit="cover" />
    </View>
  );
}
