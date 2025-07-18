FROM oven/bun:1.1.13

WORKDIR /app

# لو تستخدم libssl1.1 أضفه فقط إذا كان فعلاً ضروري:
RUN apt-get update && apt-get install -y libssl1.1 curl

COPY . .

# تثبيت الحزم
RUN bun install

# توليد Prisma
RUN bunx prisma generate

# Create uploads directory for file persistence
RUN mkdir -p /app/uploads

# Create volume for uploads and storage persistence
VOLUME ["/app/uploads", "/app/storage"]

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3005/health || exit 1

# لا تستخدم bun build
# شغل السيرفر مباشرة من TypeScript
CMD ["bun", "src/index.ts"]
