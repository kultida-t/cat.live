import { Modal, Pressable, View } from 'react-native';

import { Text } from '@/components/ui/text';

export type PostMenuAction =
  | 'not_interested'
  | 'hide_author'
  | 'copy_link'
  | 'report'
  | 'delete';

type Props = {
  visible: boolean;
  isOwnPost: boolean;
  onClose: () => void;
  onAction: (action: PostMenuAction) => void;
};

const ITEMS: { action: PostMenuAction; label: string; danger?: boolean }[] = [
  { action: 'not_interested', label: 'ไม่สนใจ' },
  { action: 'hide_author', label: 'ซ่อนโพสต์จากบัญชีนี้' },
  { action: 'copy_link', label: 'คัดลอกลิงก์' },
  { action: 'report', label: 'รายงาน', danger: true },
  { action: 'delete', label: 'ลบโพสต์', danger: true },
];

/** เมนู ··· ของโพสต์ — bottom sheet ตาม design-spec */
export function PostMenu({ visible, isOwnPost, onClose, onAction }: Props) {
  const items = ITEMS.filter((i) => i.action !== 'delete' || isOwnPost);
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <Pressable className="flex-1 justify-end bg-black/40" onPress={onClose}>
        <Pressable
          className="rounded-t-2xl bg-page pb-8 pt-2"
          onPress={(e) => e.stopPropagation()}>
          <View className="my-2 h-1 w-10 self-center rounded-full bg-unchecked" />
          {items.map((item) => (
            <Pressable
              key={item.action}
              onPress={() => onAction(item.action)}
              className="min-h-12 justify-center border-b border-line px-6 py-3.5 active:bg-soft">
              <Text
                className={`text-center text-base ${
                  item.danger ? 'font-semibold text-danger' : 'text-text'
                }`}>
                {item.label}
              </Text>
            </Pressable>
          ))}
          <Pressable onPress={onClose} className="min-h-12 justify-center px-6 py-3.5 active:bg-soft">
            <Text className="text-center text-base font-semibold text-muted">ยกเลิก</Text>
          </Pressable>
        </Pressable>
      </Pressable>
    </Modal>
  );
}
