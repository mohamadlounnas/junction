# 🤖 AI Agent Integration Guide - Smart Contact Real Estate System

## 📋 System Overview

You are integrating with **Smart Contact**, an AI-powered real estate recommendation system designed specifically for the Algerian market. This system uses advanced **12-dimensional vector scoring** and **machine learning algorithms** to match properties with potential buyers/tenants.

### 🎯 Your Mission
- Connect to PostgreSQL database with pgvector extension
- Generate property-to-contact recommendations using LLMs
- Enhance the existing vector-based scoring with natural language processing
- Process bulk recommendations efficiently

---

## 🗄️ Database Connection Details

### **Primary Database (PostgreSQL)**
```
Host: 95.179.193.54
Port: 9834
Database: postgres
Username: postgres
Password: PLXmyyPpWrtJZM99UdOiupWvFoSp1U1jpXEF1ofiVsUwz3SOQvlRkTJowRkaUsO3
```

### **Cache Layer (Redis - Optional)**
```
Host: 95.179.193.54
Port: 7739
Database: 0
Password: kgq7lDyxL9wTxBrNUmqj0xneZ0HJB68vmOXbnIHg0ZwuvB1Aj9klv9nvrs2mHAsq
```

### **API Base URL**
```
http://localhost:3001/api
```

---

## 📊 Core Database Schema

### **Contact Table**
```sql
TABLE "Contact" {
  -- Core Identity
  id                     TEXT PRIMARY KEY
  email                  TEXT UNIQUE NOT NULL
  name                   TEXT NOT NULL
  phone                  TEXT
  type                   TEXT NOT NULL -- 'BUYER' | 'TENANT' | 'INVESTOR'
  
  -- Financial Preferences
  budgetMin              DECIMAL
  budgetMax              DECIMAL
  
  -- Location Preferences (Algeria-specific)
  locationWilayas        TEXT[] -- ['Algiers', 'Oran', 'Constantine']
  locationCities         TEXT[] -- ['Hydra', 'Ben Aknoun', 'Dely Ibrahim']
  
  -- Property Preferences
  propertyTypes          TEXT[] -- ['APARTMENT', 'VILLA', 'HOUSE', 'OFFICE']
  minRooms               INTEGER
  maxRooms               INTEGER
  minArea                DECIMAL -- Square meters
  maxArea                DECIMAL
  furnishingType         TEXT -- 'FURNISHED' | 'SEMI_FURNISHED' | 'UNFURNISHED'
  preferredCondition     TEXT -- 'POOR' | 'FAIR' | 'GOOD' | 'EXCELLENT' | 'NEW'
  
  -- Transaction Preferences (Enhanced Dual Support)
  transactionType        TEXT NOT NULL -- Legacy: 'RENT' | 'SALE'
  transactionTypes       TEXT[] -- Enhanced: ['RENT', 'SALE'] for flexible buyers
  primaryTransactionType TEXT -- Primary preference when multiple types
  transactionFlexibility DECIMAL DEFAULT 0.5 -- 0=rigid, 1=very flexible
  
  -- Family Context
  familySize             INTEGER
  hasChildren            BOOLEAN DEFAULT FALSE
  
  -- Requirements
  requiresParking        BOOLEAN DEFAULT FALSE
  requiresSecurity       BOOLEAN DEFAULT FALSE
  
  -- AI Vectors (CRITICAL FOR RECOMMENDATIONS)
  scores                 DECIMAL[12] -- 12D preference vector
  transactionScores      DECIMAL[2] -- [rentScore, saleScore]
  
  -- Status
  isActive               BOOLEAN DEFAULT TRUE
  notes                  TEXT
  createdAt              TIMESTAMP DEFAULT NOW()
  updatedAt              TIMESTAMP DEFAULT NOW()
}
```

### **Property Table**
```sql
TABLE "Property" {
  -- Core Identity
  id              TEXT PRIMARY KEY
  title           TEXT NOT NULL
  description     TEXT
  
  -- Physical Characteristics
  price           DECIMAL NOT NULL -- Price in DZD (Algerian Dinar)
  area            DECIMAL NOT NULL -- Square meters
  rooms           INTEGER NOT NULL
  bathrooms       INTEGER
  
  -- Location (Algeria Administrative Divisions)
  wilaya          TEXT NOT NULL -- Administrative division (48 wilayas)
  city            TEXT NOT NULL
  address         TEXT
  latitude        DECIMAL
  longitude       DECIMAL
  
  -- Property Details
  propertyType    TEXT NOT NULL -- 'APARTMENT' | 'VILLA' | 'HOUSE' | 'OFFICE' | 'SHOP' | 'WAREHOUSE' | 'LAND' | 'GARAGE'
  transactionType TEXT NOT NULL -- 'RENT' | 'SALE'
  furnishing      TEXT NOT NULL -- 'FURNISHED' | 'SEMI_FURNISHED' | 'UNFURNISHED'
  condition       TEXT NOT NULL -- 'POOR' | 'FAIR' | 'GOOD' | 'EXCELLENT' | 'NEW'
  
  -- Amenities (Boolean Features)
  hasParking      BOOLEAN DEFAULT FALSE
  hasSecurity     BOOLEAN DEFAULT FALSE
  hasElevator     BOOLEAN DEFAULT FALSE
  hasGarden       BOOLEAN DEFAULT FALSE
  hasBalcony      BOOLEAN DEFAULT FALSE
  hasSwimmingPool BOOLEAN DEFAULT FALSE
  
  -- Building Information
  buildingAge     INTEGER -- Years
  floor           INTEGER
  totalFloors     INTEGER
  
  -- AI Vector (CRITICAL FOR RECOMMENDATIONS)
  scores          DECIMAL[12] -- 12D feature vector
  
  -- Status & Marketing
  status          TEXT DEFAULT 'AVAILABLE' -- 'AVAILABLE' | 'RESERVED' | 'SOLD' | 'RENTED' | 'INACTIVE'
  ownerId         TEXT
  viewCount       INTEGER DEFAULT 0
  featured        BOOLEAN DEFAULT FALSE
  
  -- Timestamps
  createdAt       TIMESTAMP DEFAULT NOW()
  updatedAt       TIMESTAMP DEFAULT NOW()
  
  -- Geospatial Optimization
  geohash         TEXT
  geohashPrecision5 TEXT
  geohashPrecision6 TEXT
  geohashPrecision7 TEXT
}
```

### **Sale Table** (Learning Data)
```sql
TABLE "Sale" {
  id             TEXT PRIMARY KEY
  contactId      TEXT REFERENCES "Contact"(id)
  propertyId     TEXT REFERENCES "Property"(id)
  salePrice      DECIMAL NOT NULL
  saleDate       TIMESTAMP DEFAULT NOW()
  successScore   DECIMAL NOT NULL -- 0-1 rating (CRITICAL for learning)
  timeToDecision INTEGER -- Days to make decision
  viewCount      INTEGER
  notes          TEXT
  createdAt      TIMESTAMP DEFAULT NOW()
}
```

---

## 🧠 AI Vector System (12-Dimensional)

### **Vector Structure**
Each contact and property is represented as a **12-dimensional vector** where each dimension (0-11) represents:

```typescript
VECTOR_DIMENSIONS = {
  0:  BUDGET,        // Budget/price preference (0-1, normalized)
  1:  AREA,          // Area preference (0-1, normalized) 
  2:  ROOMS,         // Room count preference (0-1, normalized)
  3:  LOCATION,      // Location desirability (0-1, Algeria-specific)
  4:  PROPERTY_TYPE, // Property type preference (0-1)
  5:  CONDITION,     // Property condition preference (0-1)
  6:  FEATURES,      // Amenities/features score (0-1)
  7:  FAMILY,        // Family-friendliness (0-1)
  8:  MODERN,        // Modernity/newness preference (0-1)
  9:  INVESTMENT,    // Investment potential (0-1)
  10: URGENCY,       // Urgency to buy/rent (0-1)
  11: TRANSACTION    // Transaction type (RENT=0, SALE=1)
}
```

### **Algeria-Specific Scoring Constants**

#### **Wilaya Desirability Scores (Location Dimension)**
```typescript
ALGERIA_WILAYAS = {
  'Algiers': 0.95,     // Capital - highest desirability
  'Oran': 0.92,        // Major port city
  'Constantine': 0.90, // Historical city
  'Annaba': 0.85,      // Coastal city
  'Boumerdès': 0.85,   // Near Algiers
  'Tipaza': 0.88,      // Coastal, near Algiers
  'Batna': 0.75,       // Mountain region
  'Sétif': 0.75,       // Agricultural hub
  'Béjaïa': 0.80,      // Coastal Berber region
  'Tlemcen': 0.75,     // Western border
  'Biskra': 0.68,      // Desert gateway
  'Ghardaïa': 0.70,    // M'zab valley
  'Tamanrasset': 0.45, // Deep south
  'Tindouf': 0.50,     // Western Sahara border
  'Illizi': 0.45       // Southeastern desert
  // ... (48 wilayas total)
}
```

#### **Property Type Scores**
```typescript
PROPERTY_TYPE_SCORES = {
  VILLA: 0.8,        // Luxury - highest value
  HOUSE: 0.6,        // Family homes
  APARTMENT: 0.3,    // Most common
  OFFICE: 0.4,       // Commercial
  SHOP: 0.2,         // Retail
  WAREHOUSE: 0.1,    // Industrial
  LAND: 0.1,         // Development potential
  GARAGE: 0.05       // Utility - lowest value
}
```

#### **Condition Quality Scores**
```typescript
CONDITION_SCORES = {
  NEW: 1.0,          // Brand new construction
  EXCELLENT: 0.9,    // Recently renovated
  GOOD: 0.7,         // Well-maintained
  FAIR: 0.3,         // Needs minor work
  POOR: 0.1          // Needs major renovation
}
```

### **Vector Generation Logic**

#### **For Contacts (Preferences):**
```typescript
// Budget: 2M DZD = 0.1, 50M DZD = 1.0
scores[0] = Math.min(1.0, Math.max(0.1, (avgBudget - 2000000) / 48000000));

// Area: 30m² = 0.1, 500m² = 1.0  
scores[1] = Math.min(1.0, Math.max(0.1, (avgArea - 30) / 470));

// Rooms: 1 room = 0.1, 6+ rooms = 1.0
scores[2] = Math.min(1.0, Math.max(0.1, (avgRooms - 1) / 5));

// Location: Use wilaya desirability
scores[3] = ALGERIA_WILAYAS[preferredWilaya] || 0.3;

// Property Type: Average of preferred types
scores[4] = averageOf(preferredTypes.map(type => PROPERTY_TYPE_SCORES[type]));

// Condition: Preferred quality level
scores[5] = CONDITION_SCORES[preferredCondition] || 0.5;

// Features: Parking + Security + other amenities
scores[6] = (requiresParking * 0.2) + (requiresSecurity * 0.3) + baseScore;

// Family: Based on children and family size
scores[7] = hasChildren || familySize > 2 ? 0.9 : (familySize === 1 ? 0.2 : 0.5);

// Modern: Based on condition preference and features
scores[8] = modernityPreference; // 0.2-0.8 based on preferences

// Investment: Based on contact type and budget level
scores[9] = contactType === 'INVESTOR' ? 0.9 : (budget > high ? 0.6 : 0.3);

// Urgency: Based on contact type (tenants = high urgency)
scores[10] = contactType === 'TENANT' ? 0.7 : 0.5;

// Transaction: RENT = 0.0, SALE = 1.0
scores[11] = transactionType === 'SALE' ? 1.0 : 0.0;
```

#### **For Properties (Characteristics):**
Properties use the same scoring logic but based on actual features rather than preferences.

### **Similarity Calculation**
```typescript
function calculateCosineSimilarity(vector1: number[], vector2: number[]): number {
  const dotProduct = vector1.reduce((sum, v1, i) => sum + v1 * vector2[i], 0);
  const magnitude1 = Math.sqrt(vector1.reduce((sum, v) => sum + v * v, 0));
  const magnitude2 = Math.sqrt(vector2.reduce((sum, v) => sum + v * v, 0));
  
  if (magnitude1 === 0 || magnitude2 === 0) return 0;
  return dotProduct / (magnitude1 * magnitude2);
}
```

---

## 🔗 API Endpoints Reference

### **1. Contact Property Recommendations**
```http
GET /recommendations/contact/{contactId}?limit=10&minSimilarity=0.3&propertyType=VILLA&wilaya=Algiers

Response Structure:
{
  "success": true,
  "data": {
    "contact": {
      "id": "contact_123",
      "name": "Ahmed Benali",
      "type": "BUYER",
      "transactionType": "SALE",
      "transactionTypes": ["SALE", "RENT"], // Enhanced dual support
      "primaryTransactionType": "SALE",
      "transactionFlexibility": 0.7
    },
    "recommendations": [
      {
        "property": {
          "id": "prop_456",
          "title": "Villa 200m² Hydra, Algiers",
          "price": 25000000, // DZD
          "area": 200,
          "rooms": 4,
          "wilaya": "Algiers",
          "city": "Hydra",
          "propertyType": "VILLA",
          "transactionType": "SALE",
          "condition": "EXCELLENT"
        },
        "similarity": 0.875,        // Cosine similarity score
        "combinedScore": 0.845,     // Includes success history
        "matchType": "primary",     // or "fallback"
        "explanation": "Excellent match, Budget perfect fit, Preferred location, Property type match"
      }
    ],
    "metadata": {
      "primaryMatches": 5,
      "fallbackMatches": 0,
      "totalAvailableProperties": 150,
      "fallbackUsed": false
    }
  }
}
```

### **2. Property Contact Recommendations**
```http
GET /recommendations/property/{propertyId}?limit=10&minSimilarity=0.3&contactType=BUYER

Response: Array of matching contacts with similarity scores
```

### **3. Bulk Property Processing**
```http
POST /recommendations/bulk
Content-Type: application/json

{
  "propertyIds": ["prop_1", "prop_2", "prop_3"],
  "minSimilarity": 0.3,
  "limit": 10
}

Response: Recommendations for each property
```

### **4. Batch Multi-Processing**
```http
POST /recommendations/batch-process
Content-Type: application/json

{
  "contactIds": ["contact_1", "contact_2"],
  "propertyIds": ["prop_1", "prop_2", "prop_3"],
  "minSimilarity": 0.3,
  "limit": 5
}

Response: Contact-centric recommendation matrix
```

### **5. Analytics Dashboard**
```http
GET /recommendations/analytics

Response: System performance metrics, success rates, algorithm effectiveness
```

---

## 🚀 pgvector Integration Guide

### **Setup pgvector Extension**
```sql
-- Enable vector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Add vector columns to existing tables
ALTER TABLE "Contact" ADD COLUMN IF NOT EXISTS vector_embedding vector(12);
ALTER TABLE "Property" ADD COLUMN IF NOT EXISTS vector_embedding vector(12);

-- Create HNSW indexes for fast similarity search
CREATE INDEX IF NOT EXISTS contact_vector_idx 
ON "Contact" USING hnsw (vector_embedding vector_cosine_ops);

CREATE INDEX IF NOT EXISTS property_vector_idx 
ON "Property" USING hnsw (vector_embedding vector_cosine_ops);
```

### **Vector Operations**
```sql
-- Insert/Update vectors (convert from scores array)
UPDATE "Contact" 
SET vector_embedding = scores::vector 
WHERE vector_embedding IS NULL;

UPDATE "Property" 
SET vector_embedding = scores::vector 
WHERE vector_embedding IS NULL;

-- Similarity search (find similar contacts to a property)
SELECT 
  c.id,
  c.name,
  c.email,
  c.type,
  c.budgetMin,
  c.budgetMax,
  1 - (c.vector_embedding <=> p.vector_embedding) as similarity_score
FROM "Contact" c, "Property" p
WHERE p.id = $1 
  AND c.isActive = true
  AND (1 - (c.vector_embedding <=> p.vector_embedding)) >= $2
ORDER BY c.vector_embedding <=> p.vector_embedding
LIMIT $3;

-- Find similar properties for a contact
SELECT 
  p.id,
  p.title,
  p.price,
  p.area,
  p.rooms,
  p.wilaya,
  p.city,
  p.propertyType,
  1 - (p.vector_embedding <=> c.vector_embedding) as similarity_score
FROM "Property" p, "Contact" c
WHERE c.id = $1 
  AND p.status = 'AVAILABLE'
  AND p.transactionType = ANY(c.transactionTypes) -- Enhanced transaction matching
  AND (1 - (p.vector_embedding <=> c.vector_embedding)) >= $2
ORDER BY p.vector_embedding <=> c.vector_embedding
LIMIT $3;
```

---

## 🤖 LLM Integration Strategies

### **1. Natural Language Query Processing**
Convert user descriptions to structured preferences:

```typescript
// Example user input
userInput: "I'm looking for a modern family villa in Algiers with a garden and parking, budget around 30 million DZD"

// LLM Processing Task
extractPreferences(userInput) → {
  propertyTypes: ['VILLA'],
  locationWilayas: ['Algiers'],
  budgetMin: 25000000,
  budgetMax: 35000000,
  preferredCondition: 'EXCELLENT' | 'NEW',
  requiresParking: true,
  hasGarden: true,
  familyContext: true
}
```

### **2. Explanation Enhancement**
Generate human-readable explanations for similarity scores:

```typescript
// Input: similarity breakdown
vectorDifferences: {
  budget: 0.9,     // Very close match
  location: 0.95,  // Excellent location match  
  propertyType: 1.0, // Perfect type match
  condition: 0.8,  // Good condition match
  features: 0.7    // Some features match
}

// LLM Task: Generate explanation
generateExplanation(vectorDifferences, contact, property) → 
"Excellent match! This villa perfectly matches your property type preference and is in your highly desired Algiers location. The budget aligns well with your 25-35M DZD range at 28M DZD. The property is in excellent condition, which matches your preference for modern homes. It includes the parking and garden you requested, plus additional amenities like security."
```

### **3. Market Intelligence**
Analyze trends and provide insights:

```typescript
// Analyze successful sales patterns
marketAnalysis(wilaya, propertyType, timeRange) → {
  averagePrice: number,
  priceChangeTrend: 'increasing' | 'stable' | 'decreasing',
  demandLevel: 'high' | 'medium' | 'low',
  averageTimeToSale: number,
  hotFeatures: string[], // ['hasParking', 'hasGarden']
  recommendation: string
}
```

### **4. Dynamic Vector Adjustment**
Use LLM to suggest vector weight adjustments based on market conditions:

```typescript
// Seasonal/market adjustments
adjustVectorWeights(currentWeights, marketConditions, season) → {
  budget: 0.25,      // Increased importance during high-price periods
  location: 0.20,    // Standard
  features: 0.15,    // Increased for luxury market
  urgency: 0.05      // Decreased during slow periods
}
```

---

## 📊 Learning & Optimization

### **Continuous Learning from Sales**
```typescript
// When a sale occurs, update contact preferences
function learnFromSuccessfulSale(contactId: string, propertyId: string, saleData: {
  successScore: number,    // 0-1 rating
  salePrice: number,
  timeToDecision: number   // Days
}) {
  // Learning algorithm adjusts contact vector toward successful property characteristics
  learningRate = 0.1;
  successWeight = saleData.successScore;
  
  for (dimension = 0; dimension < 12; dimension++) {
    adjustment = learningRate * successWeight * (property.scores[dimension] - contact.scores[dimension]);
    contact.scores[dimension] += adjustment;
  }
}
```

### **Genetic Algorithm Enhancement**
For advanced optimization (optional):

```typescript
// Genetic algorithm parameters
GA_CONFIG = {
  POPULATION_SIZE: 20,      // Vector variants per contact
  MUTATION_RATE: 0.15,      // 15% mutation chance
  CROSSOVER_RATE: 0.8,      // 80% crossover chance
  GENERATIONS: 50,          // Evolution cycles
  ELITE_SIZE: 4             // Top performers preserved
}
```

---

## 🎯 Implementation Tasks for AI Agent

### **Priority 1: Basic Integration**
1. **Database Connection**: Connect to PostgreSQL and verify table access
2. **Vector Reading**: Read existing 12D vectors from `scores` columns
3. **Similarity Calculation**: Implement cosine similarity in your LLM workflow
4. **Basic Recommendations**: Generate property recommendations for given contact

### **Priority 2: Enhanced Processing**
1. **pgvector Setup**: Install extension and create vector columns
2. **Bulk Processing**: Handle multiple contacts/properties simultaneously
3. **Explanation Generation**: Create human-readable explanations using LLM
4. **Query Processing**: Convert natural language to structured preferences

### **Priority 3: Advanced Features**
1. **Learning Integration**: Update vectors based on successful sales
2. **Market Analysis**: Provide market insights and trends
3. **Dynamic Weighting**: Adjust algorithm based on market conditions
4. **Performance Optimization**: Implement caching and batch processing

### **Testing Checklist**
- [ ] Can connect to database successfully
- [ ] Can read contact and property vectors
- [ ] Can calculate similarity scores correctly
- [ ] Can generate recommendations with explanations
- [ ] Can handle bulk processing requests
- [ ] Can update vectors based on learning data
- [ ] Can process natural language queries
- [ ] Performance meets requirements (< 2s for 50 recommendations)

---

## 🚨 Important Notes & Constraints

### **Data Sensitivity**
- All prices are in **Algerian Dinar (DZD)**
- Location data uses **Algerian administrative divisions** (48 wilayas)
- Cultural considerations: Family-oriented preferences, multi-generational housing

### **Performance Requirements**
- **Response Time**: < 2 seconds for 10 recommendations
- **Batch Processing**: Handle up to 50x50 combinations
- **Concurrent Users**: Support 100+ simultaneous requests
- **Accuracy Target**: > 85% relevant recommendations

### **System Limitations**
- Vectors must be exactly 12 dimensions
- Similarity scores range 0-1 (cosine similarity)
- Minimum similarity threshold typically 0.3
- Maximum batch size: 50 contacts × 50 properties

### **Error Handling**
- Always validate vector dimensions
- Handle missing or null vectors gracefully
- Provide fallback recommendations when primary matches < 3
- Log all errors for debugging

### **Integration Points**
- **REST API**: Primary interface for recommendations
- **Direct Database**: For bulk operations and analytics
- **Redis Cache**: For performance optimization
- **Webhook Support**: For real-time notifications (future)

---

## 🔧 Sample Integration Code

### **Python/n8n Integration Example**
```python
import psycopg2
import numpy as np
from pgvector import register_vector

# Database connection
conn = psycopg2.connect(
    host="95.179.193.54",
    port=9834,
    database="postgres",
    user="postgres", 
    password="PLXmyyPpWrtJZM99UdOiupWvFoSp1U1jpXEF1ofiVsUwz3SOQvlRkTJowRkaUsO3"
)
register_vector(conn)

def get_recommendations(contact_id: str, limit: int = 10, min_similarity: float = 0.3):
    """Get property recommendations for a contact using pgvector"""
    with conn.cursor() as cur:
        # Get contact vector
        cur.execute("SELECT vector_embedding FROM Contact WHERE id = %s", (contact_id,))
        contact_vector = cur.fetchone()[0]
        
        # Find similar properties
        cur.execute("""
            SELECT 
                p.id, p.title, p.price, p.area, p.rooms, p.wilaya,
                1 - (p.vector_embedding <=> %s) as similarity
            FROM Property p
            WHERE p.status = 'AVAILABLE'
              AND (1 - (p.vector_embedding <=> %s)) >= %s
            ORDER BY p.vector_embedding <=> %s
            LIMIT %s
        """, (contact_vector, contact_vector, min_similarity, contact_vector, limit))
        
        return cur.fetchall()

def cosine_similarity(vec1, vec2):
    """Calculate cosine similarity between two vectors"""
    dot_product = np.dot(vec1, vec2)
    magnitude1 = np.linalg.norm(vec1)
    magnitude2 = np.linalg.norm(vec2)
    
    if magnitude1 == 0 or magnitude2 == 0:
        return 0
    return dot_product / (magnitude1 * magnitude2)
```

This comprehensive guide provides everything your AI agent needs to understand and integrate with the Smart Contact recommendation system. The system is production-ready and optimized for the Algerian real estate market with cultural, geographic, and economic considerations built-in. 