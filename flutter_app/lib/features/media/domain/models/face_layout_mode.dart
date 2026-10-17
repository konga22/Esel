enum FaceLayoutMode {
  original, // 그대로
  paintStroke, // 물감 한 획
  behindLogo, // 제호 뒤로
  belowNeck, // 목 아래
}

/// 그대로는 효과 없음. 나머지는 독립적으로 켜고 끈다.
Set<FaceLayoutMode> toggleFaceEffect(
  Set<FaceLayoutMode> current,
  FaceLayoutMode mode,
) {
  if (mode == FaceLayoutMode.original) return const {};
  final next = {...current}..remove(FaceLayoutMode.original);
  if (!next.remove(mode)) next.add(mode);
  return Set.unmodifiable(next);
}

/// 두 자르기 효과를 겹치면 목 아래 영역을 우선한다. 물감은 별도 레이어다.
FaceLayoutMode faceCropMode(Set<FaceLayoutMode> effects) =>
    effects.contains(FaceLayoutMode.belowNeck)
    ? FaceLayoutMode.belowNeck
    : effects.contains(FaceLayoutMode.behindLogo)
    ? FaceLayoutMode.behindLogo
    : FaceLayoutMode.original;

/// 단일 효과를 읽는 이전 코드/저장 형식에도 현재 상태를 일관되게 전달한다.
FaceLayoutMode primaryFaceEffect(Set<FaceLayoutMode> effects) {
  final crop = faceCropMode(effects);
  return crop != FaceLayoutMode.original
      ? crop
      : effects.contains(FaceLayoutMode.paintStroke)
      ? FaceLayoutMode.paintStroke
      : FaceLayoutMode.original;
}
