import React from 'react';
import { Pressable, Text, View, type StyleProp, type ViewStyle } from 'react-native';
import { ArrowUpRight, type LucideIcon } from 'lucide-react-native';
import { theme } from './theme';

export function Button({ children, onPress, secondary = false, disabled = false, icon: Icon = ArrowUpRight, style }: {
  children: string; onPress: () => void; secondary?: boolean; disabled?: boolean; icon?: LucideIcon; style?: StyleProp<ViewStyle>;
}) {
  return <Pressable accessibilityRole="button" accessibilityState={{ disabled }} disabled={disabled} onPress={onPress}
    android_ripple={{ color: '#88888825' }}
    style={({ pressed }) => [{ minHeight: 54, paddingHorizontal: 24, paddingVertical: 14, borderRadius: 3, flexDirection: 'row', gap: 24, alignItems: 'center', justifyContent: 'center', backgroundColor: secondary ? 'transparent' : theme.ink, borderWidth: secondary ? 1 : 0, borderColor: theme.line, opacity: disabled ? 0.35 : pressed ? 0.7 : 1 }, style]}>
    <Text style={{ fontSize: 14, fontWeight: '500', color: secondary ? theme.ink : '#FFFFFF' }}>{children}</Text>
    <Icon size={18} strokeWidth={1.5} color={secondary ? theme.ink : '#FFFFFF'} />
  </Pressable>;
}

export function IconButton({ icon: Icon, label, onPress, selected = false, color = theme.ink }: {
  icon: LucideIcon; label: string; onPress: () => void; selected?: boolean; color?: string;
}) {
  return <Pressable accessibilityRole="button" aria-pressed={selected} accessibilityLabel={label} accessibilityState={{ selected }} onPress={onPress}
    style={({ pressed }) => ({ minWidth: 48, minHeight: 48, alignItems: 'center', justifyContent: 'center', opacity: pressed ? 0.5 : 1 })}>
    <Icon size={20} color={color} strokeWidth={1.4} fill={selected ? color : 'none'} />
  </Pressable>;
}

export function Eyebrow({ children }: { children: string }) {
  return <Text style={{ fontSize: 11, fontWeight: '500', letterSpacing: 1.8, color: theme.muted }}>{children}</Text>;
}

export function ColorDot({ color, size = 10 }: { color: string; size?: number }) {
  return <View style={{ width: size, height: size, borderRadius: size / 2, backgroundColor: color }} />;
}
