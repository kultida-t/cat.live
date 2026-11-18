# syntax=docker/dockerfile:1
# Image สำหรับ cat.live API (NestJS + Prisma) — build context คือ apps/api
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --legacy-peer-deps
COPY prisma ./prisma
COPY prisma.config.ts ./
COPY nest-cli.json tsconfig.json tsconfig.build.json ./
COPY src ./src
# DATABASE_URL ตัวปลอมเฉพาะตอน generate (ไม่ได้ต่อฐานข้อมูลจริงตอน build)
RUN DATABASE_URL="postgresql://build:build@localhost:5432/build" npx prisma generate \
  && npm run build \
  && npm prune --omit=dev --legacy-peer-deps

FROM node:22-alpine
ENV NODE_ENV=production \
    PORT=3000 \
    DB_SSL_CA_FILE=/app/certs/rds-ap-southeast-7-bundle.pem
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app
COPY --from=build /app/package.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY certs ./certs
USER app
EXPOSE 3000
CMD ["node", "dist/main.js"]
