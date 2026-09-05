import { Pressable, ScrollView, Text, View, useWindowDimensions } from 'react-native';
import { Redirect, router } from 'expo-router';
import { Check, Camera, ArrowRight } from 'lucide-react-native';
import { COLORS } from '../src/data/demo';
import { useGallery } from '../src/state/gallery-provider';
import { Shell } from '../src/components/shell';
import { Button, ColorDot, Eyebrow } from '../src/components/ui';
import { theme } from '../src/components/theme';

export default function Today() {
  const { state, dispatch } = useGallery();
  const { width } = useWindowDimensions();
  const mobile = width < 760;
  const narrow = width < 410;
  const color = COLORS.find(item => item.id === state.selectedColorId);
  if (!state.profileName) return <Redirect href="/welcome" />;

  return <Shell><ScrollView contentInsetAdjustmentBehavior="automatic" showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingHorizontal: mobile ? 24 : 52, paddingTop: mobile ? 32 : 52, paddingBottom: 28 }}>
    <View style={{ maxWidth: 1192, width: '100%', alignSelf: 'center' }}>
      <View style={{ paddingBottom: mobile ? 20 : 26 }}>
        <Eyebrow>오늘의 팔레트</Eyebrow>
      </View>
      <View style={{ marginBottom: mobile ? 30 : 40 }}>
        <Text accessibilityRole="header" style={{ fontSize: mobile ? 32 : 43, lineHeight: mobile ? 44 : 58, fontWeight: '300', letterSpacing: -2, color: theme.ink }}>오늘, 어떤 색을{mobile ? '\n' : ' '}입고 싶나요?</Text>
      </View>

      <View style={{ flexDirection: 'row', gap: mobile ? 10 : 24 }}>
        {COLORS.map((item, index) => {
          const selected = color?.id === item.id;
          return <Pressable key={item.id} accessibilityRole="radio" aria-checked={selected} accessibilityLabel={`${item.name} 선택`} accessibilityState={{ checked: selected, disabled: !!state.publishedPost }} disabled={!!state.publishedPost} onPress={() => dispatch({ type: 'choose-color', colorId: item.id })}
            style={({ pressed }) => ({ flex: 1, opacity: pressed ? 0.8 : 1, transform: [{ translateY: selected ? -4 : 0 }] })}>
            <View style={{ backgroundColor: item.hex, height: mobile ? 230 : 326, padding: mobile ? 13 : 26, justifyContent: 'space-between', borderRadius: 1 }}>
              <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
                <Text style={{ fontFamily: theme.serifItalic, fontSize: mobile ? 19 : 24, color: '#343D3280' }}>0{index + 1}</Text>
                <View style={{ width: 23, height: 23, borderRadius: 12, borderWidth: selected ? 0 : 1, borderColor: '#343D3240', backgroundColor: selected ? theme.ink : 'transparent', alignItems: 'center', justifyContent: 'center' }}>
                  {selected ? <Check color="#FFFFFF" size={14} strokeWidth={1.8} /> : null}
                </View>
              </View>
              <View style={{ gap: 9 }}>
                <Text style={{ fontFamily: theme.serif, fontSize: mobile ? (narrow ? 28 : 33) : 58, lineHeight: mobile ? 32 : 55, letterSpacing: -1.2, color: '#2F392F' }}>{item.id === 'powder-blue' ? 'Powder\nblue' : item.englishName}</Text>
                {!mobile ? <Text style={{ fontSize: 11, letterSpacing: 1.7, color: '#344132A0' }}>{item.hex}</Text> : null}
              </View>
            </View>
            <View style={{ paddingTop: 18, paddingBottom: 20, borderBottomWidth: selected ? 2 : 1, borderColor: selected ? theme.ink : theme.line, gap: 8 }}>
              <Text style={{ fontSize: mobile ? 12 : 15, fontWeight: '500', color: theme.ink }}>{item.name}</Text>
              {!mobile ? <Text style={{ fontSize: 12, color: theme.muted }}>{item.description}</Text> : null}
            </View>
          </Pressable>;
        })}
      </View>

      <View style={{ flexDirection: mobile ? 'column' : 'row', alignItems: mobile ? 'stretch' : 'center', justifyContent: 'space-between', gap: 22, paddingTop: 30, paddingBottom: mobile ? 30 : 44 }}>
        <View style={{ gap: 9 }}>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>{color ? <ColorDot color={color.hex} size={13} /> : null}<Text style={{ fontSize: 14, color: theme.ink }}>{state.publishedPost ? '오늘의 색이 당신의 작품이 되었어요.' : color ? `오늘의 색은 ${color.name}.` : '당신의 하루에 어울리는 색을 골라주세요.'}</Text></View>
          <Text style={{ fontSize: 12, color: theme.muted }}>{state.publishedPost ? '같은 색을 입은 사람들의 다른 해석을 만나보세요.' : '셔츠 한 장, 양말 한 켤레, 가방 하나여도 좋아요.'}</Text>
        </View>
        <View style={{ flexDirection: mobile ? 'column-reverse' : 'row', gap: 12 }}>
          <Button secondary disabled={!color} onPress={() => router.replace('/gallery')}>먼저 둘러보기</Button>
          <Button disabled={!color} icon={state.publishedPost ? ArrowRight : Camera} onPress={() => state.publishedPost ? router.replace('/profile') : router.push('/studio')}>{state.publishedPost ? '내 작품 보기' : '이 색으로 촬영하기'}</Button>
        </View>
      </View>
      <View style={{ borderTopWidth: 1, borderColor: theme.line, paddingTop: 22, flexDirection: 'row', justifyContent: 'space-between', gap: 20 }}>
        <Text style={{ fontSize: 11, color: theme.muted, lineHeight: 19 }}>정답은 없어요. 같은 색도, 당신이 입으면 달라지니까.</Text>
        {!mobile ? <Text style={{ fontSize: 10, letterSpacing: 1, color: theme.muted }}>샘플 팔레트 · 001</Text> : null}
      </View>
    </View>
  </ScrollView></Shell>;
}
