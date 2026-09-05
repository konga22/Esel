import { Pressable, ScrollView, Share, Text, View, useWindowDimensions } from 'react-native';
import { Image } from 'expo-image';
import { Redirect, router, useLocalSearchParams } from 'expo-router';
import { ArrowLeft, Heart, Bookmark, Share2 } from 'lucide-react-native';
import { COLORS } from '../../src/data/demo';
import { postImage } from '../../src/data/images';
import { getVisiblePosts } from '../../src/state/gallery-state';
import { useGallery } from '../../src/state/gallery-provider';
import { Shell } from '../../src/components/shell';
import { LockedExhibition } from '../../src/components/locked-exhibition';
import { Button, Eyebrow, IconButton } from '../../src/components/ui';
import { theme } from '../../src/components/theme';

export default function PostDetail() {
  const { state, dispatch, notify } = useGallery();
  const { id } = useLocalSearchParams<{ id: string }>();
  const mobile = useWindowDimensions().width < 760;
  const post = getVisiblePosts(state, 'all').find(item => item.id === id);
  const selected = COLORS.find(item => item.id === state.selectedColorId);
  if (!state.profileName) return <Redirect href="/welcome" />;
  if (!selected) return <Redirect href="/" />;
  const color = COLORS.find(item => item.id === post?.colorId);
  const goBack = () => router.canGoBack() ? router.back() : router.replace('/gallery');
  return <Shell simple><ScrollView contentInsetAdjustmentBehavior="automatic" contentContainerStyle={{ maxWidth: 1140, width: '100%', alignSelf: 'center', padding: mobile ? 24 : 48, gap: 24 }}>
    <Pressable accessibilityRole="button" onPress={goBack} style={{ flexDirection: 'row', alignItems: 'center', gap: 10, minHeight: 48, alignSelf: 'flex-start' }}><ArrowLeft size={18} color={theme.ink} /><Text style={{ fontSize: 13, color: theme.ink }}>전시로 돌아가기</Text></Pressable>
    {!post || !color ? <><LockedExhibition color={selected} /><Button secondary onPress={goBack}>다른 작품 감상하기</Button></> : <View style={{ flexDirection: mobile ? 'column' : 'row', alignItems: mobile ? 'stretch' : 'center', gap: mobile ? 28 : 70 }}>
      <Image source={postImage(post)} contentFit="contain" style={{ flex: mobile ? undefined : 1.2, width: mobile ? '100%' : undefined, aspectRatio: post.aspectRatio, maxHeight: 670, backgroundColor: '#EFEEEB' }} accessibilityLabel={`${post.author}의 ${color.name} 착장`} />
      <View style={{ flex: mobile ? undefined : 1, gap: 22 }}>
        <Eyebrow>{post.own ? '오늘의 나, 첫 번째 작품' : '오늘의 전시 · 샘플 작품'}</Eyebrow>
        <View style={{ borderLeftWidth: 3, borderLeftColor: color.hex, paddingLeft: 22, gap: 6 }}><Text style={{ fontFamily: theme.serif, fontSize: 45, color: theme.ink }}>{color.englishName}</Text><Text style={{ fontSize: 12, color: theme.muted }}>{color.name}  ·  {color.hex}</Text></View>
        <Text style={{ fontSize: 18, color: theme.ink }}>{post.author}<Text style={{ fontSize: 12, color: theme.muted }}>  /  {post.city}</Text></Text>
        <Text selectable style={{ fontSize: 15, lineHeight: 28, color: theme.muted }}>{post.caption}</Text>
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 12, borderTopWidth: 1, borderColor: theme.line, paddingTop: 16 }}>
          <IconButton icon={Heart} label="작품 좋아요" selected={state.likedIds.includes(post.id)} onPress={() => dispatch({ type: 'toggle-like', postId: post.id })} color={state.likedIds.includes(post.id) ? theme.accent : theme.ink} />
          <Text style={{ fontSize: 12, color: theme.muted }}>{post.likes + Number(state.likedIds.includes(post.id))}</Text><View style={{ flex: 1 }} />
          <IconButton icon={Bookmark} label="작품 저장" selected={state.savedIds.includes(post.id)} onPress={() => { dispatch({ type: 'toggle-save', postId: post.id }); notify(state.savedIds.includes(post.id) ? '저장을 취소했어요.' : '내 전시에 영감을 저장했어요.'); }} />
          <IconButton icon={Share2} label="작품 소개 공유" onPress={async () => { try { await Share.share({ message: `Esel · ${post.author}의 ${color.name}\n${post.caption}\n일상을 전시하는 패션 갤러리의 데모 작품입니다.` }); } catch { notify('이 브라우저에서는 공유를 지원하지 않아요. 작품을 저장해보세요.'); } }} />
        </View>
        <Text style={{ fontSize: 10, color: theme.muted, lineHeight: 19 }}>{post.own ? '이 작품은 현재 기기에서만 보이는 체험 기록입니다.' : '사진은 공개 스톡 이미지이며 이름·도시·반응은 가상의 예시입니다.'}</Text>
      </View>
    </View>}
  </ScrollView></Shell>;
}
