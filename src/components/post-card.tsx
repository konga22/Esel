import React, { memo, useState } from 'react';
import { Image } from 'expo-image';
import { Pressable, Text, View } from 'react-native';
import { router } from 'expo-router';
import { ArrowUpRight, Heart, Bookmark, ImageOff } from 'lucide-react-native';
import { COLORS, type Post } from '../data/demo';
import { postImage } from '../data/images';
import { theme } from './theme';
import { ColorDot, IconButton } from './ui';

export const PostCard = memo(function PostCard({ post, liked, saved, onLike, onSave, inset = false }: {
  post: Post; liked: boolean; saved: boolean; onLike: (id: string) => void; onSave: (id: string) => void; inset?: boolean;
}) {
  const color = COLORS.find(item => item.id === post.colorId)!;
  const [error, setError] = useState(false);
  const [retry, setRetry] = useState(0);
  return <View style={{ flex: 1, paddingTop: inset ? 42 : 0, paddingBottom: 24 }}>
    <Pressable accessibilityRole="button" accessibilityLabel={`${post.author}의 ${color.name} 착장 감상`} onPress={() => router.push({ pathname: '/post/[id]', params: { id: post.id } })}
      style={({ pressed }) => ({ opacity: pressed ? 0.8 : 1, position: 'relative', backgroundColor: '#EFEEEA', overflow: 'hidden' })}>
      <Image key={retry} source={postImage(post)} style={{ width: '100%', aspectRatio: post.aspectRatio }} contentFit="cover" transition={0} onError={() => setError(true)} accessibilityLabel={`${color.name} 포인트로 표현한 착장 사진`} />
      {error ? <View style={{ position: 'absolute', inset: 0, alignItems: 'center', justifyContent: 'center', gap: 12, backgroundColor: '#ECEDE9' }}>
        <ImageOff color={theme.muted} size={28} /><Text style={{ color: theme.muted, fontSize: 12 }}>사진을 불러오지 못했어요.</Text>
      </View> : null}
      {post.own ? <View style={{ position: 'absolute', top: 16, left: 16, backgroundColor: theme.background, paddingHorizontal: 10, paddingVertical: 6 }}><Text style={{ fontSize: 10, color: theme.ink }}>나의 작품</Text></View> : null}
      <View style={{ position: 'absolute', right: 14, bottom: 14, width: 31, height: 31, backgroundColor: color.hex, justifyContent: 'center', alignItems: 'center' }}><ArrowUpRight size={15} color={theme.ink} strokeWidth={1.4} /></View>
    </Pressable>
    {error ? <Pressable accessibilityRole="button" onPress={() => { setError(false); setRetry(value => value + 1); }} style={{ minHeight: 48, justifyContent: 'center' }}><Text style={{ color: theme.ink, fontSize: 12 }}>사진 다시 불러오기</Text></Pressable> : null}
    <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingTop: 17, gap: 8 }}>
      <View style={{ flexDirection: 'row', alignItems: 'baseline', gap: 8 }}><Text style={{ fontSize: 14, fontWeight: '500', color: theme.ink }}>{post.author}</Text><Text style={{ fontSize: 11, color: theme.muted }}>{post.city}</Text></View>
      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}><ColorDot color={color.hex} size={8} /><Text style={{ fontSize: 10, color: theme.muted }}>{color.name}</Text></View>
    </View>
    <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginLeft: -12, marginRight: -12 }}>
      <View style={{ flexDirection: 'row', alignItems: 'center' }}><IconButton icon={Heart} label={`${post.author} 좋아요${liked ? ' 취소' : ''}`} selected={liked} color={liked ? theme.accent : theme.ink} onPress={() => onLike(post.id)} /><Text style={{ fontSize: 11, color: theme.muted }}>{post.likes + (liked ? 1 : 0)}</Text></View>
      <IconButton icon={Bookmark} label={`${post.author} 작품 ${saved ? '저장 취소' : '저장'}`} selected={saved} onPress={() => onSave(post.id)} />
    </View>
  </View>;
});
