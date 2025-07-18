FROM oven/bun:1.1.13

# Install libssl1.1 instead of libssl3
RUN apt-get update && apt-get install -y libssl1.1

WORKDIR /app

COPY . .

RUN bun install

# Update binary target for Prisma
RUN npx prisma generate

RUN bun run build

CMD ["bun", "run", "dist/index.js"]
