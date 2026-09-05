import { Redirect, router } from 'expo-router';
import { View } from 'react-native';
import PhotoStudio from '../src/components/photo-studio';
import { COLORS } from '../src/data/demo';
import { sampleImage } from '../src/data/images';
import { useGallery } from '../src/state/gallery-provider';
import { theme } from '../src/components/theme';

export default function Studio() {
  const { state, dispatch } = useGallery();
  const color = COLORS.find(item => item.id === state.selectedColorId);
  if (!state.profileName) return <Redirect href="/welcome" />;
  if (!color) return <Redirect href="/" />;
  if (state.publishedPost) return <Redirect href={{ pathname: '/gallery', params: { mode: 'same', published: '1' } }} />;
  return <View style={{ flex: 1, backgroundColor: theme.background }}><PhotoStudio color={color} demoImage={sampleImage(color.id)}
    onClose={() => router.canGoBack() ? router.back() : router.replace('/')}
    onPublish={async photo => {
      dispatch({ type: 'publish', post: { id: `own-${Date.now()}`, author: state.profileName, city: '나의 하루', colorId: color.id, image: photo.uri, aspectRatio: photo.width / photo.height, caption: photo.caption || '오늘의 색을, 나답게.', likes: 0, own: true } });
    }}
  /></View>;
}
