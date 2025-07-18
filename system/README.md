# Smart Contact System 🇩🇿

**AI-Powered Real Estate Recommendation System for Algeria**

A sophisticated recommendation system using 12-dimensional vectors to match properties with potential buyers, tenants, and investors across all 48 Algerian wilayas.

[![TypeScript](https://img.shields.io/badge/TypeScript-007ACC?style=flat&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Elysia](https://img.shields.io/badge/Elysia-FF6B35?style=flat&logo=bun&logoColor=white)](https://elysiajs.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)](https://postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-DC382D?style=flat&logo=redis&logoColor=white)](https://redis.io/)
[![Prisma](https://img.shields.io/badge/Prisma-2D3748?style=flat&logo=prisma&logoColor=white)](https://prisma.io/)

---

## 🚀 Quick Start

### Prerequisites
- **Bun** 1.0+ (recommended) or Node.js 18+
- Access to provided PostgreSQL database
- Access to provided Redis instance

### Installation

#### Option 1: Quick Start (Recommended)
```bash
# One-command setup and start
./run.sh
```

#### Option 2: Manual Setup
```bash
# 1. Install dependencies
bun install

# 2. Generate Prisma client
bun run db:generate

# 3. Push schema to database
bun run db:push --force-reset

# 4. Seed with sample Algerian data
bun run db:seed

# 5. Run tests to verify
bun run src/scripts/quick-test.ts

# 6. Start the server
bun src/index.ts
```

#### Option 3: Development Mode
```bash
# Start with hot reload
bun run dev
```

### Environment Configuration

The system is pre-configured with the provided database credentials:

```bash
# PostgreSQL Database
DATABASE_URL="postgres://postgres:PLXmyyPpWrtJZM99UdOiupWvFoSp1U1jpXEF1ofiVsUwz3SOQvlRkTJowRkaUsO3@95.179.193.54:9834/postgres"

# Redis Cache
REDIS_URL="redis://default:kgq7lDyxL9wTxBrNUmqj0xneZ0HJB68vmOXbnIHg0ZwuvB1Aj9klv9nvrs2mHAsq@95.179.193.54:7739/0"

# Server
PORT=3001
```

**🌐 Access Points:**
- **API Server**: `http://localhost:3001`
- **Swagger Documentation**: `http://localhost:3001/swagger`
- **Health Check**: `http://localhost:3001/health`

---

## 📊 Database Schema

### Simplified 2-Table Approach

The system uses a streamlined approach with only **2 core tables** plus supporting tables:

#### **Contacts Table**
```typescript
{
  id: string,
  email: string,
  name: string,
  phone?: string,
  type: 'BUYER' | 'TENANT' | 'INVESTOR',
  
  // Budget & Location Preferences
  budgetMin?: number,  // DZD
  budgetMax?: number,  // DZD
  locationWilayas: string[],  // Preferred wilayas
  locationCities: string[],   // Preferred cities
  transactionType: 'RENT' | 'SALE',
  
  // Property Preferences
  propertyTypes: PropertyType[],
  familySize?: number,
  hasChildren: boolean,
  minRooms?: number,
  maxRooms?: number,
  minArea?: number,    // m²
  maxArea?: number,    // m²
  
  // Preferences
  furnishingType?: FurnishingType,
  preferredCondition?: PropertyCondition,
  requiresParking: boolean,
  requiresSecurity: boolean,
  
  // AI Score Vector (12D)
  scores: number[],  // Auto-generated 12D vector
  
  isActive: boolean,
  createdAt: DateTime,
  updatedAt: DateTime
}
```

#### **Properties Table**
```typescript
{
  id: string,
  title: string,
  description?: string,
  
  // Basic Info
  price: number,       // DZD
  area: number,        // m²
  rooms: number,
  bathrooms?: number,
  
  // Location
  wilaya: string,      // Algerian wilaya
  city: string,
  address?: string,
  latitude?: number,   // GPS
  longitude?: number,  // GPS
  
  // Property Details
  propertyType: PropertyType,
  transactionType: 'RENT' | 'SALE',
  furnishing: FurnishingType,
  condition: PropertyCondition,
  
  // Features
  hasParking: boolean,
  hasSecurity: boolean,
  hasElevator: boolean,
  hasGarden: boolean,
  hasBalcony: boolean,
  hasSwimmingPool: boolean,
  
  // Building Info
  buildingAge?: number,
  floor?: number,
  totalFloors?: number,
  
  // AI Score Vector (12D)
  scores: number[],    // Auto-generated 12D vector
  
  status: PropertyStatus,
  ownerId?: string,
  viewCount: number,
  featured: boolean,
  createdAt: DateTime,
  updatedAt: DateTime
}
```

#### **Supporting Tables**
- **Sales**: Learning data for improving recommendations
- **Settings**: System configuration and algorithm parameters

---

## 🧠 12D Vector System

### Vector Dimensions

Each contact and property has a **12-dimensional vector** for perfect compatibility:

```typescript
[
  0: BUDGET,      // Budget/price level (0-1)
  1: AREA,        // Area preference (0-1)
  2: ROOMS,       // Room count preference (0-1)
  3: LOCATION,    // Location desirability (0-1)
  4: PROPERTY_TYPE, // Property type preference (0-1)
  5: CONDITION,   // Condition preference (0-1)
  6: FEATURES,    // Amenities importance (0-1)
  7: FAMILY,      // Family-friendliness (0-1)
  8: MODERN,      // Modernity preference (0-1)
  9: INVESTMENT,  // Investment potential (0-1)
  10: URGENCY,    // Urgency level (0-1)
  11: TRANSACTION // Transaction type (RENT=0, SALE=1)
]
```

### Algeria-Optimized Scoring

- **48 Wilayas**: All Algerian wilayas with desirability scores
- **DZD Pricing**: 2M-100M DZD range normalization
- **Cultural Factors**: Family size, children, security preferences
- **Geographic**: Coastal vs inland, urban vs rural preferences

---

## 🔧 API Documentation

### Core Endpoints

#### **Health & System**
```http
GET /health                    # System health check
GET /api/stats                 # System statistics
```

#### **Contacts Management**
```http
GET    /api/contacts           # List contacts with filters
POST   /api/contacts           # Create new contact
GET    /api/contacts/:id       # Get contact by ID
PUT    /api/contacts/:id       # Update contact
DELETE /api/contacts/:id       # Delete contact
```

#### **Properties Management**
```http
GET    /api/properties         # List properties with filters
POST   /api/properties         # Create new property
GET    /api/properties/:id     # Get property by ID
PUT    /api/properties/:id     # Update property
DELETE /api/properties/:id     # Delete property
```

#### **AI Recommendations**
```http
GET /api/recommendations/contact/:id    # Get property recommendations for contact
GET /api/recommendations/property/:id   # Get contact recommendations for property
```

#### **Learning System**
```http
GET    /api/sales              # List sales data
POST   /api/sales              # Record new sale (triggers learning)
GET    /api/sales/:id          # Get sale details
```

#### **Settings Management**
```http
GET    /api/settings           # List all settings
GET    /api/settings/:key      # Get setting by key
POST   /api/settings           # Create/update setting
PUT    /api/settings/:key      # Update setting
DELETE /api/settings/:key      # Delete setting
```

### Example API Usage

#### Create a Contact
```bash
curl -X POST http://localhost:3001/api/contacts \
  -H "Content-Type: application/json" \
  -d '{
    "email": "client@example.dz",
    "name": "Ahmed Benali",
    "phone": "+213 555 123 456",
    "type": "BUYER",
    "budgetMin": 15000000,
    "budgetMax": 25000000,
    "locationWilayas": ["Algiers", "Boumerdès"],
    "propertyTypes": ["VILLA", "APARTMENT"],
    "transactionType": "SALE",
    "familySize": 4,
    "hasChildren": true,
    "requiresParking": true
  }'
```

#### Get Recommendations
```bash
curl "http://localhost:3001/api/recommendations/contact/{contactId}?limit=10&minSimilarity=0.7"
```

---

## 🎯 Core Algorithms

### 1. **Score Generation**

```typescript
// Generate scores for contacts
generateScoresFromContact(contact) -> number[12]

// Generate scores for properties  
generateScoresFromProperty(property) -> number[12]
```

### 2. **Similarity Calculation**

Uses **cosine similarity** for vector comparison:

```typescript
calculateSimilarity(contactVector, propertyVector) -> number [0-1]
```

### 3. **Learning Algorithm**

Updates contact preferences based on successful sales:

```typescript
learnFromSale(contact, property, sale) -> updatedContactVector
```

---

## 🔄 Recommendation Flow

```mermaid
graph TD
    A[Contact Profile] --> B[Generate 12D Vector]
    C[Property Listing] --> D[Generate 12D Vector]
    B --> E[Calculate Similarity]
    D --> E
    E --> F{Similarity > Threshold?}
    F -->|Yes| G[Return Recommendation]
    F -->|No| H[Skip Property]
    I[Successful Sale] --> J[Learn & Update Vector]
    J --> K[Improved Future Recommendations]
```

---

## 🚀 Available Scripts

```bash
# Development
bun run dev              # Start development server with hot reload
bun src/index.ts         # Direct server start
./run.sh                 # Complete setup and start

# Database
bun run db:generate      # Generate Prisma client
bun run db:push          # Push schema to database
bun run db:seed          # Seed with sample data

# Testing
bun run test             # Run comprehensive API tests
bun run test:watch       # Run tests in watch mode
bun run src/scripts/quick-test.ts  # Quick vector system test

# Health Check
bun run health           # Check if server is running
curl http://localhost:3001/health  # Direct health check
```

---

## 📈 Sample Data

The system comes pre-seeded with realistic Algerian real estate data:

- **5 Contacts**: Various types (buyers, tenants, investors)
- **6 Properties**: Diverse properties across Algeria (villas, apartments, offices, land)
- **2 Sales Records**: Learning examples
- **5 System Settings**: Algorithm configuration

### Locations Covered
- **Algiers**: Hydra, Bab Ezzouar, Ben Aknoun, Alger Centre
- **Oran**: Es Senia, Oran Centre
- **Constantine**: City center and surrounding areas
- **Tipaza**: Coastal properties
- Other major wilayas

### Property Types
- Villas with gardens
- Modern apartments
- Commercial offices
- Traditional houses
- Land plots
- Student studios

---

## 🎯 System Features

### ✅ **Implemented**

#### **Core System**
- ✅ **12D Vector System**: Perfect contact-property matching
- ✅ **Auto-Score Generation**: Automatic vector calculation from data
- ✅ **Algeria Optimization**: All 48 wilayas, DZD pricing, cultural factors
- ✅ **Database Schema**: Prisma with PostgreSQL
- ✅ **Redis Caching**: Performance optimization
- ✅ **API Documentation**: Swagger/OpenAPI integration

#### **API Endpoints**
- ✅ **CRUD Operations**: Complete contact and property management
- ✅ **Recommendation Engine**: AI-powered matching
- ✅ **Learning System**: Sales-based preference updates
- ✅ **Settings Management**: Configurable algorithm parameters
- ✅ **Health Monitoring**: System status and statistics

#### **Algeria-Specific**
- ✅ **Wilaya Support**: All 48 Algerian wilayas
- ✅ **DZD Pricing**: Proper currency and range handling
- ✅ **Cultural Factors**: Family size, children, security preferences
- ✅ **French/Arabic**: Proper text handling for Algerian context

---

## 🔮 Competitive Advantages

1. **Simplicity**: Only 2 core models vs complex multi-table systems
2. **Performance**: 12D vectors enable fast similarity calculations
3. **Learning**: System improves from every successful sale
4. **Algeria-Focused**: Built specifically for Algerian market
5. **Scalability**: Designed for 10,000+ contacts
6. **Transparency**: Explainable AI recommendations
7. **Flexibility**: Traditional search + optional AI scoring

---

## 📞 Usage Examples

### Traditional Search
```bash
# Find apartments in Algiers under 70K DZD/month
GET /api/properties?wilaya=Algiers&propertyType=APARTMENT&transactionType=RENT&priceMax=70000
```

### AI-Powered Recommendations
```bash
# Get AI recommendations for a specific contact
GET /api/recommendations/contact/{id}?limit=10&minSimilarity=0.7
```

### Learning from Sales
```bash
# Record a successful sale to improve recommendations
POST /api/sales
{
  "contactId": "...",
  "propertyId": "...",
  "salePrice": 22000000,
  "successScore": 0.9
}
```

---

## 🛠️ Technical Stack

- **Runtime**: Bun (High-performance JavaScript runtime)
- **Framework**: ElysiaJS (Type-safe web framework)
- **Database**: PostgreSQL with Prisma ORM
- **Caching**: Redis for performance optimization
- **Documentation**: Swagger/OpenAPI 3.0
- **Language**: TypeScript (100% type coverage)
- **Deployment**: Ready for production deployment

---

## 🔧 Configuration

Key system settings (configurable via API):

```typescript
{
  "recommendation_threshold": 0.3,    // Minimum similarity
  "max_recommendations": 50,          // Max results
  "learning_rate": 0.1,              // Learning speed
  "enable_learning": true,            // Auto-learning
  "cache_ttl_recommendations": 600    // Cache duration
}
```

---

## 📄 License

This project is designed for the Algerian real estate market and competition requirements.

---

**🇩🇿 Built with ❤️ for Algeria's digital transformation in real estate! 🚀**