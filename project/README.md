# Smart Contact: AI-Powered Real Estate Recommendation System 🇩🇿

> *Algeria's Most Advanced Real Estate Matching Platform*

A sophisticated **AI-powered recommendation system** specifically designed for the **Algerian real estate market**. Uses advanced vector-based scoring, machine learning algorithms, and Redis caching to intelligently match properties with potential buyers and tenants across all 48 wilayas.

[![TypeScript](https://img.shields.io/badge/TypeScript-007ACC?style=flat&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Elysia](https://img.shields.io/badge/Elysia-FF6B35?style=flat&logo=bun&logoColor=white)](https://elysiajs.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)](https://postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-DC382D?style=flat&logo=redis&logoColor=white)](https://redis.io/)
[![Prisma](https://img.shields.io/badge/Prisma-2D3748?style=flat&logo=prisma&logoColor=white)](https://prisma.io/)

---

## 🚀 Quick Start

### Prerequisites
- **Bun** 1.0+ (recommended) or Node.js 18+
- **PostgreSQL** with pgvector extension
- **Redis** server

### Installation

```bash
# 1. Navigate to project directory
cd project

# 2. Install dependencies
bun install

# 3. Generate Prisma client
bun run db:generate

# 4. Push schema to database
bun run db:push

# 5. Seed with realistic Algerian data
bun run db:seed

# 6. Start the development server
bun run dev
```

### Environment Configuration
```bash
# Database (PostgreSQL with pgvector)
DATABASE_URL="postgres://postgres:PLXmyyPpWrtJZM99UdOiupWvFoSp1U1jpXEF1ofiVsUwz3SOQvlRkTJowRkaUsO3@95.179.193.54:9834/postgres"

# Redis Cache
REDIS_URL="redis://default:kgq7lDyxL9wTxBrNUmqj0xneZ0HJB68vmOXbnIHg0ZwuvB1Aj9klv9nvrs2mHAsq@95.179.193.54:7739/0"
```

**🌐 Server Access:**
- **API Server**: `http://localhost:3001`
- **Swagger Docs**: `http://localhost:3001/swagger`
- **Health Check**: `http://localhost:3001/api/health`

---

## 📊 Database Schema

### Core Models

#### **Users Table**
```sql
CREATE TABLE users (
  id            TEXT PRIMARY KEY,
  email         TEXT UNIQUE NOT NULL,
  name          TEXT NOT NULL,
  phone         TEXT,
  userType      TEXT NOT NULL, -- BUYER, TENANT, AGENT
  scoreVector   REAL[] NOT NULL DEFAULT '{0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5}',
  createdAt     TIMESTAMP DEFAULT NOW(),
  updatedAt     TIMESTAMP DEFAULT NOW()
);
```

#### **Properties Table**
```sql
CREATE TABLE properties (
  id                    TEXT PRIMARY KEY,
  title                 TEXT NOT NULL,
  description           TEXT,
  price                 REAL NOT NULL,
  area                  REAL NOT NULL,
  rooms                 INTEGER NOT NULL,
  location              TEXT NOT NULL,
  propertyType          TEXT NOT NULL, -- APARTMENT, VILLA, OFFICE, LAND
  furnishing            TEXT NOT NULL, -- FURNISHED, UNFURNISHED, SEMI_FURNISHED
  condition             TEXT NOT NULL, -- POOR, FAIR, GOOD, EXCELLENT
  transactionType       TEXT NOT NULL, -- RENT, SALE
  scoreVector           REAL[] NOT NULL,
  status                TEXT DEFAULT 'ACTIVE', -- ACTIVE, INACTIVE, SOLD
  isResidentialComplex  BOOLEAN DEFAULT FALSE,
  hasParking            BOOLEAN DEFAULT FALSE,
  hasSecurity           BOOLEAN DEFAULT FALSE,
  agentId               TEXT REFERENCES users(id),
  createdAt             TIMESTAMP DEFAULT NOW(),
  updatedAt             TIMESTAMP DEFAULT NOW()
);
```

#### **Settings Table** (Admin Configuration)
```sql
CREATE TABLE settings (
  id          TEXT PRIMARY KEY,
  key         TEXT UNIQUE NOT NULL,
  value       TEXT NOT NULL,
  type        TEXT DEFAULT 'STRING', -- STRING, NUMBER, BOOLEAN, JSON
  category    TEXT NOT NULL,         -- algorithm, system, business, ui
  description TEXT,
  isPublic    BOOLEAN DEFAULT FALSE,
  createdAt   TIMESTAMP DEFAULT NOW(),
  updatedAt   TIMESTAMP DEFAULT NOW()
);
```

---

## 🔧 Complete API Documentation

### **🏥 Health & System**

#### Health Check
```http
GET /api/health
```
**Response:**
```json
{
  "success": true,
  "message": "Smart Contact API is running",
  "timestamp": "2025-01-18T01:59:26.500Z"
}
```

#### System Statistics
```http
GET /api/stats
```
**Response:**
```json
{
  "success": true,
  "data": {
    "users": { "total": 25, "byType": [...] },
    "properties": { "total": 50, "byTransactionType": [...] }
  }
}
```

---

### **👥 Users API**

#### Get All Users (with Pagination & Filtering)
```http
GET /api/users?page=1&limit=10&userType=BUYER&search=john
```
**Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 10, max: 100)
- `userType` (optional): BUYER, TENANT, AGENT
- `search` (optional): Search in name/email
- `similarityVector` (optional): JSON array of 12 numbers for similarity search
- `minSimilarity` (optional): Minimum similarity threshold (default: 0.3)
- `scoreIndex` (optional): Vector dimension index (0-11) for range filtering
- `scoreMin` (optional): Minimum score value for the specified dimension
- `scoreMax` (optional): Maximum score value for the specified dimension

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "cm...",
      "email": "user@example.com",
      "name": "John Doe",
      "phone": "+213 XXX XXX XXX",
      "userType": "BUYER",
      "scoreVector": [0.7, 0.4, 0.5, ...],
      "createdAt": "2025-01-18T01:08:07.312Z",
      "updatedAt": "2025-01-18T01:08:07.312Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 25,
    "pages": 3
  },
  "filters": {
    "userType": "BUYER",
    "search": "john",
    "similarityVector": "provided",
    "minSimilarity": 0.5,
    "scoreIndex": 0,
    "scoreMin": 0.6,
    "scoreMax": 0.9
  }
}
```

#### Get User by ID
```http
GET /api/users/:id
```

#### Create New User
```http
POST /api/users
Content-Type: application/json

{
  "email": "newuser@example.com",
  "name": "New User",
  "phone": "+213 XXX XXX XXX",
  "userType": "BUYER",
  "scoreVector": [0.5, 0.6, 0.4, ...] // Optional: 12-dimensional vector
}
```

#### Update User
```http
PUT /api/users/:id
Content-Type: application/json

{
  "name": "Updated Name",
  "phone": "+213 XXX XXX XXX"
}
```

#### Delete User
```http
DELETE /api/users/:id
```

#### User Score Management
```http
GET /api/users/:id/score              # Get user's preference vector
PUT /api/users/:id/score              # Update user's preference vector
```

---

### **🏠 Properties API**

#### Get All Properties (with Advanced Filtering)
```http
GET /api/properties?page=1&limit=10&location=Algiers&propertyType=VILLA&transactionType=SALE&priceMin=5000000&priceMax=25000000&areaMin=100&areaMax=300&rooms=4&furnishing=FURNISHED&condition=EXCELLENT&status=ACTIVE&search=villa
```
**Filters:**
- `location`: Wilaya/city name
- `propertyType`: APARTMENT, VILLA, OFFICE, LAND
- `transactionType`: RENT, SALE
- `priceMin/priceMax`: Price range in DZD
- `areaMin/areaMax`: Area range in m²
- `rooms`: Number of rooms
- `furnishing`: FURNISHED, UNFURNISHED, SEMI_FURNISHED
- `condition`: POOR, FAIR, GOOD, EXCELLENT
- `status`: ACTIVE, INACTIVE, SOLD
- `search`: Search in title/description/location

#### Get Property by ID
```http
GET /api/properties/:id
```

#### Create New Property
```http
POST /api/properties
Content-Type: application/json

{
  "title": "Villa moderne avec jardin",
  "description": "Belle villa située à Hydra...",
  "price": 35000000,
  "area": 250,
  "rooms": 4,
  "location": "Hydra, Algiers",
  "propertyType": "VILLA",
  "furnishing": "SEMI_FURNISHED",
  "condition": "EXCELLENT",
  "transactionType": "SALE",
  "agentId": "agent_id",
  "isResidentialComplex": false,
  "hasParking": true,
  "hasSecurity": true
}
```

#### Update Property
```http
PUT /api/properties/:id
```

#### Delete Property
```http
DELETE /api/properties/:id
```

#### Property Score Management
```http
GET /api/properties/:id/score           # Get property's feature vector
POST /api/properties/:id/sync-score     # Recalculate property score
```

---

### **🎯 Recommendations API**

#### Get Property Recommendations for User
```http
GET /api/recommendations/user/:id?limit=10&minScore=0.3&location=Algiers&propertyType=VILLA&transactionType=SALE&priceMin=5000000&priceMax=25000000
```
**Parameters:**
- `limit`: Max recommendations (default: 10)
- `minScore`: Minimum similarity threshold (default: 0.3)
- Plus all property filters

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "property": {
        "id": "...",
        "title": "Villa luxueuse avec jardin privé",
        "location": "Hydra, Algiers",
        "price": 25000000,
        "area": 180,
        "rooms": 4,
        "propertyType": "VILLA",
        "agent": {
          "id": "...",
          "name": "Agent Name",
          "email": "agent@example.com"
        }
      },
        "similarity": 0.94
    }
  ],
  "user": {
    "id": "...",
    "name": "User Name",
    "userType": "BUYER"
  },
  "filters": {...}
}
```

#### Get User Recommendations for Property
```http
GET /api/recommendations/property/:id?limit=10&minScore=0.3&userType=BUYER
```

---

### **⚙️ Admin Settings API** (Requires Agent Authentication)

All admin endpoints require `Authorization: Bearer {AGENT_USER_ID}` header.

#### Get All Settings
```http
GET /api/admin/settings
Authorization: Bearer {AGENT_ID}
```

#### Get Setting by Key
```http
GET /api/admin/settings/{key}
Authorization: Bearer {AGENT_ID}
```

#### Create/Update Setting
```http
POST /api/admin/settings
Authorization: Bearer {AGENT_ID}
Content-Type: application/json

{
  "key": "recommendation_threshold",
  "value": 0.4,
  "type": "NUMBER",
  "category": "algorithm",
  "description": "Minimum similarity threshold for recommendations"
}
```

#### Update Setting
```http
PUT /api/admin/settings/{key}
Authorization: Bearer {AGENT_ID}
Content-Type: application/json

{
  "value": 0.5
}
```

#### Delete Setting
```http
DELETE /api/admin/settings/{key}
Authorization: Bearer {AGENT_ID}
```

#### Get Settings by Category
```http
GET /api/admin/settings/category/{category}
Authorization: Bearer {AGENT_ID}
```

#### Bulk Update Settings
```http
POST /api/admin/settings/bulk
Authorization: Bearer {AGENT_ID}
Content-Type: application/json

{
  "settings": [
    {
      "key": "max_recommendations",
      "value": 75,
      "type": "NUMBER",
      "category": "algorithm"
    }
  ]
}
```

#### Reset to Defaults
```http
POST /api/admin/settings/reset
Authorization: Bearer {AGENT_ID}
```

#### Clear Cache
```http
POST /api/admin/settings/clear-cache
Authorization: Bearer {AGENT_ID}
```

---

## 🧠 Algeria-Optimized Vector System

### **12-Dimensional Vector Structure**

The system uses **12-dimensional vectors** specifically optimized for the Algerian real estate market:

```typescript
scoreVector = [
  // Index 0: Price (DZD 2M-50M normalized)
  // Index 1: Area (30-500m² normalized)  
  // Index 2: Rooms (1-6 rooms normalized)
  // Index 3: Wilaya (48 Algerian wilayas encoded)
  // Index 4: Property Type (APARTMENT=0.2, VILLA=0.8, OFFICE=0.5, LAND=0.1)
  // Index 5: Furnishing (UNFURNISHED=0.0, SEMI=0.5, FURNISHED=1.0)
  // Index 6: Condition (POOR=0.0, FAIR=0.3, GOOD=0.7, EXCELLENT=1.0)
  // Index 7: Transaction Type (RENT=0.0, SALE=1.0)
  // Index 8: Amenities (Parking, Security, Elevator combined)
  // Index 9: Neighborhood (Residential vs Commercial area)
  // Index 10: Accessibility (Transport, Mosque, Market proximity)
  // Index 11: Family-Friendly (Schools, Healthcare, Safety)
]
```

### **Smart Default System**

The system automatically generates intelligent preferences when users don't provide complete information:

#### **Example: Minimal User Input**
```typescript
// Input: Only userType
{ userType: "BUYER" }

// Output: Intelligent 12D vector
[0.7, 0.6, 0.4, 0.9, 0.4, 0.2, 0.8, 1.0, 0.3, 0.6, 0.5, 0.3]
// = Moderate budget buyer preferring major cities, good condition properties
```

#### **Example: Family with Children**
```typescript
// Input: Detailed family preferences
{
  userType: "BUYER",
  familySize: 5,
  hasChildren: true,
  preferredLocation: "Algiers",
  budget: 25000000
}

// Output: Family-optimized vector
[0.5, 0.63, 0.67, 0.95, 0.8, 0.2, 0.8, 1.0, 0.8, 0.8, 0.5, 1.0]
// = Family-friendly villa preference in Algiers with security/schools
```

### **Wilaya Encoding (All 48 Algerian Wilayas)**

Major cities receive higher scores reflecting market importance:
- **Algiers**: 0.95 (Capital)
- **Oran**: 0.92 (Economic hub)
- **Constantine**: 0.90 (Regional center)
- **Annaba**: 0.85 (Port city)
- **Boumerdès**: 0.75 (Near capital)
- **Provincial cities**: 0.20-0.70
- **Rural areas**: 0.02-0.50

---

## 🚀 Available Scripts

```bash
# Development
bun run dev              # Start development server with hot reload
bun run build            # Build for production
bun run start            # Start production server

# Database
bun run db:generate      # Generate Prisma client
bun run db:push          # Push schema to database
bun run db:seed          # Seed with Algerian sample data

# Testing
bun run test             # Run database tests
bun run db:test          # Test database operations
bun run test:admin       # Test admin settings functionality

# Algeria-specific
bun run scripts/test-algeria-vectors.ts  # Test vector system
```

---

## 📈 Current Sample Data

- **25 Users**: 5 agents, 11 buyers, 9 tenants with realistic Algerian profiles
- **50 Properties**: 27 for sale, 23 for rent across Algerian cities
- **Locations**: Algiers, Oran, Constantine, Annaba, Boumerdès, etc.
- **Price Ranges**: 2M-50M DZD (realistic Algerian market prices)
- **Features**: All property types with Algerian market characteristics

---

## 🎯 Current Features Status

### ✅ **Fully Implemented**

#### **Core System**
- [x] **Database Schema**: PostgreSQL with pgvector extension
- [x] **Vector Similarity**: Cosine similarity calculations
- [x] **Algeria Optimization**: 48 wilayas, DZD prices, cultural preferences
- [x] **Smart Defaults**: Intelligent vector generation for missing preferences
- [x] **Redis Caching**: Performance optimization with auto-invalidation

#### **API Endpoints**
- [x] **Users CRUD**: Complete user management with score vectors
- [x] **Properties CRUD**: Full property management with auto-score calculation
- [x] **Recommendations**: User-property matching with advanced filtering
- [x] **Admin Settings**: Laravel-style admin panel for system configuration
- [x] **Statistics**: System analytics and reporting

#### **Documentation**
- [x] **Swagger/OpenAPI**: Interactive API documentation at `/swagger`
- [x] **Type Safety**: Full TypeScript implementation with Prisma
- [x] **Testing**: Comprehensive test suites for all components

#### **Performance**
- [x] **Caching**: Redis integration for settings and frequent queries
- [x] **Pagination**: Efficient data loading with configurable limits
- [x] **Filtering**: Advanced property search with multiple criteria
- [x] **Optimization**: Vector calculations optimized for real-time use

---

### 🔄 **In Progress**

#### **Learning Algorithm** (Phase 2)
- [ ] **User Interaction Tracking**: Click, view, contact tracking
- [ ] **Preference Learning**: Update vectors based on user behavior
- [ ] **Feedback Integration**: Rating system for recommendation quality
- [ ] **Dynamic Weighting**: Automatic weight adjustment based on success rates

#### **Enhanced Features** (Phase 2)
- [ ] **Search Enhancement**: Natural language search with LLM integration
- [ ] **Geolocation**: Map-based property search and recommendations
- [ ] **Image Analysis**: Property image classification and feature extraction
- [ ] **Market Analysis**: Price prediction and market trend analysis

---

### 📋 **Planned Features**

#### **Phase 3: Advanced AI**
- [ ] **NLP Search**: "Find me a villa near a good school in Algiers under 30M DZD"
- [ ] **ChatBot Integration**: WhatsApp/Telegram bot for property inquiries
- [ ] **Predictive Analytics**: Market trends, price predictions, investment advice
- [ ] **Computer Vision**: Automatic property feature detection from images

#### **Phase 4: Platform Features**
- [ ] **Agent Dashboard**: Comprehensive agent management interface
- [ ] **Mobile Apps**: React Native iOS/Android applications
- [ ] **Multi-language**: Arabic, French, English support
- [ ] **Payment Integration**: Integrated payment processing for transactions

#### **Phase 5: Enterprise**
- [ ] **Multi-tenant**: Support for multiple real estate agencies
- [ ] **API Rate Limiting**: Advanced rate limiting and access control
- [ ] **Advanced Analytics**: Business intelligence and reporting dashboard
- [ ] **Integration APIs**: CRM, ERP, and third-party system integrations

---

## 🏗️ Technical Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client Apps   │    │   Elysia API    │    │   PostgreSQL    │
│                 │◄──►│                 │◄──►│   + pgvector    │
│ • Web Dashboard │    │ • REST Endpoints│    │                 │
│ • Mobile Apps   │    │ • Vector Math   │    │ • Users         │
│ • Admin Panel   │    │ • AI Algorithms │    │ • Properties    │
│ • Swagger UI    │    │ • Admin Settings│    │ • Settings      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                ▲
                                │
                       ┌─────────────────┐
                       │      Redis      │
                       │                 │
                       │ • Settings Cache│
                       │ • Query Cache   │
                       │ • Session Data  │
                       └─────────────────┘
```

### **Technology Stack**
- **Runtime**: Bun (high-performance JavaScript runtime)
- **Framework**: Elysia.js (type-safe web framework)
- **Database**: PostgreSQL with pgvector extension
- **Caching**: Redis with intelligent invalidation
- **ORM**: Prisma (type-safe database access)
- **Documentation**: Swagger/OpenAPI 3.0
- **Language**: TypeScript (100% type coverage)

---

## 🔍 Usage Examples

### **Basic Property Search**
```bash
curl "http://localhost:3001/api/properties?location=Algiers&propertyType=VILLA&transactionType=SALE&limit=5"
```

### **Score-Based User Search**
```bash
# Search by similarity to a target vector
curl "http://localhost:3001/api/users?similarityVector=[0.7,0.6,0.4,0.9,0.4,0.2,0.8,1.0,0.3,0.6,0.5,0.3]&minSimilarity=0.5&limit=5"

# Search by price preference (index 0)
curl "http://localhost:3001/api/users?scoreIndex=0&scoreMin=0.6&scoreMax=0.9&limit=5"

# Search by location preference (index 3) - Major cities
curl "http://localhost:3001/api/users?scoreIndex=3&scoreMin=0.8&limit=5"

# Search by property type preference (index 4) - Villa lovers
curl "http://localhost:3001/api/users?scoreIndex=4&scoreMin=0.6&limit=5"

# Combined search - Buyers with high budget in Algiers
curl "http://localhost:3001/api/users?userType=BUYER&scoreIndex=0&scoreMin=0.6&scoreIndex=3&scoreMin=0.8&limit=5"
```

### **Get Recommendations**
```bash
curl "http://localhost:3001/api/recommendations/user/USER_ID?limit=10&minScore=0.7"
```

### **Admin Settings Management**
```bash
# Update algorithm threshold
curl -X PUT \
  -H "Authorization: Bearer AGENT_ID" \
  -H "Content-Type: application/json" \
  -d '{"value": 0.5}' \
  "http://localhost:3001/api/admin/settings/recommendation_threshold"
```

### **Test Vector System**
```bash
bun run scripts/test-algeria-vectors.ts
```

### **Test Score-Based Search**
```bash
bun run test:score-search
```

---

## 🚀 Next Steps & Roadmap

### **Immediate (Next 2 weeks)**
1. **User Interaction Tracking**
   - Track property views, clicks, contacts
   - Store interaction history in database
   - Calculate engagement scores

2. **Preference Learning Algorithm**
   - Update user vectors based on interactions
   - Implement feedback loop for recommendations
   - A/B test different learning rates

3. **Enhanced Search**
   - Implement full-text search with PostgreSQL
   - Add autocomplete for locations and property types
   - Location-based radius search

### **Short-term (1-2 months)**
1. **Frontend Dashboard**
   - React-based admin dashboard
   - Property management interface
   - Analytics and reporting

2. **Mobile API**
   - Mobile-optimized endpoints
   - Image upload and processing
   - Offline capability support

3. **Advanced Analytics**
   - Market trend analysis
   - Price prediction models
   - Investment ROI calculations

### **Medium-term (3-6 months)**
1. **AI Enhancement**
   - Natural language search with LLM
   - ChatGPT-style property assistant
   - Automated property descriptions

2. **Platform Features**
   - Multi-agency support
   - White-label solutions
   - API marketplace

### **Long-term (6+ months)**
1. **Market Expansion**
   - Morocco, Tunisia support
   - Multi-currency handling
   - Localization for different markets

2. **Enterprise Features**
   - Advanced CRM integration
   - Workflow automation
   - Custom reporting tools

---

## 🤝 Contributing

### **Development Guidelines**
1. **Code Quality**: Follow TypeScript best practices
2. **Testing**: Add tests for new features
3. **Documentation**: Update API docs and README
4. **Algeria Focus**: Consider local market needs

### **Contribution Process**
1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

---

## 📄 Additional Documentation

- **[Technical Architecture](./TECHNICAL_ARCHITECTURE.md)**: Detailed system design
- **[Implementation Roadmap](./IMPLEMENTATION_ROADMAP.md)**: Development phases
- **[Project Documentation](./PROJECT_DOCUMENTATION.md)**: Complete specifications
- **[API Testing Guide](./scripts/test-admin-settings.ts)**: Testing procedures

---

## 📞 Support & Contact

For questions, suggestions, or contributions related to the Smart Contact real estate recommendation system, please:

1. **Technical Issues**: Create GitHub issues
2. **Feature Requests**: Submit detailed proposals
3. **Business Inquiries**: Contact development team

---

**🇩🇿 Proudly serving the Algerian real estate market with AI-powered precision! 🚀**

*Built with ❤️ for Algeria's digital transformation in real estate.* 