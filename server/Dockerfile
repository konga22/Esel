FROM node:24-bookworm-slim AS base
RUN apt-get update \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

FROM base AS dependencies
WORKDIR /app
# npm ci가 끝나면 postinstall이 prisma generate를 돌린다. 그래서 스키마와 설정을 먼저 복사한다.
COPY package.json package-lock.json prisma.config.ts ./
COPY prisma ./prisma
RUN npm ci

FROM dependencies AS build
COPY . .
RUN npm run build

FROM base AS runtime
ENV NODE_ENV=production
WORKDIR /app
COPY package.json package-lock.json ./
# 실행 이미지에는 prisma CLI(개발 의존성)가 없으므로 postinstall을 건너뛴다. 생성된 클라이언트는 dist에 들어 있다.
RUN npm ci --omit=dev --ignore-scripts
COPY --from=build /app/dist ./dist
# 임시 로컬 미디어 저장소. Compose volume에 연결하고 node 사용자만 쓴다.
RUN mkdir -p /app/data/media && chown -R node:node /app/data
# root가 아닌 node 사용자로 실행한다. 서버가 뚫려도 컨테이너 안에서 할 수 있는 일이 줄어든다.
USER node
EXPOSE 3000
# npm을 거치지 않고 node가 PID 1이 되어야 docker stop의 SIGTERM을 서버가 직접 받아 DB 연결을 닫고 끝낸다.
CMD ["node", "dist/main.js"]
