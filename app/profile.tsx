import { useCallback, useState } from 'react';
import { FlatList, Pressable, Text, View, useWindowDimensions } from 'react-native';
import { Redirect, router } from 'expo-router';
import { Bookmark, Camera } from 'lucide-react-native';
import { COLORS, type Post } from '../src/data/demo';
import { useGallery } from '../src/state/gallery-provider';
import { getVisiblePosts } from '../src/state/gallery-state';
import { Shell } from '../src/components/shell';
import { PostCard } from '../src/components/post-card';
import { Button, Eyebrow } from '../src/components/ui';
import { theme } from '../src/components/theme';

export default function Profile() {
  const { state, dispatch } = useGallery();
  const [tab, setTab] = useState<'mine' | 'saved'>('mine');
  const [confirmReset, setConfirmReset] = useState(false);
  const { width } = useWindowDimensions();
  const mobile = width < 760;
  const columns = width >= 1000 ? 3 : width >= 620 ? 2 : 1;
  const color = COLORS.find(item => item.id === state.selectedColorId);
  const posts = tab === 'mine' ? (state.publishedPost ? [state.publishedPost] : []) : getVisiblePosts(state, 'saved');
  const like = useCallback((postId: string) => dispatch({ type: 'toggle-like', postId }), [dispatch]);
  const save = useCallback((postId: string) => dispatch({ type: 'toggle-save', postId }), [dispatch]);
  const renderItem = useCallback(({ item }: { item: Post }) => <View style={{ flex: 1, maxWidth: `${100 / columns}%`, paddingRight: columns > 1 ? 28 : 0 }}><PostCard post={item} liked={state.likedIds.includes(item.id)} saved={state.savedIds.includes(item.id)} onLike={like} onSave={save} /></View>, [columns, state.likedIds, state.savedIds, like, save]);
  if (!state.profileName) return <Redirect href="/welcome" />;

  return <Shell><FlatList key={columns} data={posts} numColumns={columns} renderItem={renderItem} keyExtractor={item => item.id} contentInsetAdjustmentBehavior="automatic"
    contentContainerStyle={{ maxWidth: 1192, width: '100%', alignSelf: 'center', paddingHorizontal: mobile ? 24 : 52, paddingTop: mobile ? 36 : 60, paddingBottom: 30 }}
    ListHeaderComponent={<View>
      <Eyebrow>내가 쌓아가는 작은 갤러리</Eyebrow>
      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 24, paddingVertical: 30 }}>
        <View style={{ backgroundColor: color?.hex ?? '#E7E6DE', width: 78, height: 88, alignItems: 'center', justifyContent: 'center' }}><Text style={{ fontFamily: theme.serifItalic, fontSize: 48, color: '#394238' }}>{state.profileName.charAt(0)}</Text></View>
        <View style={{ gap: 10 }}><Text accessibilityRole="header" style={{ fontSize: mobile ? 28 : 37, color: theme.ink, fontWeight: '300', letterSpacing: -1.4 }}>{state.profileName}의 전시</Text><Text style={{ fontSize: 12, color: theme.muted }}>오늘의 작품 {state.publishedPost ? '1' : '0'}점  ·  저장한 영감 {getVisiblePosts(state, 'saved').length}점</Text></View>
      </View>
      <View style={{ flexDirection: 'row', gap: 28, borderBottomWidth: 1, borderColor: theme.line, marginBottom: 30 }}>
        {([{ id: 'mine', label: '나의 작품' }, { id: 'saved', label: '저장한 영감' }] as const).map(item => <Pressable key={item.id} accessibilityRole="tab" accessibilityState={{ selected: tab === item.id }} onPress={() => setTab(item.id)} style={{ minHeight: 50, justifyContent: 'center', borderBottomWidth: tab === item.id ? 1 : 0, borderColor: theme.ink }}><Text style={{ fontSize: 13, color: tab === item.id ? theme.ink : theme.muted }}>{item.label}</Text></Pressable>)}
      </View>
    </View>}
    ListEmptyComponent={<View style={{ alignItems: 'center', paddingVertical: 55, gap: 22 }}>
      {tab === 'mine' ? <View style={{ width: 125, height: 158, borderWidth: 1, borderColor: '#C4C8BF', alignItems: 'center', justifyContent: 'center' }}><View style={{ width: 72, height: 94, backgroundColor: color?.hex ?? '#E7E6DE', opacity: 0.5 }} /></View> : <Bookmark size={42} strokeWidth={1} color={theme.muted} />}
      <Text style={{ fontSize: 23, color: theme.ink, fontWeight: '300' }}>{tab === 'mine' ? '첫 작품을 기다리는 자리' : '마음이 머문 색을 모아보세요'}</Text>
      <Text style={{ fontSize: 13, color: theme.muted, textAlign: 'center', lineHeight: 23 }}>{tab === 'mine' ? '완벽한 사진이 아니어도 좋아요.\n오늘의 당신을 남겨보세요.' : '작품 아래의 저장 버튼을 누르면\n이곳에 나만의 영감이 쌓여요.'}</Text>
      <Button secondary icon={tab === 'mine' ? Camera : Bookmark} onPress={() => router.push(tab === 'mine' && color ? '/studio' : color ? '/gallery' : '/')}>{tab === 'mine' ? (color ? '첫 착장 올리기' : '오늘의 색 고르기') : '전시 둘러보기'}</Button>
    </View>}
    ListFooterComponent={<View style={{ borderTopWidth: 1, borderColor: theme.line, marginTop: 30, paddingTop: 18, gap: 12 }}>
      <Text style={{ fontSize: 11, lineHeight: 20, color: theme.muted }}>체험 기록은 이 앱을 열어둔 동안만 유지됩니다. 실제 게시나 가입은 이루어지지 않아요.</Text>
      {confirmReset ? <View style={{ gap: 12 }}><Text style={{ fontSize: 13, color: theme.ink }}>사진·선택·저장 등 이번 체험 기록을 지우고 다시 시작할까요?</Text><View style={{ flexDirection: 'row', gap: 14 }}><Button secondary onPress={() => setConfirmReset(false)}>계속 둘러보기</Button><Button onPress={() => { dispatch({ type: 'reset' }); router.replace('/welcome'); }}>체험 초기화</Button></View></View> : <Pressable accessibilityRole="button" onPress={() => setConfirmReset(true)} style={{ minHeight: 48, justifyContent: 'center', alignSelf: 'flex-start' }}><Text style={{ fontSize: 11, textDecorationLine: 'underline', color: theme.muted }}>처음부터 다시 체험하기</Text></Pressable>}
    </View>}
  /></Shell>;
}
