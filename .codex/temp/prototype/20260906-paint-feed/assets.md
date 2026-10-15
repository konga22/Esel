> **보관된 자료 · 최신 아님** — 2026-09-06 물감 에셋 제작 기록이다. 지금 쓰는 12색 물감은 `.codex/temp/prototype/20261003-cover-sns/paint/`와 [디자인 보드 01](../../../../docs/design/README.md#01-디자인-토큰)을 본다. 무엇이 최신인지는 [저장소 안내](../../../../README.md#보관된-자료)에 있다.

# 물감 에셋 제작 기록

기록일: 2026-09-06. 사용자 이름 옆에 표시하는 작은 아크릴 물감 표식용 에셋이다.

## 제작 방식과 결과

내장 `image_gen` 도구를 사용해 최초 생성 3회와 배경 편집 3회, 총 6회를 실행했다. 각 단계에서 색상별로 한 번씩 호출했다. CLI/API fallback과 로컬 이미지 후처리는 사용하지 않았다. 최종 파일은 내장 도구가 저장한 편집 결과를 그대로 복사했으며, 원본과 복사본의 SHA-256 일치를 확인했다.

최초 생성에서는 실제 알파 투명을 요청했지만 세 결과 모두 체크무늬가 포함된 불투명 RGB PNG였다. 후속 편집에서는 각 최초 생성본을 `view_image`로 확인한 다음 `referenced_image_paths`에 해당 경로 하나를 전달하고 배경만 흰색으로 바꾸도록 요청했다. 최종 파일은 알파 채널이 없는, 체크무늬 없는 거의 흰색 배경의 PNG다. 완전히 균일한 순백색이나 투명 PNG라고 간주해서는 안 된다.

세 최종 파일의 크기는 모두 1774×887px이다. 육안 검토에서 체크무늬가 제거되고 물감의 윤곽·색·능선·조명이 유지되었음을 확인했다. 색상별 최초 생성은 독립 호출이므로 서로 완전히 동일한 윤곽은 아니며, 생성된 실제 색상도 지정 HEX와 픽셀 단위로 일치한다고 보장하지 않는다.

## 파일 출처

### Sage

- 최종 에셋: [paint-sage.png](src/assets/paint-sage.png)
- 최초 생성 원본: `exec-9d23b00b-ef3a-4ec3-a017-659adfdad167.png`(작성자 로컬에만 있음, 저장소에 없음)
- 최종 편집 원본: `exec-120247d3-1203-4f18-864d-9eacbc09ed51.png`(작성자 로컬에만 있음, 저장소에 없음)
- 최종 원본 및 복사본 SHA-256: `5d6ff7a73373ff49a27199c035bf98071a3e5398b2047a8cace276892b1a0943`

### Butter

- 최종 에셋: [paint-butter.png](src/assets/paint-butter.png)
- 최초 생성 원본: `exec-71d15295-306c-4e13-a015-09c5bdf66413.png`(작성자 로컬에만 있음, 저장소에 없음)
- 최종 편집 원본: `exec-ed609b7e-d8cc-4c71-8b96-3c3c0ebc33e6.png`(작성자 로컬에만 있음, 저장소에 없음)
- 최종 원본 및 복사본 SHA-256: `6f6ce24b27c24d0d9ebf1294af490a324c1dd451f8476e2f24a952d268c8caf0`

### Powder blue

- 최종 에셋: [paint-powder-blue.png](src/assets/paint-powder-blue.png)
- 최초 생성 원본: `exec-3a4dc410-0ee4-4fb7-91cb-629450b796a3.png`(작성자 로컬에만 있음, 저장소에 없음)
- 최종 편집 원본: `exec-478c4855-f8dd-42ef-b1c2-9faf29059263.png`(작성자 로컬에만 있음, 저장소에 없음)
- 최종 원본 및 복사본 SHA-256: `2890e2544e74d31ba4ea4284c57ede24992c4c0eb1e5c217e43f399d548ee737`

## 실제 최초 생성 프롬프트

세 호출은 아래 Sage 프롬프트와 동일한 템플릿을 사용했다. `Primary request`와 `Color palette`에 있는 `muted sage green, #A8B5A0` 두 곳만 다음 값으로 치환했다. 저장된 실제 호출 프롬프트와 이 치환 결과가 완전히 일치함을 확인했다.

| 색상 | 정확한 치환 문자열 |
|---|---|
| Sage | `muted sage green, #A8B5A0` |
| Butter | `warm butter yellow, #E5C982` |
| Powder blue | `soft powder blue, #9BB8CF` |

Sage 호출 원문:

```text
Use case: product-mockup
Asset type: transparent PNG raster cutout for a tiny color mark beside a social-feed username, displayed at approximately 34 by 16 pixels.
Scene/backdrop: genuinely transparent alpha background, with zero background objects or surfaces.
Primary request: one single short, thick horizontal dab of freshly squeezed acrylic paint, as if extruded from an artist's paint tube. The paint is muted sage green, #A8B5A0. It is centered, with a plump rounded left head and one subtly pointed squeeze-off tail on the right, a continuous simple solid silhouette about 3:1 width to height.
Style/medium: photorealistic top-down orthographic macro product cutout, tactile 3D viscous acrylic paint, semi-matte finish. Show a few broad shallow squeeze ridges and restrained creamy highlights so the thickness remains legible when tiny.
Composition/framing: landscape canvas, approximately 800 by 400 pixels or similar 2:1 aspect ratio. The paint occupies approximately 85% of the canvas width and 55% of canvas height. Keep transparent margins on every edge, with no cropping. View directly down from above; horizontal left-to-right orientation.
Lighting/mood: a broad soft light from upper left; gentle highlight on upper-left rounded ridges, mild self-shading toward lower right, no dramatic shadow or floating appearance.
Color palette: a single uniform muted sage green, #A8B5A0 base pigment with only natural lighter highlights and soft darker self-shading.
Constraints: actual transparent PNG with a preserved alpha channel. No opaque white, gray, or colored backdrop; no checkerboard pattern printed into the image; no gray display plate. No paint tube, brush, palette, table, text, letters, logo, watermark, decorative flourishes, extra drips, splatters, other paint blobs, or additional objects. Make the single dab simple, chunky, and compact rather than a long thin brushstroke.
```

## 실제 최종 편집 공통 프롬프트

색상별 최초 생성 원본 하나를 각각 편집 대상으로 지정했다. 세 편집 호출의 프롬프트는 아래 원문과 모두 같다.

```text
Use case: precise-object-edit
Input image: Image 1 is the edit target.
Primary request: Replace only the existing gray-and-white checkerboard background with a perfectly solid, uniform pure white background, exactly #FFFFFF.
Preserve unchanged: the single acrylic paint dab itself, its exact silhouette and squeeze ridges, pigment color, highlights, self-shading, size, position, camera angle, and image framing.
Background requirements: every part outside the paint dab must be flat opaque pure white RGB 255,255,255. Completely remove all checkerboard squares and every residual trace of the checkerboard, including alongside the paint edge. No gradient, no gray tint, no paper texture, no floor line, no shadow on the background, no other objects, and no text.
Output intent: opaque white-background PNG for a tiny UI asset. Change only the background.
```

## 배경·알파 검증과 한계

`sips -g hasAlpha -g pixelWidth -g pixelHeight`로 최초 생성본과 최종 편집본 모두 `hasAlpha: no`, 1774×887px임을 확인했다.

최종 편집본을 Swift/AppKit의 `NSBitmapImageRep`로 읽어 외곽 배경 픽셀을 검사했다. 파일은 수정하지 않았다. 검사 영역은 0부터 시작하는 좌표에서 `x < 100 || x >= 1674 || y < 140 || y >= 780`이며, 파일마다 총 566,178픽셀이다. 이 영역은 세 이미지 모두 물감 밖의 배경에 해당한다. 이 측정은 외곽 영역에 한정되며, 물감과 맞닿는 모든 경계 픽셀을 수치로 검사한 것은 아니다.

| 최종 에셋 | 알파 | 외곽 최소 RGB | 외곽 최대 RGB | 정확한 (255,255,255) 픽셀 | 순백 비율 |
|---|---|---|---|---:|---:|
| paint-sage.png | 없음 | (253,253,253) | (255,255,255) | 71,279 / 566,178 | 12.58950365432779% |
| paint-butter.png | 없음 | (253,253,253) | (255,255,255) | 70,764 / 566,178 | 12.498542861079025% |
| paint-powder-blue.png | 없음 | (253,253,253) | (255,255,255) | 68,518 / 566,178 | 12.101847828774696% |

최종 배경은 육안상 체크무늬 없이 거의 흰색이지만, 픽셀 값이 253–255로 달라 완전히 균일한 `#FFFFFF`는 아니다. 고정 UI 배경 `#F9F9FB` 위에 `mix-blend-mode: multiply`로 표시하는 대안에 사용할 수 있으나, 이미지 바깥 배경과 최대 약 2단계의 밝기 차이가 남을 수 있다. 브라우저의 합성 표시는 이미지 파일의 알파 채널을 생성하거나 원본 배경을 제거하는 처리가 아니다.

