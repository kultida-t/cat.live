import { NativeTabs } from 'expo-router/native-tabs';

import { CatColors } from '@/constants/theme';

export default function AppTabs() {
  return (
    <NativeTabs
      backgroundColor={CatColors.card}
      indicatorColor={CatColors.navTile}
      labelStyle={{ selected: { color: CatColors.ink } }}>
      <NativeTabs.Trigger name="index">
        <NativeTabs.Trigger.Label>หน้าแรก</NativeTabs.Trigger.Label>
        <NativeTabs.Trigger.Icon
          sf={{ default: 'house', selected: 'house.fill' }}
          md="home"
        />
      </NativeTabs.Trigger>

      <NativeTabs.Trigger name="community">
        <NativeTabs.Trigger.Label>ฟีด</NativeTabs.Trigger.Label>
        <NativeTabs.Trigger.Icon
          sf={{ default: 'square.grid.2x2', selected: 'square.grid.2x2.fill' }}
          md="grid_view"
        />
      </NativeTabs.Trigger>

      <NativeTabs.Trigger name="nearby">
        <NativeTabs.Trigger.Label>ใกล้ฉัน</NativeTabs.Trigger.Label>
        <NativeTabs.Trigger.Icon
          sf={{ default: 'map', selected: 'map.fill' }}
          md="map"
        />
      </NativeTabs.Trigger>

      <NativeTabs.Trigger name="cat-ai">
        <NativeTabs.Trigger.Label>Cat AI</NativeTabs.Trigger.Label>
        <NativeTabs.Trigger.Icon sf="sparkles" md="smart_toy" />
      </NativeTabs.Trigger>

      <NativeTabs.Trigger name="help">
        <NativeTabs.Trigger.Label>ช่วยเหลือ</NativeTabs.Trigger.Label>
        <NativeTabs.Trigger.Icon
          sf={{ default: 'lifepreserver', selected: 'lifepreserver.fill' }}
          md="support"
        />
      </NativeTabs.Trigger>

      <NativeTabs.Trigger name="my-cat">
        <NativeTabs.Trigger.Label>แมวและฉัน</NativeTabs.Trigger.Label>
        <NativeTabs.Trigger.Icon
          sf={{ default: 'pawprint', selected: 'pawprint.fill' }}
          md="pets"
        />
      </NativeTabs.Trigger>
    </NativeTabs>
  );
}
