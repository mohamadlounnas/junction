# Multi-stage build for production optimization
FROM oven/bun:1.1.13-alpine AS base

# Install system dependencies
RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    freetype-dev \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    && rm -rf /var/cache/apk/*

# Set environment variables for Puppeteer
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Create app directory
WORKDIR /app

# Copy package files
COPY package.json bun.lock ./

# Install dependencies
RUN bun install --frozen-lockfile

# Copy Prisma schema
COPY prisma ./prisma/

# Generate Prisma client
RUN bunx prisma generate

# Copy source code
COPY src ./src/
COPY tsconfig.json ./

# Create necessary directories
RUN mkdir -p /app/uploads /app/storage/quotes /app/storage/comparisons /app/storage/professional-comparisons

# Create non-root user for security (check if bun user already exists)
RUN if ! id -u bun > /dev/null 2>&1; then \
        addgroup -g 1001 -S nodejs && \
        adduser -S bun -u 1001; \
    else \
        echo "User 'bun' already exists, skipping creation"; \
    fi

# Change ownership of app directory
RUN chown -R bun:nodejs /app
USER bun

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD bun run health || exit 1

# Start the application
CMD ["bun", "src/index.ts"]
