import {
  IBMPlexSansThaiLooped_400Regular,
  IBMPlexSansThaiLooped_500Medium,
  IBMPlexSansThaiLooped_600SemiBold,
  IBMPlexSansThaiLooped_700Bold,
  useFonts,
} from '@expo-google-fonts/ibm-plex-sans-thai-looped';
import { DefaultTheme, ThemeProvider } from 'expo-router';
import { Tabs } from 'expo-router/js-tabs';
import * as SplashScreen from 'expo-splash-screen';
import { StatusBar } from 'expo-status-bar';
import { useEffect } from 'react';

import { ScreenErrorBoundary } from '@/components/error-boundary';
import { MaewTabBar } from '@/components/nav/maew-tab-bar';
import { CatColors } from '@/constants/theme';

import '@/global.css';

SplashScreen.preventAutoHideAsync();

const THEME = {
  ...DefaultTheme,
  colors: { ...DefaultTheme.colors, background: CatColors.page, card: CatColors.page, text: CatColors.text },
};

export default function RootLayout() {
  const [fontsLoaded, fontError] = useFonts({
    IBMPlexSansThaiLooped_400Regular,
    IBMPlexSansThaiLooped_500Medium,
    IBMPlexSansThaiLooped_600SemiBold,
    IBMPlexSansThaiLooped_700Bold,
  });

  useEffect(() => {
    if (fontsLoaded || fontError) SplashScreen.hideAsync();
  }, [fontsLoaded, fontError]);

  if (!fontsLoaded && !fontError) return null;

  return (
    <ThemeProvider value={THEME}>
      <StatusBar style="dark" />
      <ScreenErrorBoundary>
        <Tabs
          tabBar={(props) => <MaewTabBar {...props} />}
          screenOptions={{ headerShown: false, sceneStyle: { backgroundColor: CatColors.page } }}>
          <Tabs.Screen name="index" />
          <Tabs.Screen name="community" />
          <Tabs.Screen name="nearby" />
          <Tabs.Screen name="cat-ai" />
          <Tabs.Screen name="help" />
          <Tabs.Screen name="my-cat" />
        </Tabs>
      </ScreenErrorBoundary>
    </ThemeProvider>
  );
}
