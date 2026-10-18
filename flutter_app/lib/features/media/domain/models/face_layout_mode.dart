enum FaceLayoutMode {
  original, // 그대로
  paintStroke, // 물감 한 획
  behindLogo, // 사인 뒤로
  belowNeck, // 목 아래
}

/// 이전 중복 선택 저장본도 P15의 단일 자르기 + 선택적 물감으로 읽는다.
/// 목 아래를 우선하며 이 경우 물감을 제거한다. 저장 파일 자체는 지우지 않는다.
Set<FaceLayoutMode> normalizeFaceEffects(Set<FaceLayoutMode> effects) {
  if (effects.contains(FaceLayoutMode.belowNeck)) {
    return const {FaceLayoutMode.belowNeck};
  }
  return Set.unmodifiable({
    if (effects.contains(FaceLayoutMode.behindLogo)) FaceLayoutMode.behindLogo,
    if (effects.contains(FaceLayoutMode.paintStroke))
      FaceLayoutMode.paintStroke,
  });
}

/// 자르기는 하나를 선택하고, 물감만 독립적으로 켜고 끈다.
Set<FaceLayoutMode> toggleFaceEffect(
  Set<FaceLayoutMode> current,
  FaceLayoutMode mode,
) {
  final next = {...normalizeFaceEffects(current)};
  if (mode == FaceLayoutMode.paintStroke) {
    if (next.contains(FaceLayoutMode.belowNeck)) return Set.unmodifiable(next);
    if (!next.remove(mode)) next.add(mode);
  } else {
    next.removeAll({FaceLayoutMode.behindLogo, FaceLayoutMode.belowNeck});
    if (mode != FaceLayoutMode.original) next.add(mode);
  }
  return normalizeFaceEffects(next);
}

/// 이전 저장본에 두 자르기가 있으면 목 아래 영역을 우선한다.
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
