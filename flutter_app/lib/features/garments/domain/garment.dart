/// P19. 쇼핑 상품이 아니라 본인이 기록한 옷. 가격·링크 필드는 두지 않는다.
class Garment {
  static const kinds = [
    '코트',
    '니트',
    '셔츠',
    '바지',
    '치마',
    '원피스',
    '신발',
    '가방',
    '액세서리',
  ];
  static const notes = ['빈티지', '물려받음', '직접 만듦', '오래 입음'];
  final String id, kind, name, note;
  final bool todayColor;

  /// 원본 사진의 비율 좌표. 두 값 모두 있거나 둘 다 없다.
  final double? x, y;
  const Garment({
    required this.id,
    required this.kind,
    this.name = '',
    this.note = '',
    this.todayColor = false,
    this.x,
    this.y,
  });
  String get label => name.isEmpty ? kind : name;
  Garment at(double? x, double? y) => Garment(
    id: id,
    kind: kind,
    name: name,
    note: note,
    todayColor: todayColor,
    x: x,
    y: y,
  );
  Garment forColor(bool selected) => Garment(
    id: id,
    kind: kind,
    name: name,
    note: note,
    todayColor: selected,
    x: x,
    y: y,
  );
  Map<String, dynamic> toJson() => {
    'garmentId': id,
    'kind': kind,
    'name': name,
    'note': note,
    'todayColor': todayColor,
    'x': x,
    'y': y,
  };
  factory Garment.fromJson(Map<String, dynamic> value) {
    final x = (value['x'] as num?)?.toDouble(),
        y = (value['y'] as num?)?.toDouble();
    final kind = value['kind'] as String;
    if ((value['garmentId'] as String).isEmpty ||
        !kinds.contains(kind) ||
        (x == null) != (y == null) ||
        (x != null &&
            (!x.isFinite ||
                !y!.isFinite ||
                x < 0 ||
                x > 1 ||
                y < 0 ||
                y > 1))) {
      throw const FormatException('착용 정보 위치와 종류를 확인해 주세요.');
    }
    final name = value['name'] as String? ?? '',
        note = value['note'] as String? ?? '';
    if (name.runes.length > 40 || (note.isNotEmpty && !notes.contains(note))) {
      throw const FormatException('착용 정보 입력을 확인해 주세요.');
    }
    return Garment(
      id: value['garmentId'] as String,
      kind: kind,
      name: name,
      note: note,
      todayColor: value['todayColor'] == true,
      x: x,
      y: y,
    );
  }
}
