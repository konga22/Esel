import { Stack } from 'expo-router';
import { useFonts } from 'expo-font';
import { StatusBar } from 'expo-status-bar';
import { ActivityIndicator, View } from 'react-native';
import { GalleryProvider } from '../src/state/gallery-provider';
import { theme } from '../src/components/theme';

export default function RootLayout() {
  const [fontsLoaded, fontError] = useFonts({
    CormorantGaramond_400Regular: require('@expo-google-fonts/cormorant-garamond/400Regular/CormorantGaramond_400Regular.ttf'),
    CormorantGaramond_400Regular_Italic: require('@expo-google-fonts/cormorant-garamond/400Regular_Italic/CormorantGaramond_400Regular_Italic.ttf'),
  });
  if (!fontsLoaded && !fontError) return <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: theme.background }}><ActivityIndicator color={theme.ink} accessibilityLabel="전시를 준비하고 있어요" /></View>;
  return <GalleryProvider>
    <StatusBar style="dark" />
    <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: theme.background }, animation: 'fade' }}>
      <Stack.Screen name="index" options={{ title: '오늘의 색 · Esel' }} />
      <Stack.Screen name="welcome" options={{ title: 'Esel · 일상을 전시하는 공간' }} />
      <Stack.Screen name="gallery" options={{ title: '둘러보기 · Esel' }} />
      <Stack.Screen name="profile" options={{ title: '내 전시 · Esel' }} />
      <Stack.Screen name="studio" options={{ title: '사진 스튜디오 · Esel', presentation: 'fullScreenModal' }} />
      <Stack.Screen name="post/[id]" options={{ title: '작품 감상 · Esel', presentation: 'modal' }} />
    </Stack>
  </GalleryProvider>;
}
