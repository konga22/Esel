# Esel server

Esel의 직접 구축 REST API입니다. NestJS, PostgreSQL, Prisma로 구성합니다.

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
