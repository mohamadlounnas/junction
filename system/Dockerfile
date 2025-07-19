FROM oven/bun:1.1.13

WORKDIR /app

# Install system dependencies for Puppeteer and other requirements
RUN apt-get update && apt-get install -y \
    libssl1.1 \
    curl \
    wget \
    gnupg \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libxss1 \
    libxtst6 \
    xdg-utils \
    libgbm1 \
    libxkbcommon0 \
    libxshmfence1 \
    && rm -rf /var/lib/apt/lists/*

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
