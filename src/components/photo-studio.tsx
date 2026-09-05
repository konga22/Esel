import { useCallback, useEffect, useRef, useState, type ReactNode } from 'react';
import {
  ActivityIndicator,
  AppState,
  BackHandler,
  Image as NativeImage,
  KeyboardAvoidingView,
  Linking,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { CameraView, useCameraPermissions, type CameraType } from 'expo-camera';
import { Image } from 'expo-image';
import { ImageManipulator, SaveFormat } from 'expo-image-manipulator';
import * as ImagePicker from 'expo-image-picker';
import { useFocusEffect } from 'expo-router';
import { ArrowLeft, ArrowRight, Camera, Check, Crop, Images, RefreshCw, RotateCw, X } from 'lucide-react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

type Photo = { uri: string; width: number; height: number };
type Props = {
  color: { id: string; name: string; hex: string };
  demoImage: string;
  onClose: () => void;
  onPublish: (photo: Photo & { caption: string }) => Promise<void>;
};
type Pending = 'permission' | 'photo' | 'edit' | 'publish' | null;

const INK = '#26272B';
const MUTED = '#777982';
const isWeb = process.env.EXPO_OS === 'web';

function Action({ label, icon, onPress, disabled, primary, loading }: {
  label: string;
  icon?: ReactNode;
  onPress: () => void;
  disabled?: boolean;
  primary?: boolean;
  loading?: boolean;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      accessibilityState={{ disabled: Boolean(disabled), busy: Boolean(loading) }}
      disabled={disabled}
      onPress={onPress}
      style={({ pressed }) => [styles.action, primary && styles.primary, { opacity: disabled ? 0.45 : pressed ? 0.7 : 1 }]}
    >
      {loading ? <ActivityIndicator color={primary ? '#FFFFFF' : INK} size="small" /> : icon}
      <Text style={[styles.actionText, primary && { color: '#FFFFFF' }]}>{label}</Text>
    </Pressable>
  );
}

export default function PhotoStudio({ color, demoImage, onClose, onPublish }: Props) {
  const insets = useSafeAreaInsets();
  const [stage, setStage] = useState<'source' | 'camera' | 'edit'>('source');
  const [permission, requestPermission] = useCameraPermissions();
  const [facing, setFacing] = useState<CameraType>('back');
  const [cameraReady, setCameraReady] = useState(false);
  const [draft, setDraft] = useState<Photo | null>(null);
  const [original, setOriginal] = useState<Photo | null>(null);
  const [sample, setSample] = useState(false);
  const [caption, setCaption] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [showSettings, setShowSettings] = useState(false);
  const [pending, setPending] = useState<Pending>(null);
  const operation = useRef<Pending>(null);
  const camera = useRef<CameraView>(null);
  const mounted = useRef(true);
  const sampleSize = useRef<Photo | null>(null);

  useEffect(() => {
    mounted.current = true;
    const subscription = AppState.addEventListener('change', (next) => {
      if (next !== 'active') {
        setStage((current) => current === 'camera' ? 'source' : current);
        setCameraReady(false);
      }
    });
    return () => {
      mounted.current = false;
      subscription.remove();
    };
  }, []);

  useFocusEffect(useCallback(() => {
    if (process.env.EXPO_OS !== 'android') return;
    const subscription = BackHandler.addEventListener('hardwareBackPress', () => {
      if (operation.current) return true;
      if (stage === 'source') return false;
      setStage('source');
      setError(null);
      setCameraReady(false);
      return true;
    });
    return () => subscription.remove();
  }, [stage]));

  function begin(kind: NonNullable<Pending>) {
    if (operation.current) return false;
    operation.current = kind;
    setPending(kind);
    setError(null);
    setShowSettings(false);
    return true;
  }

  function finish() {
    operation.current = null;
    if (mounted.current) setPending(null);
  }

  function acceptPhoto(photo: Photo, isSample = false) {
    if (!mounted.current) return;
    if (!photo.uri || !Number.isFinite(photo.width) || !Number.isFinite(photo.height) || photo.width <= 0 || photo.height <= 0) {
      throw new Error('The selected image could not be decoded');
    }
    setOriginal(photo);
    setDraft(photo);
    setSample(isSample);
    setError(null);
    setCameraReady(false);
    setStage('edit');
  }

  async function openCamera() {
    if (!begin('permission')) return;
    try {
      const result = permission?.granted ? permission : await requestPermission();
      if (!mounted.current) return;
      if (result.granted) {
        setCameraReady(false);
        setStage('camera');
      } else {
        setError(isWeb
          ? '카메라 접근이 허용되지 않았어요. 브라우저의 사이트 권한에서 허용하거나 앨범에서 사진을 선택해 주세요.'
          : '카메라 권한이 필요해요. 권한을 허용하거나 앨범에서 사진을 선택할 수 있어요.');
        setShowSettings(!isWeb && !result.canAskAgain);
      }
    } catch {
      if (mounted.current) setError('카메라를 열 수 없어요. 카메라 연결과 권한을 확인하거나 앨범에서 사진을 선택해 주세요.');
    } finally {
      finish();
    }
  }

  async function choosePhoto() {
    if (!begin('photo')) return;
    try {
      // On web, opening the picker must stay inside the original press event.
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ['images'],
        allowsMultipleSelection: false,
        allowsEditing: false,
        quality: 0.95,
      });
      const selected = !result.canceled ? result.assets[0] : null;
      if (selected) acceptPhoto({ uri: selected.uri, width: selected.width, height: selected.height });
    } catch (cause) {
      if (mounted.current) {
        const denied = /permission|access.+denied/i.test(String(cause));
        setError(denied
          ? '사진 접근이 허용되지 않았어요. 설정에서 권한을 확인하거나 카메라 또는 샘플 사진을 이용해 주세요.'
          : '사진을 불러오지 못했어요. 다른 사진을 선택하거나 다시 시도해 주세요.');
        setShowSettings(denied && !isWeb);
      }
    } finally {
      finish();
    }
  }

  async function useSample() {
    if (!begin('photo')) return;
    try {
      const photo = sampleSize.current?.uri === demoImage
        ? sampleSize.current
        : await new Promise<Photo>((resolve, reject) => {
          NativeImage.getSize(demoImage, (width, height) => resolve({ uri: demoImage, width, height }), reject);
        });
      acceptPhoto(photo, true);
    } catch {
      if (mounted.current) setError('샘플 사진을 불러오지 못했어요. 연결을 확인하거나 앨범의 사진으로 시작해 주세요.');
    } finally {
      finish();
    }
  }

  async function capture() {
    if (!cameraReady || !camera.current || !begin('photo')) return;
    try {
      const photo = await camera.current.takePictureAsync({ quality: 0.9 });
      if (!photo) throw new Error('No photo');
      acceptPhoto({ uri: photo.uri, width: photo.width, height: photo.height });
    } catch {
      if (mounted.current) {
        setStage('source');
        setError('촬영하지 못했어요. 카메라를 다시 열거나 앨범에서 사진을 선택해 주세요.');
      }
    } finally {
      finish();
    }
  }

  async function editPhoto(kind: 'rotate' | 'crop') {
    if (!draft || !begin('edit')) return;
    let context: ReturnType<typeof ImageManipulator.manipulate> | undefined;
    try {
      context = ImageManipulator.manipulate(draft.uri);
      if (kind === 'rotate') {
        context.rotate(90);
      } else {
        const size = Math.min(draft.width, draft.height);
        context.crop({ originX: Math.floor((draft.width - size) / 2), originY: Math.floor((draft.height - size) / 2), width: size, height: size });
      }
      const rendered = await context.renderAsync();
      try {
        const result = await rendered.saveAsync({ compress: 0.92, format: SaveFormat.JPEG });
        if (mounted.current) setDraft({ uri: result.uri, width: result.width, height: result.height });
      } finally {
        rendered.release();
      }
    } catch {
      if (mounted.current) setError(sample
        ? '이 샘플 사진은 지금 편집할 수 없어요. 원본으로 기록하거나 앨범의 사진을 선택해 주세요.'
        : '사진을 편집하지 못했어요. 현재 사진은 그대로 유지되니 다시 시도해 주세요.');
    } finally {
      context?.release();
      finish();
    }
  }

  async function publish() {
    if (!draft || !begin('publish')) return;
    try {
      await onPublish({ ...draft, caption: caption.trim() });
    } catch {
      if (mounted.current) setError('기록을 저장하지 못했어요. 사진과 글은 유지되어 있어요. 다시 시도해 주세요.');
    } finally {
      finish();
    }
  }

  const busy = pending !== null;
  const preview = stage === 'edit' && draft ? draft.uri : demoImage;

  return (
    <KeyboardAvoidingView style={styles.root} behavior={process.env.EXPO_OS === 'ios' ? 'padding' : undefined}>
      <ScrollView
        contentInsetAdjustmentBehavior="automatic"
        keyboardShouldPersistTaps="handled"
        automaticallyAdjustKeyboardInsets
        contentContainerStyle={[styles.scrollContent, { paddingTop: Math.max(insets.top, 20), paddingBottom: Math.max(insets.bottom, 24) }]}
      >
        <View style={styles.studio}>
          <View style={styles.header}>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={stage === 'source' ? '스튜디오 닫기' : '사진 선택으로 돌아가기'}
              disabled={busy}
              onPress={() => {
                if (stage === 'source') onClose();
                else { setStage('source'); setError(null); setCameraReady(false); }
              }}
              style={({ pressed }) => [styles.iconButton, { opacity: busy ? 0.4 : pressed ? 0.55 : 1 }]}
            >
              {stage === 'source' ? <X size={22} color={INK} /> : <ArrowLeft size={22} color={INK} />}
            </Pressable>
            <Text style={styles.headerTitle}>{stage === 'edit' ? '사진 다듬기' : '오늘의 색 기록'}</Text>
            <Text style={styles.step}>{stage === 'edit' ? '02 / 02' : '01 / 02'}</Text>
          </View>

          <View style={styles.intro}>
            <View style={styles.colorBadge}>
              <View style={[styles.colorDot, { backgroundColor: color.hex }]} />
              <Text selectable style={styles.colorText}>{color.name}</Text>
              <Text selectable style={styles.hex}>{color.hex.toUpperCase()}</Text>
            </View>
            <Text style={styles.title}>{stage === 'edit' ? '이 순간을 간직해요.' : '당신이 발견한 색은?'}</Text>
            <Text style={styles.subtitle}>{stage === 'edit' ? '사진을 다듬고, 오늘의 짧은 이야기를 남겨요.' : '일상 속에서 만난 색을 한 장의 사진으로 담아보세요.'}</Text>
          </View>

          {stage === 'camera' ? (
            <>
              <View style={styles.cameraFrame}>
                <CameraView
                  key={facing}
                  ref={camera}
                  facing={facing}
                  mirror={facing === 'front'}
                  mode="picture"
                  style={StyleSheet.absoluteFill}
                  onCameraReady={() => setCameraReady(true)}
                  onMountError={() => {
                    setStage('source');
                    setCameraReady(false);
                    setError('카메라를 시작하지 못했어요. 다른 앱에서 카메라를 사용 중인지 확인하거나 앨범을 이용해 주세요.');
                  }}
                />
                {!cameraReady && <View pointerEvents="none" style={styles.cameraLoading}><ActivityIndicator color="#FFFFFF" /><Text style={styles.cameraHint}>카메라 준비 중</Text></View>}
                <View pointerEvents="none" style={styles.cameraBadge}><View style={[styles.colorDot, { backgroundColor: color.hex }]} /><Text style={styles.cameraHint}>오늘의 색을 찾아보세요</Text></View>
              </View>
              <View style={styles.cameraControls}>
                <Pressable accessibilityRole="button" accessibilityLabel="카메라 닫기" disabled={busy} onPress={() => { setStage('source'); setCameraReady(false); }} style={styles.cameraControl}>
                  <X size={23} color={INK} /><Text style={styles.toolText}>닫기</Text>
                </Pressable>
                <Pressable accessibilityRole="button" accessibilityLabel="사진 촬영" accessibilityState={{ disabled: busy || !cameraReady }} disabled={busy || !cameraReady} onPress={capture} style={[styles.shutter, { opacity: busy || !cameraReady ? 0.45 : 1 }]}>
                  {pending === 'photo' ? <ActivityIndicator color={INK} /> : <View style={styles.shutterCenter} />}
                </Pressable>
                <Pressable accessibilityRole="button" accessibilityLabel="전면 후면 카메라 전환" disabled={busy} onPress={() => { setCameraReady(false); setFacing((value) => value === 'back' ? 'front' : 'back'); }} style={styles.cameraControl}>
                  <RefreshCw size={22} color={INK} /><Text style={styles.toolText}>전환</Text>
                </Pressable>
              </View>
            </>
          ) : (
            <View style={styles.previewFrame}>
              <Image
                source={{ uri: preview }}
                contentFit="contain"
                transition={0}
                accessibilityLabel={stage === 'source' || sample ? `${color.name} 샘플 사진` : '선택한 사진 미리보기'}
                style={StyleSheet.absoluteFill}
                onLoad={(event) => {
                  if (preview === demoImage) sampleSize.current = { uri: demoImage, width: event.source.width, height: event.source.height };
                }}
                onError={() => setError('사진 미리보기를 불러오지 못했어요. 연결을 확인하거나 다른 사진을 선택해 주세요.')}
              />
              {(stage === 'source' || sample) && <View style={styles.sampleBadge}><Text style={styles.sampleText}>샘플 사진</Text></View>}
              {pending === 'edit' && <View style={styles.editLoading}><ActivityIndicator color="#FFFFFF" /><Text style={styles.cameraHint}>사진을 다듬고 있어요</Text></View>}
            </View>
          )}

          {error && <View accessibilityRole="alert" style={styles.error}><Text selectable style={styles.errorText}>{error}</Text>{showSettings && <Action label="설정 열기" onPress={() => { void Linking.openSettings().catch(() => setError('설정을 열지 못했어요. 기기 설정에서 앱 권한을 확인해 주세요.')); }} />}</View>}

          {stage === 'source' && (
            <View style={styles.sourceActions}>
              <Action primary label="카메라로 촬영" icon={<Camera size={19} color="#FFFFFF" />} onPress={openCamera} disabled={busy} loading={pending === 'permission'} />
              <Action label="앨범에서 선택" icon={<Images size={19} color={INK} />} onPress={choosePhoto} disabled={busy} loading={pending === 'photo'} />
              <Pressable accessibilityRole="button" accessibilityLabel="샘플 사진으로 시작" disabled={busy} onPress={useSample} style={styles.textButton}>
                <Text style={styles.sampleAction}>샘플 사진으로 먼저 해볼게요</Text><ArrowRight size={15} color={MUTED} />
              </Pressable>
              {draft && <Action label="편집 중인 사진으로 돌아가기" onPress={() => { setStage('edit'); setError(null); }} disabled={busy} />}
            </View>
          )}

          {stage === 'edit' && draft && (
            <>
              <View style={styles.tools}>
                <Pressable accessibilityRole="button" accessibilityLabel="사진 90도 회전" disabled={busy} onPress={() => editPhoto('rotate')} style={[styles.tool, busy && styles.disabled]}><RotateCw size={20} color={INK} /><Text style={styles.toolText}>회전</Text></Pressable>
                <Pressable accessibilityRole="button" accessibilityLabel="사진 중앙을 정사각형으로 자르기" disabled={busy || draft.width === draft.height} onPress={() => editPhoto('crop')} style={[styles.tool, (busy || draft.width === draft.height) && styles.disabled]}><Crop size={20} color={INK} /><Text style={styles.toolText}>정사각형</Text></Pressable>
                <Pressable accessibilityRole="button" accessibilityLabel="모든 편집을 취소하고 원본으로 복원" disabled={busy || draft.uri === original?.uri} onPress={() => { setDraft(original); setError(null); }} style={[styles.tool, (busy || draft.uri === original?.uri) && styles.disabled]}><RefreshCw size={19} color={INK} /><Text style={styles.toolText}>원본으로</Text></Pressable>
              </View>
              <View style={styles.captionSection}>
                <View style={styles.captionHeader}><Text style={styles.captionLabel}>오늘의 한 줄</Text><Text style={styles.optional}>선택</Text><Text style={styles.counter}>{caption.length}/120</Text></View>
                <TextInput
                  accessibilityLabel="오늘의 한 줄, 최대 120자"
                  value={caption}
                  onChangeText={setCaption}
                  placeholder="이 색을 어디에서 발견했나요?"
                  placeholderTextColor="#A2A3AA"
                  maxLength={120}
                  multiline
                  editable={!busy}
                  textAlignVertical="top"
                  style={styles.captionInput}
                />
              </View>
              <Action primary label={pending === 'publish' ? '기록하는 중…' : '오늘의 색 기록하기'} icon={<Check size={19} color="#FFFFFF" />} onPress={publish} disabled={busy} loading={pending === 'publish'} />
              <Text style={styles.privacy}>외부 전송 없이 체험합니다. 새로고침하면 기록이 사라져요.</Text>
            </>
          )}
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#F9F9FB' },
  scrollContent: { flexGrow: 1, paddingHorizontal: 20, alignItems: 'center' },
  studio: { width: '100%', maxWidth: 560, gap: 20 },
  header: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  iconButton: { width: 48, height: 48, justifyContent: 'center', alignItems: 'center' },
  headerTitle: { flex: 1, color: INK, fontSize: 15, fontWeight: '600' },
  step: { color: '#9899A2', fontSize: 11, fontWeight: '500', letterSpacing: 1, fontVariant: ['tabular-nums'] },
  intro: { alignItems: 'center', gap: 10, paddingTop: 10, paddingBottom: 4 },
  colorBadge: { flexDirection: 'row', alignItems: 'center', gap: 8, borderRadius: 99, borderWidth: 1, borderColor: '#E8E8EC', backgroundColor: '#FFFFFF', paddingVertical: 8, paddingHorizontal: 12 },
  colorDot: { width: 12, height: 12, borderRadius: 6, borderWidth: 1, borderColor: 'rgba(0,0,0,0.08)' },
  colorText: { color: INK, fontSize: 11, fontWeight: '600' },
  hex: { color: '#9899A2', fontSize: 10, letterSpacing: 0.3 },
  title: { color: INK, fontSize: 29, fontWeight: '300', letterSpacing: -1 },
  subtitle: { color: MUTED, fontSize: 12, textAlign: 'center', lineHeight: 20 },
  previewFrame: { aspectRatio: 1.18, backgroundColor: '#EEEFEA', overflow: 'hidden', borderRadius: 2 },
  sampleBadge: { position: 'absolute', bottom: 14, left: 14, paddingHorizontal: 10, paddingVertical: 5, backgroundColor: 'rgba(255,255,255,0.9)', borderRadius: 99 },
  sampleText: { fontSize: 10, fontWeight: '500', color: '#65656B' },
  sourceActions: { gap: 10 },
  action: { minHeight: 54, paddingVertical: 14, paddingHorizontal: 18, borderRadius: 3, backgroundColor: 'transparent', borderWidth: 1, borderColor: '#E5E5EA', flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 9 },
  primary: { backgroundColor: INK, borderColor: INK },
  actionText: { fontSize: 13, fontWeight: '600', color: INK },
  textButton: { minHeight: 48, paddingHorizontal: 12, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8 },
  sampleAction: { fontSize: 11, color: MUTED },
  tools: { flexDirection: 'row', borderBottomWidth: 1, borderColor: '#E4E4E1', paddingVertical: 6 },
  tool: { flex: 1, minHeight: 60, alignItems: 'center', justifyContent: 'center', gap: 6 },
  toolText: { fontSize: 11, color: MUTED },
  disabled: { opacity: 0.35 },
  captionSection: { gap: 10 },
  captionHeader: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  captionLabel: { color: INK, fontSize: 13, fontWeight: '600' },
  optional: { color: '#A2A3AA', fontSize: 10 },
  counter: { flex: 1, textAlign: 'right', color: '#999BA4', fontSize: 10, fontVariant: ['tabular-nums'] },
  captionInput: { color: INK, fontSize: 13, lineHeight: 21, minHeight: 80, padding: 15, backgroundColor: '#FFFFFF', borderWidth: 1, borderColor: '#E7E7ED', borderRadius: 3 },
  privacy: { color: '#999BA4', textAlign: 'center', fontSize: 10, marginTop: -8 },
  error: { backgroundColor: '#FFF1EB', borderRadius: 14, padding: 14, gap: 10 },
  errorText: { color: '#995035', fontSize: 12, lineHeight: 19 },
  cameraFrame: { aspectRatio: 0.85, borderRadius: 20, overflow: 'hidden', backgroundColor: '#17181A' },
  cameraLoading: { ...StyleSheet.absoluteFill, alignItems: 'center', justifyContent: 'center', gap: 12 },
  cameraBadge: { position: 'absolute', top: 15, alignSelf: 'center', flexDirection: 'row', alignItems: 'center', gap: 8, padding: 10, backgroundColor: 'rgba(0,0,0,0.4)', borderRadius: 99 },
  cameraHint: { color: '#FFFFFF', fontSize: 11 },
  cameraControls: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-evenly' },
  cameraControl: { minHeight: 60, minWidth: 64, alignItems: 'center', justifyContent: 'center', gap: 6 },
  shutter: { width: 74, height: 74, borderWidth: 2, borderColor: INK, borderRadius: 37, alignItems: 'center', justifyContent: 'center' },
  shutterCenter: { width: 60, height: 60, borderRadius: 30, backgroundColor: INK },
  editLoading: { ...StyleSheet.absoluteFill, alignItems: 'center', justifyContent: 'center', gap: 10, backgroundColor: 'rgba(0,0,0,0.35)' },
});
