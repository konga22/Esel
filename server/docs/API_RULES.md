# Esel API 규칙

서버의 모든 API는 이 규칙대로 만든다. 무엇을 만들지는 [api-contract.json](../api-contract.json), 왜 그런지는 [배움 안내](LEARN.md)에 있다. `npm run check:server`가 이 규칙의 일부를 자동으로 확인한다.

## 1. 약속이 먼저

- API는 `api-contract.json`에 있는 것만 만든다. 바꾸려면 그 파일을 먼저 고치고 PR에서 리뷰를 받는다.
- 정본 관계: **경로·방법·권한(access)·오류 코드 = `api-contract.json`, 요청·응답 데이터 모양 = Swagger(코드의 DTO)**. 앱은 Swagger(`/api/docs`, 개발 환경)에서 필드를 확인한다.
- 하나의 API = `id`(이름), `method`, `path`, `access`, `request`, `response`, `errors`, `feature`(DEV-xx), `contracts`(P01~P18), `test`, `status`, 그리고 필요하면 `note`(아직 사용자가 정하지 않은 것).
- `feature`는 루트 `docs/dev/features.json`의 기능 ID, `contracts`는 루트 `harness.json`의 `productContracts` ID만 쓴다. `check:server`가 루트와 대조한다.

## 2. 주소

| 규칙 | 좋은 예 | 나쁜 예 |
|---|---|---|
| 모든 주소는 `/api`로 시작(`main.ts`의 전역 prefix) | `/api/issues` | `/issues` |
| 소문자와 하이픈만 | `/api/share-links` | `/api/shareLinks`, `/api/share_links` |
| 모음은 복수 명사 | `/api/issues`, `/api/friends/requests` | `/api/issue` |
| 로그인한 나의 것은 `/api/me/…` | `/api/me/records` | `/api/users/123/records` |
| 동작은 동사 대신 하위 주소 + POST | `POST /api/twins/:id/consent` | `POST /api/consentTwin` |
| 경로 변수는 `:이름`(camelCase 가능) | `/api/issues/:id`, `/api/issues/:id/lines/:lineId/reports` | `/api/issues/{id}` |

## 3. 방법(HTTP method)

| 방법 | 쓰는 때 | 예 |
|---|---|---|
| GET | 읽기만. 아무것도 바꾸지 않는다 | `GET /api/feed` |
| POST | 새로 만들기, 동작 실행 | `POST /api/issues`(발행), `POST /api/issues/:id/like` |
| PUT | 하나의 값을 통째로 정하기 | `PUT /api/today/choice` |
| PATCH | 일부만 바꾸기 | `PATCH /api/me/profile` |
| DELETE | 지우기, 취소하기 | `DELETE /api/issues/:id/like` |

성공 상태 코드는 하나로 정한다(`api-contract.json`의 `successStatus`).

| 방법 | 성공 | 예 |
|---|---|---|
| GET·PUT·PATCH·DELETE | 200 | `GET /api/feed`, `DELETE /api/issues/:id/like` |
| POST | 201 | `POST /api/issues`, `POST /api/auth/email/login` |
| 돌려줄 것이 없음(`response: "void"`) | 204 | `POST /api/auth/logout`, `DELETE /api/me` |

같은 좋아요를 두 번 보내도 결과는 한 번이어야 한다(멱등). 좋아요·스크랩·구독은 "누른 상태"를 저장하고, 이미 눌렀어도 오류 없이 같은 성공 응답(POST는 201, DELETE는 200)을 돌려준다.

## 4. 누가 부를 수 있나(access)

| access | 뜻 | 서버가 할 일 |
|---|---|---|
| `public` | 로그인 없이 | 컨트롤러에 `@Public()`을 붙인다 |
| `user` | 로그인한 사람(기본값) | 인증 가드가 토큰을 확인한다. 없으면 401 `AUTH_REQUIRED`, 만료면 401 `TOKEN_EXPIRED`. 이 401은 access로 정해지므로 `errors`에 따로 적지 않는다 |
| `owner` | 그 자원의 주인 | 서비스에서 `authorId === 나`를 확인한다. 나에게 보이지만 남의 것이면 403 `FORBIDDEN`. 없거나 나에게 잠긴 것이면 404가 먼저다 |
| `member` | 트윈의 두 사람 중 하나 | 서비스에서 참여자인지 확인한다. 아니면 404 `NOT_FOUND`(트윈이 있다는 사실도 숨긴다) |

403과 404 가르는 법: **나에게 보이지 않는 것(없음·잠김·숨김)은 언제나 404**, 보이지만 바꿀 권한이 없을 때만 403이다. 예: 남의 표지 id로 `/api/me/issues/:id/reactions`를 부르면 403, 그 표지가 나에게 잠겨 있으면(P01) 404.

로그인은 `Authorization: Bearer <access token>` 헤더로 받는다. 인증 가드는 전역으로 걸고, 열어 둘 API에만 `@Public()`을 단다(닫힌 것이 기본).

## 5. 주고받는 모양(DTO)

- JSON 필드 이름은 camelCase: `serviceDate`, `issueNumber`, `hiddenCount`.
- 날짜(서비스 날짜)는 `"2026-09-06"` 문자열. 서비스 날짜는 서버가 `SERVICE_TIME_ZONE`(Asia/Seoul)으로 정한다. 앱이 "오늘"을 보내게 하지 않는다.
- 시각은 ISO 8601 UTC 문자열: `"2026-09-06T06:00:00.000Z"`.
- ID는 UUID 문자열. 색은 12색 key 문자열: `"camel"`.
- 요청 DTO는 `class-validator`로 검사하고, 응답 DTO는 이름으로 공개 범위를 드러낸다.

| 이름 끝 | 누구에게 | 숫자 필드 |
|---|---|---|
| `…PublicDto` | 아무 사용자 | **넣지 않는다**(`likeCount`, `subscriberCount`, `lineCount`, `scrapCount`, `readerCount` 등) |
| `…OwnerDto` | 주인 본인 | 넣어도 된다. `/api/me/…` 또는 주인 확인 후에만 돌려준다 |
| 그 밖(`TodayDto`, `TwinDto`, `FeedPageDto` 등) | 요청한 본인에 관한 것 | 남의 숫자는 넣지 않는다 |

`check:server`는 이름이 `…PublicDto`인 것만이 아니라 access가 `public`·`user`인 API의 응답 DTO 전체와 그 안에 든 DTO(필드 타입, `PickType`·`OmitType` 같은 상속)를 보고, `likesCount`·`like_count`·`totalLikes`처럼 이름을 바꾼 숫자도 막는다. 루트 `harness.json`의 `publicCounts.ownerOnly`(likes·subscribers·reader-line-count·scrap-count)는 `api-contract.json`의 `publicCountFields`로 서버 필드 이름과 이어진다.

글자 수: 표지 문구 40자, 독자 한 줄 60자, 소개 80자, 제호는 영문 소문자 2~10자(`^[a-z]{2,10}$`).

## 6. 목록과 페이지

목록은 항상 이 모양이고, 전체 개수(total)는 주지 않는다. 개수가 곧 인기 숫자가 되기 때문이다(P18).

```json
{ "items": [ ... ], "nextCursor": "eyJpZCI6..." }
```

다음 페이지는 `?cursor=<nextCursor>`로 부르고, 더 없으면 `nextCursor`는 `null`. 이미 보낸 항목의 순서는 다음 페이지에서 바뀌지 않는다.

## 7. 오류 모양

오류는 언제나 이 모양이다. 코드는 `api-contract.json`의 `errors` 목록에 있는 것만 쓴다.

```json
{
  "error": {
    "code": "ISSUE_ALREADY_PUBLISHED",
    "message": "오늘 호는 이미 발행했어요.",
    "hint": "하루에 한 호만 발행할 수 있어요."
  }
}
```

| 상태 | 언제 |
|---|---|
| 400 `VALIDATION` | 형식이 틀림(빈 값, 너무 긴 글). 어느 항목인지 `details`에 |
| 401 | 로그인 안 함, 토큰 만료 |
| 403 | 로그인했고 나에게 보이지만, 남의 것을 바꾸거나 주인만 보는 것을 보려 함(owner API) |
| 404 | 없음. **잠겨서 볼 수 없는 것도 404**로 답한다. 403으로 답하면 "그런 표지가 있다"는 사실이 새기 때문이다(P01). 트윈 참여자가 아닐 때도 404 |
| 409 | 지금 상태와 부딪힘(이미 발행, 이미 있는 제호, 이미 친구) |
| 413·415 | 사진이 너무 큼, 사진이 아님 |
| 422 | 형식은 맞지만 규칙상 안 됨(후보에 없는 색, 복원할 수 없는 날짜) |
| 429 | 너무 자주 요청 |

서버 안에서는 `throw new AppException('ISSUE_ALREADY_PUBLISHED')`처럼 코드만 던지고, 전역 예외 필터가 위 모양으로 바꾼다. 메시지 표는 `src/common/errors.ts` 한 곳에 두고 `api-contract.json`과 같게 유지한다.

## 8. 폴더와 책임

```text
src/
  main.ts          앱을 만들고 configureApp → enableShutdownHooks → listen
  app.setup.ts     configureApp: 접두어 /api, ValidationPipe, Helmet, CORS, Swagger 조건, 전역 필터(main과 e2e가 같이 씀)
  common/          service-date.ts(서비스 날짜), AppException, 전역 예외 필터, @Public(), 인증 가드, 페이지 도우미
  <모듈>/          api-contract.json의 module 이름 (auth, profile, today, media, issues, feed, stand,
                   magazines, me, records, friends, twins, share, account, moderation)
    <모듈>.controller.ts   요청 받기·DTO 검사·서비스 호출·응답 DTO로 바꾸기. DB를 직접 부르지 않는다
    <모듈>.service.ts      흐름과 권한 확인. PrismaService는 여기서만
    <모듈>.rules.ts        P01·P04 같은 규칙을 순수 함수로. 단위 테스트가 쉽다
    <모듈>.rules.spec.ts   규칙 단위 테스트
    dto/*.dto.ts           요청·응답 DTO
test/create-app.ts                 e2e용 앱 만들기(configureApp을 거침)
test/contracts/<모듈>.e2e-spec.ts   API 테스트(합격 기준). 루트 features.json의 tests가 이 경로를 가리킨다
```

## 9. 예: 좋아요 하나를 끝까지

```ts
// src/issues/dto/reaction-state.dto.ts
export class ReactionStateDto {
  @ApiProperty() liked: boolean;   // 내가 눌렀는지만. 몇 명이 눌렀는지는 넣지 않는다(P18)
}

// src/issues/issues.controller.ts
@Post(':id/like')
@ApiOperation({ summary: '좋아요(두 번 보내도 한 번)' })
like(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() me: AuthUser): Promise<ReactionStateDto> {
  return this.issues.like(me.id, id);
}

// src/issues/issues.service.ts
async like(userId: string, issueId: string): Promise<ReactionStateDto> {
  await this.assertVisible(userId, issueId);           // 볼 수 없는 표지면 404 (P01)
  await this.prisma.like.upsert({ where: { userId_issueId: { userId, issueId } }, create: { userId, issueId }, update: {} });
  return { liked: true };
}
```

```ts
// test/contracts/issues.e2e-spec.ts
it('POST /api/issues/:id/like: 두 번 보내도 한 번만 저장된다', async () => {
  await request(app.getHttpServer()).post(`/api/issues/${issue.id}/like`).set(auth(dana)).expect(201);
  await request(app.getHttpServer()).post(`/api/issues/${issue.id}/like`).set(auth(dana)).expect(201);
  expect(await prisma.like.count({ where: { issueId: issue.id } })).toBe(1);
});
```

## 10. Swagger

- 모든 API에 `@ApiOperation({ summary })`(api-contract.json의 summary와 같게)와 성공·오류 `@ApiResponse`를 단다.
- Swagger는 `NODE_ENV`가 `production`이 아닐 때만 켠다(`configureApp`). `check:server`가 조건을 읽어 운영에서 켜지면 실패시킨다.
