import React from 'react';
import { Pressable, Text, View, useWindowDimensions } from 'react-native';
import { router, usePathname } from 'expo-router';
import { ArrowUpRight, Check } from 'lucide-react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useGallery } from '../state/gallery-provider';
import { COLORS } from '../data/demo';
import { theme } from './theme';
import { ColorDot } from './ui';

const destinations = [
  { path: '/' as const, name: '오늘의 색' },
  { path: '/gallery' as const, name: '둘러보기' },
  { path: '/profile' as const, name: '내 전시' },
];

export function Brand() {
  return <View style={{ flexDirection: 'row', alignItems: 'center', gap: 2 }}>
    <Text accessibilityLabel="Esel" style={{ fontFamily: theme.serif, fontSize: 47, letterSpacing: -3, lineHeight: 56, color: theme.ink }}>Esel</Text>
    <View style={{ width: 6, height: 6, borderRadius: 3, backgroundColor: theme.accent, marginLeft: 6, marginTop: 16 }} />
  </View>;
}

export function Shell({ children, simple = false }: React.PropsWithChildren<{ simple?: boolean }>) {
  const { width } = useWindowDimensions();
  const mobile = width < 760;
  const insets = useSafeAreaInsets();
  const pathname = usePathname();
  const { state, notice, notify } = useGallery();
  const color = COLORS.find(item => item.id === state.selectedColorId);

  function navigate(path: '/' | '/gallery' | '/profile') {
    if (!state.profileName) { router.replace('/welcome'); return; }
    if (path === '/gallery' && !color) {
      notify('먼저 오늘 입고 싶은 색을 하나 골라주세요.');
      router.replace('/');
      return;
    }
    router.replace(path);
  }

  const nav = (bottom: boolean) => destinations.map(({ path, name }) => {
    const active = pathname === path;
    return <Pressable key={path} accessibilityRole="tab" aria-selected={active} accessibilityLabel={name} accessibilityState={{ selected: active }} onPress={() => navigate(path)}
      style={({ pressed }) => ({ flex: bottom ? 1 : undefined, minHeight: 48, alignItems: 'center', justifyContent: 'center', opacity: pressed ? 0.55 : 1, borderBottomWidth: !bottom && active ? 1 : 0, borderBottomColor: theme.ink, paddingHorizontal: bottom ? 0 : 6 })}>
      <Text style={{ fontSize: bottom ? 12 : 13, letterSpacing: bottom ? 0.4 : 0, color: active ? theme.ink : theme.muted, fontWeight: active ? '600' : '400' }}>{name}</Text>
    </Pressable>;
  });

  return <View style={{ flex: 1, backgroundColor: theme.background, paddingTop: insets.top }}>
    <View style={{ paddingHorizontal: mobile ? 24 : 52 }}>
      <View style={{ width: '100%', maxWidth: 1192, alignSelf: 'center', minHeight: mobile ? 72 : 94, flexDirection: 'row', alignItems: 'center' }}>
        <View style={{ flex: 1, minWidth: 0, alignItems: 'flex-start' }}>
          {!mobile && !simple ? <View accessibilityRole="tablist" style={{ flexDirection: 'row', gap: 40 }}>{nav(false)}</View> : null}
        </View>
        <Pressable accessibilityRole="button" accessibilityLabel="Esel 오늘의 색으로" onPress={() => navigate('/')} style={{ minHeight: 56, minWidth: 100, alignItems: 'center', justifyContent: 'center' }}><Brand /></Pressable>
        <View style={{ flex: 1, minWidth: 0, alignItems: 'flex-end' }}>
          {!simple && color ? <Pressable accessibilityRole="button" accessibilityLabel={`오늘의 색 ${color.name}`} onPress={() => navigate('/')} style={{ minHeight: 48, maxWidth: '100%', flexDirection: 'row', alignItems: 'center', gap: mobile ? 6 : 9 }}>
            <ColorDot color={color.hex} /><Text numberOfLines={1} style={{ flexShrink: 1, fontSize: 12, color: theme.ink }}>{color.name}</Text><ArrowUpRight size={13} color={theme.muted} />
          </Pressable> : !mobile ? <Text style={{ fontSize: 10, letterSpacing: 1.1, color: theme.muted }}>일상을 전시하는 공간</Text> : null}
        </View>
      </View>
    </View>
    <View style={{ flex: 1 }}>{children}</View>
    {notice ? <View pointerEvents="none" accessibilityRole="alert" accessibilityLiveRegion="polite" style={{ position: 'absolute', bottom: mobile ? 88 + insets.bottom : 26, left: 20, right: 20, alignItems: 'center', zIndex: 10 }}>
      <View style={{ backgroundColor: theme.ink, maxWidth: 620, paddingVertical: 16, paddingHorizontal: 22, flexDirection: 'row', alignItems: 'center', gap: 10, borderRadius: 4 }}><Check color="#FFFFFF" size={16} /><Text style={{ color: '#FFFFFF', fontSize: 13, flexShrink: 1 }}>{notice}</Text></View>
    </View> : null}
    {mobile && !simple ? <View accessibilityRole="tablist" style={{ flexDirection: 'row', paddingHorizontal: 24, gap: 12, paddingTop: 6, paddingBottom: Math.max(insets.bottom, 12), backgroundColor: theme.background }}>{nav(true)}</View> : null}
  </View>;
}
