# Smart Contact: AI-Powered Real Estate Recommendation System

A sophisticated recommendation system for real estate that uses vector-based scoring and machine learning to match properties with potential buyers/tenants.

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- PostgreSQL with pgvector extension
- npm or yarn

### Installation

1. **Clone and setup**
```bash
cd project
npm install
```

2. **Environment Setup**
```bash
# The .env file is already configured with the database URL
# DATABASE_URL="postgres://postgres:PLXmyyPpWrtJZM99UdOiupWvFoSp1U1jpXEF1ofiVsUwz3SOQvlRkTJowRkaUsO3@95.179.193.54:9834/postgres"
```

3. **Database Setup**
```bash
# Generate Prisma client
npx prisma generate

# Push schema to database
npx prisma db push

# Seed with sample data
npm run seed
```

4. **Start the API Server**
```bash
npm run dev
```

The server will start on `http://localhost:3000`

## 📊 Database Schema

### Users Table
- **id**: UUID (primary key)
- **email**: String (unique)
- **name**: String
- **phone**: String (optional)
- **userType**: ENUM (BUYER, TENANT, AGENT)
- **scoreVector**: Float[8] (8-dimensional preference vector)
- **createdAt**: DateTime
- **updatedAt**: DateTime

### Properties Table
- **id**: UUID (primary key)
- **title**: String
- **description**: String (optional)
- **price**: Float
- **area**: Float
- **rooms**: Int
- **location**: String
- **propertyType**: ENUM (APARTMENT, VILLA, OFFICE, LAND)
- **furnishing**: ENUM (FURNISHED, UNFURNISHED, SEMI_FURNISHED)
- **condition**: ENUM (POOR, FAIR, GOOD, EXCELLENT)
- **transactionType**: ENUM (RENT, SALE)
- **scoreVector**: Float[8] (8-dimensional feature vector)
- **agentId**: UUID (foreign key to users)
- **status**: ENUM (ACTIVE, INACTIVE, SOLD)
- **isResidentialComplex**: Boolean
- **hasParking**: Boolean
- **hasSecurity**: Boolean
- **createdAt**: DateTime
- **updatedAt**: DateTime

## 🔧 API Endpoints

### Health Check
```http
GET /api/health
```

### Users
```http
GET /api/users                    # Get all users
GET /api/users/:id               # Get user by ID
```

### Properties
```http
GET /api/properties              # Get all properties
GET /api/properties?page=1&limit=10&location=Bab%20Ezzouar&type=APARTMENT&transactionType=SALE
GET /api/properties/:id          # Get property by ID
```

### Recommendations
```http
GET /api/recommendations/user/:id?limit=10&minScore=0.3    # Get property recommendations for user
GET /api/recommendations/property/:id?limit=10&minScore=0.3 # Get user recommendations for property
```

### Statistics
```http
GET /api/stats                   # Get system statistics
```

## 🧠 Vector-Based Scoring System

The system uses 8-dimensional vectors to represent both user preferences and property features:

1. **Price** (normalized 0-1): Based on price range 2000-41000 DA
2. **Area** (normalized 0-1): Based on area range 20-500 m²
3. **Rooms** (normalized 0-1): Based on room count (max 5)
4. **Location** (encoded 0-1): Hash-based location encoding
5. **Property Type** (encoded 0-1): apartment=0.2, villa=0.8, office=0.5, land=0.1
6. **Furnishing** (encoded 0-1): furnished=1.0, semi=0.5, unfurnished=0.0
7. **Condition** (encoded 0-1): excellent=1.0, good=0.7, fair=0.3, poor=0.0
8. **Transaction Type** (encoded 0-1): sale=1.0, rent=0.0

### Similarity Calculation
Uses cosine similarity to calculate match scores between user and property vectors.

## 📈 Sample Data

The system comes with realistic sample data:

- **25 Users**: 5 agents, 11 buyers, 9 tenants
- **50 Properties**: 27 for sale, 23 for rent
- **Locations**: Bab Ezzouar, Hydra, El Biar, Birkhadem, etc.
- **Property Types**: Apartments, villas, offices, land
- **Features**: Residential complexes, parking, security

## 🛠️ Development

### Available Scripts
```bash
npm run dev          # Start development server
npm run seed         # Seed database with sample data
npm run test         # Run database tests
npm run build        # Build for production
npm start            # Start production server
```

### Testing the System
```bash
# Test database operations
npm test

# Test API endpoints
curl http://localhost:3000/api/health
curl http://localhost:3000/api/stats
curl "http://localhost:3000/api/properties?limit=3"
```

## 🎯 Current Features

### ✅ Implemented
- Database schema with vector support
- User and property management
- Vector similarity calculations
- Recommendation system
- RESTful API endpoints
- Sample data generation
- Basic filtering and pagination

### 🔄 In Progress
- Learning algorithm for user preferences
- Interaction tracking system
- Search functionality
- Authentication system

### 📋 Planned
- Natural language search with LLM
- Agent dashboard
- Advanced analytics
- Performance optimization

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client Apps   │    │   Express API   │    │   PostgreSQL    │
│                 │◄──►│                 │◄──►│   + pgvector    │
│ • Web App       │    │ • REST Endpoints│    │                 │
│ • Mobile App    │    │ • Vector Math   │    │ • Users         │
│ • Dashboard     │    │ • Recommendations│   │ • Properties    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔍 Example Usage

### Get Property Recommendations for a User
```bash
curl "http://localhost:3000/api/recommendations/user/USER_ID?limit=5"
```

Response:
```json
{
  "success": true,
  "data": [
    {
      "property": {
        "id": "...",
        "title": "Villa luxueuse avec jardin privé",
        "location": "Hydra",
        "price": 25000,
        "similarity": 0.94
      }
    }
  ],
  "user": {
    "id": "...",
    "name": "User 1",
    "userType": "BUYER"
  }
}
```

### Filter Properties
```bash
curl "http://localhost:3000/api/properties?location=Bab%20Ezzouar&type=APARTMENT&transactionType=SALE&limit=10"
```

## 📚 Documentation

- [Project Documentation](./PROJECT_DOCUMENTATION.md)
- [Implementation Roadmap](./IMPLEMENTATION_ROADMAP.md)
- [Technical Architecture](./TECHNICAL_ARCHITECTURE.md)
- [Progress Tracking](./progress.md)

## 🤝 Contributing

1. Follow the existing code structure
2. Add tests for new features
3. Update documentation
4. Use TypeScript for type safety

## 📄 License

This project is part of the Smart Contact real estate recommendation system.

---

**Ready to revolutionize real estate matching with AI! 🚀** 