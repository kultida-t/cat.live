import { DarkTheme, DefaultTheme, ThemeProvider } from 'expo-router';
import { useColorScheme } from 'react-native';

import AppTabs from '@/components/app-tabs';
import { ScreenErrorBoundary } from '@/components/error-boundary';

import '@/global.css';

export default function RootLayout() {
  const colorScheme = useColorScheme();
  return (
    <ThemeProvider value={colorScheme === 'dark' ? DarkTheme : DefaultTheme}>
      <ScreenErrorBoundary>
        <AppTabs />
      </ScreenErrorBoundary>
    </ThemeProvider>
  );
}
