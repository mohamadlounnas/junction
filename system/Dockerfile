FROM oven/bun:1.1.13

# لتفادي مشاكل libssl مع Prisma (استخدم نسخة محدثة)
RUN apt-get update && apt-get install -y libssl-dev

WORKDIR /app

COPY . .

RUN bun install
RUN bunx prisma generate
RUN bun run build

# نشغّل الملف النهائي مباشرةً (وليس عبر "bun run")
CMD ["bun", "dist/index.js"]
