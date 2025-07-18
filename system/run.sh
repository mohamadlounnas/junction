#!/bin/bash

# Smart Contact System - Production Startup Script
# 🇩🇿 Algeria Real Estate AI System

echo "🚀 Starting Smart Contact System..."
echo "🇩🇿 Algeria Real Estate AI System"
echo "=================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if bun is installed
if ! command -v bun &> /dev/null; then
    echo -e "${RED}❌ Bun is not installed. Please install Bun first.${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Installing dependencies...${NC}"
bun install

echo -e "${BLUE}🔧 Generating Prisma client...${NC}"
bun run db:generate

echo -e "${BLUE}🗄️ Setting up database...${NC}"
bun run db:push

echo -e "${BLUE}🌱 Seeding database with Algeria data...${NC}"
bun run db:seed

echo -e "${BLUE}🧪 Running quick tests...${NC}"
bun run src/scripts/quick-test.ts

echo -e "${GREEN}✅ System setup complete!${NC}"
echo ""
echo -e "${YELLOW}🌐 API Endpoints:${NC}"
echo "  • Health Check: http://localhost:3001/health"
echo "  • Swagger Docs: http://localhost:3001/swagger"
echo "  • Contacts API: http://localhost:3001/api/contacts"
echo "  • Properties API: http://localhost:3001/api/properties"
echo "  • Recommendations: http://localhost:3001/api/recommendations"
echo ""
echo -e "${YELLOW}🎯 Core Features:${NC}"
echo "  • 12D Vector System for Algeria"
echo "  • AI-Powered Recommendations"
echo "  • Learning from Sales Data"
echo "  • 48 Algerian Wilayas Support"
echo "  • DZD Currency & Cultural Factors"
echo "  • Redis Caching for Performance"
echo ""
echo -e "${GREEN}🚀 Starting production server...${NC}"

# Start the server
bun src/index.ts 