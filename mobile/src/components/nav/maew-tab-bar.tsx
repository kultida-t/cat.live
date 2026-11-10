import type { BottomTabBarProps } from 'expo-router/js-tabs';
import { Pressable, View } from 'react-native';

import { Text } from '@/components/ui/text';
import { CatColors } from '@/constants/theme';

import { NavIcon, type NavIconName } from './nav-icons';

type TabMeta = { label: string; icon: NavIconName; pill: string };

/** แท็บล่าง 6 อัน เรียงตามเว็บ prototype พร้อมสีแคปซูลของแต่ละแท็บ */
const TAB_META: Record<string, TabMeta> = {
  index: { label: 'หน้าแรก', icon: 'home', pill: '#DCEBFF' },
  community: { label: 'ฟีด', icon: 'feed', pill: '#DCEBFF' },
  nearby: { label: 'ใกล้ฉัน', icon: 'nearby', pill: '#D5F0EB' },
  'cat-ai': { label: 'Cat AI', icon: 'ai', pill: '#EDE4FB' },
  help: { label: 'ช่วยเหลือ', icon: 'help', pill: '#FDE2EC' },
  'my-cat': { label: 'แมวและฉัน', icon: 'mycat', pill: '#FFF1E6' },
};

export function MaewTabBar({ state, emitter, navigateToTab, insets }: BottomTabBarProps) {
  return (
    <View
      className="flex-row border-t border-line px-1.5 pt-1.5"
      style={{
        backgroundColor: CatColors.navBackground,
        paddingBottom: insets.bottom + 10,
        shadowColor: '#4A3428',
        shadowOffset: { width: 0, height: -6 },
        shadowOpacity: 0.06,
        shadowRadius: 20,
      }}>
      {state.routes.map((route, index) => {
        const meta = TAB_META[route.name];
        if (!meta) return null;
        const focused = state.index === index;

        const onPress = () => {
          const event = emitter.emit({
            type: 'tabPress',
            target: route.key,
            canPreventDefault: true,
          });
          if (!focused && !event.defaultPrevented) navigateToTab(route.key);
        };

        return (
          <Pressable
            key={route.key}
            accessibilityRole="button"
            accessibilityLabel={meta.label}
            accessibilityState={{ selected: focused }}
            onPress={onPress}
            className="min-h-[58px] flex-1 items-center justify-center gap-0.5 rounded-2xl">
            <View className="h-[34px] w-[50px] items-center justify-center">
              {focused && (
                <View
                  className="absolute inset-0 rounded-full"
                  style={{ backgroundColor: meta.pill }}
                />
              )}
              <NavIcon name={meta.icon} active={focused} />
            </View>
            <Text
              numberOfLines={1}
              className={`text-[11px] leading-[17px] ${focused ? 'font-bold' : 'font-medium'}`}
              style={{ color: focused ? CatColors.ink : CatColors.muted }}>
              {meta.label}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}
