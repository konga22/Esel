# 표지 스타일(사인 뒤로) 마스크 저장 — 서버 설계안

> **상태: 제안(2026-11-22).** 팀 결정 전이라 `api-contract.json`·Prisma 스키마·코드는 아직 바꾸지 않았다. 아래 "정할 것"이 정해지면 약속부터 고치고 구현한다(`server/AGENTS.md` 규칙).
> 근거: 교수님 피드백 11/19의 4번 "사인 뒤로 — 사람이 글자 앞으로".

## 1. 무엇을 바꾸려는가

| | 지금 | 바꾸려는 모습 |
|---|---|---|
| "사인 뒤로" | 얼굴을 사인 글자로 **가리는** 자르기 방식(`faceCrop = BEHIND_LOGO`) | 잡지 표지처럼 사인 글자가 **사람 뒤에** 깔리고 머리가 글자 일부를 가림. 얼굴은 가리지 않음 |
| 서버 업로드 | 차단(2026-10-19). 글자를 빼고 올리면 가렸던 얼굴이 드러나기 때문 | 얼굴을 가리는 기능이 아니므로 차단 이유가 사라짐. 대신 **사람 모양(마스크)** 을 함께 저장해야 다른 폰에서도 같은 모습이 나옴 |

다른 사람 폰에서 표지를 그리는 순서는 이렇게 된다.

```
1) 사진(서버 원본)  →  2) 사인 글자(앱이 닉네임으로 그림)  →  3) 사진을 마스크 모양으로 오린 사람
```

> **마스크(mask)** = 사진과 같은 비율의 흑백 그림. 흰 곳은 "사람", 검은 곳은 "배경"이다. 앱이 이 모양대로 사진을 한 번 더 오려 글자 위에 덮는다.

서버는 그림을 합치지 않는다. 사진과 마스크를 **따로 보관하고 돌려줄 뿐**이고, 합치는 건 앱이 한다(P11 "합성은 기기 안에서"와 같은 방향).

## 2. 제안 설계

### 2-1. 마스크 파일 규칙

| 항목 | 제안값 | 이유 |
|---|---|---|
| 형식 | PNG, 8비트 흑백(grayscale) | 흑백 한 장이면 충분하고 JPEG처럼 경계가 뭉개지지 않는다 |
| 크기 | 긴 변 최대 1080px, 파일 최대 2MB | 사진보다 훨씬 작게. 작은 칸(팔레트 격자)에서도 그대로 늘려 쓰면 된다 |
| 비율 | 사진의 가로:세로와 **1% 안에서 같아야** 함 | 비율이 다르면 사람과 오린 모양이 어긋난다 |
| 썸네일 | 만들지 않음. `size=thumb`로 불러도 원본 마스크를 돌려줌 | 이미 작아서 따로 줄일 필요가 없다 |

서버 검사: PNG 시그니처, IHDR의 색 형식이 흑백(0)인지, 크기·비율. 기존 `inspectImage`(`src/media/media.rules.ts`)에 작은 규칙 함수 `checkMaskImage(mask, photo)`를 더하고 단위 테스트를 붙인다.

### 2-2. 업로드: 기존 사진 올리기 3단계를 그대로 쓴다

새 주소를 만들지 않고 `POST /media`에 **용도(`purpose`)** 만 더한다.

```jsonc
// POST /api/media
{ "mimeType": "image/png", "sizeBytes": 84000, "purpose": "MASK" }   // purpose 생략 시 "PHOTO"
```

- 그다음은 사진과 똑같이 `PUT /media/:id/file` → `POST /media/:id/complete`.
- `MASK`는 `image/png`만, 2MB까지. 어기면 기존 오류 `MEDIA_TYPE`(415)·`MEDIA_TOO_LARGE`(413)를 쓴다.
- DB: `MediaAsset`에 `purpose` 칸(enum `MediaPurpose { PHOTO, MASK }`, 기본값 `PHOTO`)을 더한다. 기존 행은 모두 `PHOTO`가 되므로 지금 데이터는 바뀌지 않는다.

> **enum** = 정해진 값 몇 개 중 하나만 들어가는 칸.

### 2-3. 발행: `POST /issues`에 두 칸 추가

```jsonc
// POST /api/issues
{
  "mediaId": "…사진 ID…",
  "caption": "오늘은 코발트.",
  "faceCrop": "ORIGINAL",
  "paintStroke": false,
  "signatureLayer": "BEHIND_PERSON",   // 새 칸. 생략하면 "FRONT"(지금처럼 글자가 맨 앞)
  "maskMediaId": "…마스크 ID…"          // 새 칸. BEHIND_PERSON일 때만, 그리고 반드시 필요
}
```

서버가 확인할 것(서비스 안 규칙 함수로):

1. `signatureLayer = BEHIND_PERSON` 이면 `maskMediaId`가 꼭 있어야 하고, `FRONT`이면 없어야 한다 → 어기면 `VALIDATION`(400).
2. 마스크는 내 것, `READY`, `purpose = MASK`, 아직 다른 호에 안 쓰인 것 → 아니면 사진과 똑같이 `MEDIA_NOT_READY`(409).
3. 마스크 비율이 사진과 맞는지 → 아니면 `VALIDATION`(400, details에 `maskMediaId`).
4. 사진 자리(`mediaId`)에 마스크를, 마스크 자리에 사진을 넣지 못하게 `purpose`를 확인한다.

DB: `Issue`에 두 칸을 더한다.

```prisma
enum SignatureLayer {
  FRONT
  BEHIND_PERSON
}

model Issue {
  // …기존 칸…
  signatureLayer SignatureLayer @default(FRONT) @map("signature_layer")
  maskId         String?        @unique @map("mask_id") @db.Uuid
  mask           MediaAsset?    @relation("IssueMask", fields: [maskId], references: [id], onDelete: Restrict)
}
```

`MediaAsset`에는 반대쪽 연결 `maskOfIssue Issue? @relation("IssueMask")`가 생긴다. 이미 공유된 migration은 고치지 않고 **새 migration** 하나로 추가한다.

### 2-4. 응답: 표지를 돌려줄 때 마스크도 함께

`IssuePublicDto`·`IssueOwnerDto`(피드·팔레트·스케치북·자세히 보기 공통)에 두 칸을 더한다.

```jsonc
{
  "media": { "id": "…", "mimeType": "image/jpeg", "width": 1080, "height": 1350 },
  "signatureLayer": "BEHIND_PERSON",
  "mask": { "id": "…", "mimeType": "image/png", "width": 864, "height": 1080 }   // FRONT이면 null
}
```

앱은 `GET /api/media/{mask.id}`로 마스크를 받는다.

### 2-5. 마스크를 볼 수 있는 사람

`GET /media/:id`는 지금 "이 사진이 연결된 호를 볼 수 있는가"(`issuesService.assertVisible`)로 권한을 정한다. 마스크도 **연결된 호와 똑같은 권한**을 쓴다. 같은 색 잠금(P01)으로 잠긴 호의 마스크는 사진처럼 404다. 사람 윤곽만으로도 정보가 새기 때문이다.

### 2-6. 놓치기 쉬운 곳: 사진 정리 작업

`MediaService.cleanupUnusedMedia`는 "호·트윈에 연결되지 않은" 사진을 24시간 뒤 지운다. 지금 조건은 `issue: null, twinPost: null`뿐이라 **그대로 두면 발행된 마스크가 하루 뒤 지워진다.** 조건에 `maskOfIssue: null`을 꼭 더하고, "발행된 마스크는 정리되지 않는다" e2e 테스트를 붙인다.

### 2-7. 이전 데이터(`BEHIND_LOGO`)

- 실제 앱은 사인 뒤로 업로드를 막아 왔으므로 서버에 있는 `BEHIND_LOGO` 호는 데모 시드(`prisma/seed-demo.mjs`) 정도다.
- **얼굴을 가렸던 호를 자동으로 `ORIGINAL`로 바꾸지 않는다.** 바꾸면 가렸던 얼굴이 드러난다(2026-10-19 결정과 같은 이유).
- 제안: enum 값은 DB에 남겨 이전 호를 그대로 읽게 하고, **새 발행에서는 `BEHIND_LOGO`를 받지 않는다**(`VALIDATION`). 데모 시드는 새 방식(`ORIGINAL` + `BEHIND_PERSON` + 마스크)으로 바꾼다.

### 2-8. 이번 범위에서 빼는 것

- 트윈 표지(`POST /twins/:id/posts`): 지금도 얼굴 연출 칸이 없다. 필요해지면 같은 방식으로 따로 더한다.
- 서버가 사람을 오려 내는 일: 하지 않는다. 오려 내기는 폰 안 AI(안드로이드 ML Kit, 아이폰 Vision)가 한다.
- HEIC 사진: 마스크 비율 검사에 사진 크기가 필요하다. 지금 HEIC는 크기를 읽지 않으므로(`width/height = null`) **HEIC 사진에는 마스크를 붙일 수 없게** 하거나, HEIC 변환 결정(`media.complete`의 note)을 먼저 내려야 한다.

## 3. 약속(api-contract.json) 변경 제안

| API | 바뀌는 것 | 오류 코드 |
|---|---|---|
| `POST /media` | 요청에 `purpose`(PHOTO·MASK) | 그대로 |
| `PUT /media/:id/file`, `POST /media/:id/complete` | MASK면 PNG·2MB·흑백 검사 | 그대로 |
| `GET /media/:id` | 마스크도 연결된 호 권한으로 공개 | 그대로 |
| `POST /issues` | 요청에 `signatureLayer`·`maskMediaId`, 새 발행의 `BEHIND_LOGO` 거절 | 그대로(`VALIDATION`·`MEDIA_NOT_READY`) |
| 호를 돌려주는 모든 응답 | `signatureLayer`·`mask` | — |

새 API 주소와 새 오류 코드는 **없다.** 기존 주소의 데이터 모양만 늘어나므로, 앱이 새 칸을 모르고 무시해도 지금처럼 동작한다(글자가 맨 앞에 그려짐).

## 4. 구현 순서(정해지면)

`server/AGENTS.md`의 "한 번에 하나" 규칙대로 나눈다.

1. 약속 수정 + `it.todo` 추가
2. migration: `MediaPurpose`·`SignatureLayer`·`Issue.maskId`
3. `POST /media` 등 3단계에 `purpose`와 마스크 검사(규칙 함수 + 단위 테스트)
4. `POST /issues` 발행 검사 + 응답 칸 추가(e2e)
5. `GET /media/:id` 마스크 권한 + 정리 작업 조건(e2e: 잠긴 호 마스크 404, 발행된 마스크는 안 지워짐)
6. 데모 시드 갱신, README·하네스 문서 갱신

## 5. 팀이 정할 것

1. **서버까지 할지, 처음엔 내 폰 미리보기만 할지.** 미리보기만이면 이 문서의 서버 일은 전부 미뤄지고, 앱은 그동안 `ORIGINAL`로 발행한다(다른 폰에서는 글자가 맨 앞).
2. **"사인 뒤로"를 얼굴 가리기 선택지에서 빼고 "표지 스타일"로 바꾸는 것**에 동의하는지(P15·하네스 §얼굴 연출 표가 바뀜). 이전 `BEHIND_LOGO` 호를 2-7처럼 남겨 둘지.
3. `BEHIND_PERSON`을 **목 아래(`BELOW_NECK`)와 함께** 허용할지. 머리가 없으면 "머리가 글자를 가리는" 효과가 약하다. 제안: 허용은 하되 앱 안내는 그대로·물감과 함께 쓰는 것으로.
4. 마스크 형식(흑백 PNG, 긴 변 1080px, 2MB)이 Flutter 쪽 ML Kit·Vision 결과와 맞는지(앱 담당과 확인).
5. HEIC 사진 처리(2-8).
