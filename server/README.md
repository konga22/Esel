# Esel server

Esel의 직접 구축 REST API입니다. NestJS, PostgreSQL, Prisma로 구성합니다.

구현 구조와 설계 결정은 [ARCHITECTURE.md](ARCHITECTURE.md)를 참고하세요.

## 처음 읽을 것

| 문서 | 내용 |
|---|---|
| [AGENTS.md](AGENTS.md) | AI가 이 폴더에서 일하는 규칙. AI는 이 파일부터 읽는다 |
| [docs/LEARN.md](docs/LEARN.md) | 서버를 처음 배우는 사람을 위한 설명과 미션 순서(미션마다 AI 지시문) |
| [docs/API_RULES.md](docs/API_RULES.md) | 주소·응답·오류·폴더 규칙 |
| [api-contract.json](api-contract.json) | 만들 API 약속 목록. 여기 없는 API는 만들지 않는다 |
| [docs/REVIEW.md](docs/REVIEW.md) | PR 리뷰 체크리스트 |

```bash
npm run check:server   # 약속·규칙 검사. 설치 없이 동작하고, 실패하면 이유와 고치는 법을 알려 준다
```

## 로컬 실행

저장소 루트에서 PostgreSQL을 시작합니다.

```bash
docker compose up -d postgres
```

서버 디렉터리에서 환경변수와 DB를 준비한 뒤 실행합니다.

```bash
cp .env.example .env
npm install
npm run prisma:generate
npm run prisma:migrate -- --name init
npm run start:dev
```

- API: `http://localhost:3000/api`
- 상태 확인: `http://localhost:3000/api/health`
- Swagger: `http://localhost:3000/api/docs`

## 검증

```bash
npm run lint
npm test
npm run test:e2e
npm run build
```

`.env`는 커밋하지 않습니다. 개발 기본값은 `.env.example`에서 관리합니다.
