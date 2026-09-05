import { useCallback, useMemo, useState } from 'react';
import { FlatList, Pressable, Text, View, useWindowDimensions } from 'react-native';
import { Redirect, router, useLocalSearchParams } from 'expo-router';
import { LockKeyhole, ArrowUpRight, Check } from 'lucide-react-native';
import { COLORS, type Post } from '../src/data/demo';
import { useGallery } from '../src/state/gallery-provider';
import { getVisiblePosts } from '../src/state/gallery-state';
import { Shell } from '../src/components/shell';
import { PostCard } from '../src/components/post-card';
import { LockedExhibition } from '../src/components/locked-exhibition';
import { ColorDot, Eyebrow } from '../src/components/ui';
import { theme } from '../src/components/theme';

export default function Gallery() {
  const { state, dispatch, notify } = useGallery();
  const params = useLocalSearchParams<{ mode?: string; published?: string }>();
  const [mode, setMode] = useState<'all' | 'same'>(params.mode === 'same' ? 'same' : 'all');
  const [showSuccess, setShowSuccess] = useState(params.published === '1');
  const { width } = useWindowDimensions();
  const mobile = width < 760;
  const columns = width >= 1000 ? 3 : width >= 620 ? 2 : 1;
  const color = COLORS.find(item => item.id === state.selectedColorId);
  const posts = useMemo(() => getVisiblePosts(state, mode), [state, mode]);
  const like = useCallback((postId: string) => dispatch({ type: 'toggle-like', postId }), [dispatch]);
  const save = useCallback((postId: string) => {
    dispatch({ type: 'toggle-save', postId });
    notify(state.savedIds.includes(postId) ? '저장한 영감에서 제외했어요.' : '내 전시에 영감을 저장했어요.');
  }, [dispatch, notify, state.savedIds]);
  const renderItem = useCallback(({ item, index }: { item: Post; index: number }) => <View style={{ flex: 1, maxWidth: `${100 / columns}%`, paddingHorizontal: mobile ? 0 : 14 }}>
    <PostCard post={item} liked={state.likedIds.includes(item.id)} saved={state.savedIds.includes(item.id)} onLike={like} onSave={save} inset={columns === 3 && index % 3 === 1} />
  </View>, [columns, mobile, state.likedIds, state.savedIds, like, save]);

  if (!state.profileName) return <Redirect href="/welcome" />;
  if (!color) return <Redirect href="/" />;

  const header = <View style={{ paddingHorizontal: mobile ? 0 : 14 }}>
    <View style={{ flexDirection: mobile ? 'column' : 'row', justifyContent: 'space-between', alignItems: mobile ? 'flex-start' : 'flex-end', gap: 20, paddingBottom: 36 }}>
      <View style={{ gap: 16 }}><Eyebrow>오늘의 전시</Eyebrow><Text accessibilityRole="header" style={{ fontSize: mobile ? 32 : 43, color: theme.ink, lineHeight: mobile ? 44 : 57, fontWeight: '300', letterSpacing: -1.8 }}>서로 다른 하루,{ '\n' }저마다의 색.</Text></View>
      <Pressable accessibilityRole="button" onPress={() => state.publishedPost ? router.replace('/profile') : router.push('/studio')} style={({ pressed }) => ({ minHeight: 58, minWidth: mobile ? '100%' : 250, borderBottomWidth: 1, borderBottomColor: theme.ink, flexDirection: 'row', alignItems: 'center', gap: 14, paddingVertical: 12, opacity: pressed ? 0.6 : 1 })}>
        <View style={{ width: 36, height: 44, backgroundColor: color.hex }} /><View style={{ flex: 1, gap: 4 }}><Text style={{ fontSize: 10, color: theme.muted }}>나의 {color.name}</Text><Text style={{ fontSize: 13, color: theme.ink }}>{state.publishedPost ? '오늘의 작품 보기' : '아직 비어 있는 나의 자리'}</Text></View><ArrowUpRight size={20} strokeWidth={1.3} color={theme.ink} />
      </Pressable>
    </View>
    {showSuccess && state.publishedPost ? <Pressable accessibilityRole="button" accessibilityLabel="게시 성공 안내 닫기" onPress={() => setShowSuccess(false)} style={{ backgroundColor: '#EBEFE8', flexDirection: 'row', gap: 12, alignItems: 'center', padding: 16, marginBottom: 24 }}>
      <Check size={20} color="#3E5740" /><Text accessibilityLiveRegion="polite" style={{ fontSize: 13, color: '#3E5740', flex: 1 }}>첫 작품이 걸렸어요. 같은 색의 다른 시선을 만나보세요.</Text>
    </Pressable> : null}
    <View style={{ flexDirection: 'row', alignItems: 'center', borderBottomWidth: 1, borderBottomColor: theme.line, marginBottom: 28, gap: 28 }}>
      {([{ id: 'all', label: '모두의 전시' }, { id: 'same', label: '같은 색' }] as const).map(tab => <Pressable key={tab.id} accessibilityRole="tab" accessibilityState={{ selected: mode === tab.id }} onPress={() => setMode(tab.id)} style={{ minHeight: 49, flexDirection: 'row', alignItems: 'center', gap: 7, borderBottomWidth: mode === tab.id ? 1 : 0, borderColor: theme.ink }}><Text style={{ fontSize: 13, color: mode === tab.id ? theme.ink : theme.muted }}>{tab.label}</Text>{tab.id === 'same' && !state.publishedPost ? <LockKeyhole size={12} color={theme.muted} /> : null}</Pressable>)}
      <View style={{ flex: 1 }} /><Text style={{ fontSize: 10, color: theme.muted }}>샘플 전시</Text>
    </View>
    {mode === 'all' && !state.publishedPost ? <View style={{ flexDirection: 'row', alignItems: 'center', gap: 7, paddingBottom: 22 }}><ColorDot color={color.hex} size={7} /><Text style={{ fontSize: 11, color: theme.muted }}>지금은 {color.name} 외 다른 색의 작품을 감상하고 있어요.</Text></View> : null}
  </View>;

  return <Shell><FlatList key={columns} data={posts} numColumns={columns} renderItem={renderItem} keyExtractor={item => item.id} contentInsetAdjustmentBehavior="automatic" showsVerticalScrollIndicator={false}
    style={{ flex: 1 }} contentContainerStyle={{ width: '100%', maxWidth: 1220, alignSelf: 'center', paddingHorizontal: mobile ? 24 : 38, paddingTop: mobile ? 30 : 48, paddingBottom: 26 }}
    columnWrapperStyle={columns > 1 && mobile ? { gap: 20 } : undefined} ListHeaderComponent={header}
    ListEmptyComponent={mode === 'same' ? <LockedExhibition color={color} /> : <Text style={{ padding: 40, color: theme.muted }}>아직 전시된 작품이 없어요.</Text>}
    ListFooterComponent={posts.length > 0 ? <View style={{ paddingHorizontal: mobile ? 0 : 14, paddingVertical: 24, borderTopWidth: 1, borderColor: theme.line }}><Text style={{ fontSize: 11, color: theme.muted, textAlign: 'center' }}>오늘의 전시를 모두 만났어요. 다음 색으로 또 만나요.</Text></View> : null}
  /></Shell>;
}
