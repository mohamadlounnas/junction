# Use official Bun image with Debian
FROM oven/bun:1.1.13

# Install libssl3 for Prisma (this is critical)
RUN apt-get update && apt-get install -y libssl3

# Create app directory
WORKDIR /app

# Copy files
COPY . .

# Install dependencies
RUN bun install

# Prisma: generate client inside container
RUN npx prisma generate

# Build project
RUN bun run build

# Start the server
CMD ["bun", "run", "dist/index.js"]
