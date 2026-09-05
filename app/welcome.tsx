import { useState } from 'react';
import { KeyboardAvoidingView, ScrollView, Text, TextInput, View, useWindowDimensions } from 'react-native';
import { Image } from 'expo-image';
import { Redirect, router } from 'expo-router';
import { Shell } from '../src/components/shell';
import { Button, Eyebrow } from '../src/components/ui';
import { theme } from '../src/components/theme';
import { useGallery } from '../src/state/gallery-provider';

export default function Welcome() {
  const { state, dispatch } = useGallery();
  const { width } = useWindowDimensions();
  const mobile = width < 760;
  const [name, setName] = useState('');
  const [error, setError] = useState('');
  if (state.profileName) return <Redirect href="/" />;

  function enter() {
    if (name.trim().length < 2) { setError('닉네임을 두 글자 이상 입력해주세요.'); return; }
    dispatch({ type: 'set-profile', name });
    router.replace('/');
  }

  return <Shell simple><KeyboardAvoidingView style={{ flex: 1 }} behavior={process.env.EXPO_OS === 'ios' ? 'padding' : undefined}>
    <ScrollView contentInsetAdjustmentBehavior="automatic" keyboardShouldPersistTaps="handled" contentContainerStyle={{ flexGrow: 1, padding: mobile ? 26 : 64, alignItems: 'center', justifyContent: 'center' }}>
      <View style={{ width: '100%', maxWidth: 1080, flexDirection: mobile ? 'column-reverse' : 'row', alignItems: 'center', gap: mobile ? 16 : 64 }}>
        <View style={{ flex: mobile ? undefined : 1, width: mobile ? '100%' : undefined, gap: 24 }}>
          <Eyebrow>첫 번째 전시를 시작하며</Eyebrow>
          <Text accessibilityRole="header" style={{ fontSize: mobile ? 34 : 49, lineHeight: mobile ? 47 : 67, letterSpacing: -2.5, fontWeight: '300', color: theme.ink }}>당신의 하루를,{ '\n' }하나의 색으로.</Text>
          <Text style={{ fontSize: 14, lineHeight: 25, color: theme.muted }}>오늘의 색을 고르고, 당신답게 입어보세요.{ '\n' }평범한 옷차림도 이곳에서는 하나의 작품이 됩니다.</Text>
          <View style={{ marginTop: 14, gap: 12, maxWidth: 360 }}>
            <Text style={{ fontSize: 12, color: theme.ink }}>어떤 이름으로 전시할까요?</Text>
            <TextInput accessibilityLabel="닉네임" placeholder="닉네임을 입력해주세요" placeholderTextColor="#92928B" value={name} onChangeText={value => { setName(value); setError(''); }} maxLength={12} onSubmitEditing={enter} returnKeyType="go" style={{ borderBottomWidth: 1, borderColor: error ? theme.accent : '#BFBFBA', minHeight: 52, fontSize: 16, color: theme.ink, paddingVertical: 12 }} />
            {error ? <Text accessibilityRole="alert" style={{ color: '#A94229', fontSize: 12 }}>{error}</Text> : null}
            <Button onPress={enter} style={{ marginTop: 8 }}>나의 색 만나기</Button>
            <Text style={{ color: theme.muted, fontSize: 11, lineHeight: 18 }}>실제 가입 없이 체험하는 프로토타입입니다.{ '\n' }사진과 입력한 정보는 외부에 전송되지 않습니다.</Text>
          </View>
        </View>
        <View style={{ width: mobile ? 230 : 450, maxWidth: '100%', aspectRatio: 1 }}>
          <Image source={require('../assets/esel-app-icon-bg-F9F9FB.png')} contentFit="contain" style={{ width: '100%', height: '100%' }} accessibilityLabel="다채로운 유화 붓질 앞에 놓인 빈 나무 이젤" />
        </View>
      </View>
    </ScrollView>
  </KeyboardAvoidingView></Shell>;
}
