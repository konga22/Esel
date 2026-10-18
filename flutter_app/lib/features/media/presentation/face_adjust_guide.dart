import 'package:flutter/material.dart';
import '../../../core/design/tokens.g.dart';
import '../../../core/design/typography.dart';
import '../domain/models/face_layout_mode.dart';

/// 표지 바로 아래의 얼굴 위치 안내(P15). 물감 한 획·사인 뒤로·목 아래는 얼굴 위치를 기준으로
/// 놓이므로, 물감이 어긋났을 때 무엇을 누르면 되는지 표지 옆에서 바로 알 수 있게 한다.
class FaceAdjustGuide extends StatelessWidget {
  /// 지금 고른 연출(자르기 하나 + 물감).
  final Set<FaceLayoutMode> effects;

  /// 효과를 숨긴 원본에서 얼굴 가운데를 고르는 중인지.
  final bool locating;

  /// 얼굴 위치를 한 번이라도 정했는지. 첫 캔버스(J6)는 정해야 올릴 수 있다(P11).
  final bool placed;

  /// 위치 지정 모드가 아니어도 표지를 바로 눌러 옮길 수 있는지(편집기, 확인 전).
  final bool directTap;

  /// 위치 지정 중에 이 안내에 취소 버튼을 둘지. 화면 아래에 따로 취소가 있으면 false.
  final bool cancelHere;

  /// 위치 지정 시작·끝. 사진이 없으면 null(버튼 비활성).
  final VoidCallback? onToggle;

  const FaceAdjustGuide({
    super.key,
    required this.effects,
    required this.locating,
    required this.placed,
    required this.onToggle,
    this.directTap = false,
    this.cancelHere = true,
  });

  @override
  Widget build(BuildContext context) {
    final neck = faceCropMode(effects) == FaceLayoutMode.belowNeck;
    final paint = !neck && effects.contains(FaceLayoutMode.paintStroke);
    final tap = directTap ? ' 표지를 바로 누르거나 끌어도 돼요.' : '';
    final (title, sub, action) = _copy(neck: neck, paint: paint, tap: tap);
    return Container(
      key: const Key('face-adjust-guide'),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: locating ? EselColors.ink : EselColors.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: locating,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.touch_app_outlined, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: EselTypography.label(fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        style: EselTypography.body(
                          fontSize: 13,
                          color: EselColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (action != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('face-adjust-action'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: onToggle,
                child: Text(action),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// (제목, 설명, 버튼). 위치 지정 중 → 아직 안 정함 → 목 아래 → 물감 → 그 밖 순서로 고른다.
  (String, String, String?) _copy({
    required bool neck,
    required bool paint,
    required String tap,
  }) {
    if (locating) {
      return (
        '사진에서 얼굴 가운데를 눌러 주세요',
        '효과를 잠시 숨긴 원본이에요. 누른 자리를 기준으로 물감과 자르기가 다시 놓여요.',
        cancelHere ? '효과 미리보기로 돌아가기' : null,
      );
    }
    if (!placed) {
      return (
        '얼굴 위치를 정해 주세요',
        '효과는 바로 보이지만, 얼굴 가운데를 한 번 눌러야 물감과 자르기가 제자리에 놓여요.',
        '얼굴 위치 맞추기',
      );
    }
    if (neck) {
      return (
        '목 아래 · 물감은 쓰지 않아요',
        '턱 아래로 잘라요. 자른 자리가 어긋나면 얼굴 위치를 다시 정해 주세요.$tap',
        '얼굴 위치 다시 정하기',
      );
    }
    if (paint) {
      return (
        '물감 위치가 어긋났나요?',
        '버튼을 누르고 사진에서 얼굴 가운데를 누르면 물감이 그 자리로 옮겨 가요.$tap 물감 크기는 얼굴 크기로 맞춰요.',
        '물감 위치 옮기기',
      );
    }
    return (
      '얼굴 위치',
      '물감 한 획·사인 뒤로·목 아래는 얼굴 위치를 기준으로 놓여요. 자르기는 하나만, 물감은 따로 켜고 끌 수 있어요.$tap',
      '얼굴 위치 다시 정하기',
    );
  }
}
