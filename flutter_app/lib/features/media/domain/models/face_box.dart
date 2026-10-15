/// 사진 안 얼굴의 가운데와 폭. 사진 가로·세로에 대한 비율(0~1)이다.
///
/// 예시 인물은 디자인 생성기가 macOS Vision으로 잰 값, 내 사진은 표지에서 직접 정한 값이다.
/// 실제 앱의 자동 얼굴 감지는 아직 정하지 않았다(하네스 facePresentation).
class FaceBox {
  final double x;
  final double y;
  final double width;

  const FaceBox(this.x, this.y, this.width);

  @override
  bool operator ==(Object other) =>
      other is FaceBox && other.x == x && other.y == y && other.width == width;

  @override
  int get hashCode => Object.hash(x, y, width);
}
