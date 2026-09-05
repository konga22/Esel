import { Text, View, useWindowDimensions } from 'react-native';
import { LockKeyhole, Camera } from 'lucide-react-native';
import { router } from 'expo-router';
import { Button, Eyebrow } from './ui';
import { theme } from './theme';
import type { ColorTheme } from '../data/demo';

export function LockedExhibition({ color }: { color: ColorTheme }) {
  const mobile = useWindowDimensions().width < 760;
  return <View style={{ minHeight: 420, paddingVertical: 38, flexDirection: mobile ? 'column' : 'row', alignItems: 'center', justifyContent: 'center', gap: mobile ? 34 : 100 }}>
    <View accessibilityElementsHidden importantForAccessibility="no-hide-descendants" style={{ width: mobile ? 200 : 250, height: mobile ? 220 : 285, position: 'relative' }}>
      <View style={{ position: 'absolute', width: '80%', height: '89%', backgroundColor: color.hex, opacity: 0.27, transform: [{ rotate: '-9deg' }], left: 3, top: 14 }} />
      <View style={{ position: 'absolute', width: '80%', height: '89%', backgroundColor: color.hex, opacity: 0.5, transform: [{ rotate: '8deg' }], right: 0, top: 8 }} />
      <View style={{ position: 'absolute', width: '80%', height: '89%', backgroundColor: color.hex, left: 20, top: 8, alignItems: 'center', justifyContent: 'center' }}><LockKeyhole size={32} strokeWidth={1} color="#364035" /></View>
    </View>
    <View style={{ gap: 18, maxWidth: 380, alignItems: mobile ? 'center' : 'flex-start' }}>
      <Eyebrow>같은 색, 서로 다른 시선</Eyebrow>
      <Text accessibilityRole="header" style={{ fontSize: 30, lineHeight: 43, color: theme.ink, fontWeight: '300', letterSpacing: -1.3, textAlign: mobile ? 'center' : 'left' }}>먼저 당신의 색을{ '\n' }보여주세요.</Text>
      <Text style={{ fontSize: 13, lineHeight: 24, color: theme.muted, textAlign: mobile ? 'center' : 'left' }}>오늘의 착장을 올리면, 같은 {color.name}를{ '\n' }선택한 사람들의 전시가 열려요.</Text>
      <Button icon={Camera} onPress={() => router.push('/studio')} style={{ marginTop: 8 }}>나의 착장 올리기</Button>
      <Text style={{ fontSize: 10, color: theme.muted }}>체험 중인 공개 방식 · 아직 확정되지 않은 기능이에요</Text>
    </View>
  </View>;
}
