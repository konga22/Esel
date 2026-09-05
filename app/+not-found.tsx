import { View, Text } from 'react-native';
import { router } from 'expo-router';
import { Button } from '../src/components/ui';
import { theme } from '../src/components/theme';

export default function NotFound() {
  return <View style={{ flex: 1, backgroundColor: theme.background, alignItems: 'center', justifyContent: 'center', padding: 30, gap: 24 }}><Text style={{ color: theme.ink, fontSize: 26 }}>아직 걸리지 않은 작품이에요.</Text><Button onPress={() => router.replace('/')}>오늘의 색으로 돌아가기</Button></View>;
}
