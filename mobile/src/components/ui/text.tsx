import { Text as RNText, type TextProps } from 'react-native';

import { FontFamily } from '@/constants/theme';

type Props = TextProps & { className?: string };

function pickFamily(className: string | undefined) {
  if (!className) return FontFamily.regular;
  if (/\bfont-(bold|extrabold|black)\b/.test(className)) return FontFamily.bold;
  if (/\bfont-semibold\b/.test(className)) return FontFamily.semibold;
  if (/\bfont-medium\b/.test(className)) return FontFamily.medium;
  return FontFamily.regular;
}

/**
 * Text ของแอป — เลือกไฟล์ฟอนต์ตามคลาส font-* เพราะฟอนต์ custom
 * ต้องระบุ family แยกตามน้ำหนัก (fontWeight ปกติใช้ไม่ได้ผลบน Android)
 */
export function Text({ className, style, ...props }: Props) {
  return (
    <RNText
      {...props}
      className={className}
      style={[{ fontFamily: pickFamily(className), fontWeight: 'normal' }, style]}
    />
  );
}
