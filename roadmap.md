# Smart Contact: Real Estate Recommendation System
## Project Roadmap & Implementation Plan

---

## 🎯 Project Overview

**Smart Contact** is an AI-powered recommendation system for real estate agents in Algeria that automatically matches properties with potential buyers/tenants using vector-based scoring and machine learning algorithms.

### Key Innovation: Universal Scoring System
- **Both users and properties share the same vector format**: `[size, price, rooms, quality, furnishing, type, location, ...]`
- **Dynamic Learning**: User scores evolve based on interactions (view, like, share, contact)
- **Dual Search Modes**: Static filters + Natural language processing via LLM

---

## 🏗️ System Architecture

### Microservices Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   API Gateway   │    │   Auth Service  │
│   (React/Vue)   │────│   (Node.js)     │────│   (Node.js)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                ┌───────────────┼───────────────┐
                │               │               │
    ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
    │ Recommendation  │ │   Core API      │ │   LLM Service   │
    │ Engine (Python) │ │  (Node.js)      │ │   (Python)      │
    └─────────────────┘ └─────────────────┘ └─────────────────┘
                │               │               │
        ┌───────────────────────┼───────────────┐
        │                       │               │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │     Redis       │    │   File Storage  │
│   (Main DB)     │    │   (Caching)     │    │   (Images/PDFs) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## 📊 Core Scoring System

### Vector Format (10 dimensions)
```javascript
[
  size_score,      // 0.0-1.0 (normalized area)
  price_score,     // 0.0-1.0 (normalized price)
  rooms_score,     // 0.0-1.0 (normalized room count)
  quality_score,   // 0.0-1.0 (finishing quality)
  furnishing_score,// 0.0-1.0 (furnished=1.0, unfurnished=0.0)
  type_score,      // 0.0-1.0 (apartment=0.0, villa=0.5, office=1.0)
  location_score,  // 0.0-1.0 (based on location embedding)
  parking_score,   // 0.0-1.0 (parking availability)
  floor_score,     // 0.0-1.0 (normalized floor number)
  age_score        // 0.0-1.0 (property age, newer=higher)
]
```

### Similarity Algorithm
- **Primary**: Cosine Similarity
- **Fallback**: Euclidean Distance
- **Weighted**: Important features can have multipliers

### Learning Algorithm
```python
def update_user_score(user_vector, property_vector, interaction_weight):
    learning_rate = 0.05 * interaction_weight
    return user_vector + learning_rate * (property_vector - user_vector)

# Interaction weights:
# view: 0.1, like: 0.3, share: 0.5, contact: 0.8, purchase: 1.0
```

---

## 🛢️ Database Schema

### Core Tables

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    user_type ENUM('client', 'agent') NOT NULL,
    scores DECIMAL(3,2)[] CHECK (array_length(scores, 1) = 10),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Properties table
CREATE TABLE properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(12,2) NOT NULL,
    area_sqm INTEGER NOT NULL,
    rooms INTEGER NOT NULL,
    property_type ENUM('apartment', 'villa', 'office', 'shop') NOT NULL,
    location_id UUID REFERENCES locations(id),
    quality_rating INTEGER CHECK (quality_rating BETWEEN 1 AND 5),
    is_furnished BOOLEAN DEFAULT FALSE,
    has_parking BOOLEAN DEFAULT FALSE,
    floor_number INTEGER,
    building_age INTEGER,
    scores DECIMAL(3,2)[] CHECK (array_length(scores, 1) = 10),
    status ENUM('active', 'sold', 'rented', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Locations table (for location embedding)
CREATE TABLE locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    coordinates POINT,
    embedding_score DECIMAL(3,2) DEFAULT 0.5
);

-- User interactions (for learning)
CREATE TABLE user_interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    property_id UUID REFERENCES properties(id),
    interaction_type ENUM('view', 'like', 'share', 'contact', 'purchase') NOT NULL,
    interaction_weight DECIMAL(3,2) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Property images
CREATE TABLE property_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id),
    image_url VARCHAR(500) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Indexing Strategy
```sql
-- Performance indexes
CREATE INDEX idx_properties_scores ON properties USING GIN (scores);
CREATE INDEX idx_users_scores ON users USING GIN (scores);
CREATE INDEX idx_properties_location ON properties (location_id);
CREATE INDEX idx_properties_price_range ON properties (price, area_sqm);
CREATE INDEX idx_interactions_user_time ON user_interactions (user_id, created_at DESC);
```

---

## 🚀 API Endpoints

### Core Recommendation API

```typescript
// GET /api/recommendations/property/:id
// Returns recommended users for a property
interface PropertyRecommendationResponse {
  property_id: string;
  recommendations: {
    user_id: string;
    user_name: string;
    user_contact: string;
    match_score: number;
    explanation: string[];
  }[];
  total_matches: number;
}

// GET /api/recommendations/user/:id  
// Returns recommended properties for a user
interface UserRecommendationResponse {
  user_id: string;
  recommendations: {
    property_id: string;
    property_title: string;
    match_score: number;
    explanation: string[];
    images: string[];
  }[];
  total_matches: number;
}

// POST /api/search/static
// Search using static filters
interface StaticSearchRequest {
  user_id?: string;
  filters: {
    price_min?: number;
    price_max?: number;
    area_min?: number;
    area_max?: number;
    rooms?: number[];
    property_type?: string[];
    location_ids?: string[];
    is_furnished?: boolean;
    has_parking?: boolean;
  };
  page?: number;
  limit?: number;
}

// POST /api/search/natural
// Search using natural language
interface NaturalSearchRequest {
  user_id?: string;
  query: string; // "أبحث عن شقة صغيرة في باب الزوار بسعر معقول"
  page?: number;
  limit?: number;
}

// POST /api/interactions
// Record user interactions for learning
interface InteractionRequest {
  user_id: string;
  property_id: string;
  interaction_type: 'view' | 'like' | 'share' | 'contact' | 'purchase';
}
```

### Agent Dashboard API

```typescript
// GET /api/agent/analytics/:agent_id
interface AgentAnalytics {
  total_properties: number;
  active_properties: number;
  total_interactions: number;
  top_performing_properties: PropertyPerformance[];
  user_interests: UserInterest[];
}

// GET /api/agent/users/similar/:user_id
// Find users similar to a specific user
interface SimilarUsersResponse {
  similar_users: {
    user_id: string;
    similarity_score: number;
    shared_interests: string[];
  }[];
}

// POST /api/properties/compare
// Compare two properties and generate PDF quote
interface PropertyComparisonRequest {
  property_ids: [string, string];
  user_id?: string;
}
```

---

## 🤖 AI Components

### 1. Score Normalization Engine
```python
class ScoreNormalizer:
    def normalize_property(self, property_data):
        # Convert raw property data to 0-1 scores
        return [
            self.normalize_area(property_data.area_sqm),
            self.normalize_price(property_data.price),
            self.normalize_rooms(property_data.rooms),
            # ... other normalizations
        ]
    
    def normalize_area(self, area):
        # Min: 20sqm, Max: 500sqm
        return min(1.0, max(0.0, (area - 20) / 480))
```

### 2. Similarity Engine
```python
class SimilarityEngine:
    def cosine_similarity(self, vector_a, vector_b):
        return np.dot(vector_a, vector_b) / (
            np.linalg.norm(vector_a) * np.linalg.norm(vector_b)
        )
    
    def find_similar_properties(self, user_vector, properties, limit=10):
        similarities = []
        for prop in properties:
            score = self.cosine_similarity(user_vector, prop.scores)
            similarities.append((prop, score))
        
        return sorted(similarities, key=lambda x: x[1], reverse=True)[:limit]
```

### 3. Learning Engine
```python
class LearningEngine:
    INTERACTION_WEIGHTS = {
        'view': 0.1,
        'like': 0.3,
        'share': 0.5,
        'contact': 0.8,
        'purchase': 1.0
    }
    
    def update_user_preferences(self, user_scores, property_scores, interaction_type):
        weight = self.INTERACTION_WEIGHTS[interaction_type]
        learning_rate = 0.05 * weight
        
        # Move user scores closer to property scores
        new_scores = user_scores + learning_rate * (property_scores - user_scores)
        return np.clip(new_scores, 0.0, 1.0)
```

### 4. LLM Integration (Natural Language Processing)
```python
class NaturalLanguageProcessor:
    def parse_search_query(self, query_text):
        # Use Gemini/OpenAI to extract structured data
        prompt = f"""
        Parse this Arabic real estate search query into structured filters:
        Query: "{query_text}"
        
        Return JSON with:
        - price_range: [min, max] in DZD
        - area_range: [min, max] in sqm  
        - rooms: number or range
        - property_type: apartment/villa/office
        - location: city/area name
        - furnishing: furnished/unfurnished/any
        - special_features: parking, garden, etc.
        """
        
        # Call LLM API and parse response
        return self.call_llm_api(prompt)
```

---

## 📱 User Experience Flow

### Client Flow
1. **Registration**: User creates account with basic preferences
2. **Initial Scoring**: Random scores assigned, refined through onboarding questions
3. **Feed View**: Personalized property feed based on user scores
4. **Search Options**:
   - Static filters → Generate search vector → Find matches
   - Natural text → LLM parsing → Generate search vector → Find matches
5. **Interactions**: Every action updates user scores
6. **Learning**: System becomes more accurate over time

### Agent Flow
1. **Dashboard**: Overview of properties, users, and analytics
2. **Property Management**: CRUD operations with automatic score generation
3. **User Insights**: View user scores and find similar users
4. **Recommendations**: Get best user matches for each property
5. **Analytics**: Performance metrics and user behavior insights

---

## 🔧 Technology Stack

### Backend Services
- **Core API**: Node.js + Express + TypeScript
- **AI Engine**: Python + FastAPI + NumPy + Scikit-learn
- **LLM Service**: Python + OpenAI/Gemini API
- **Database**: PostgreSQL 15+ with vector extensions
- **Caching**: Redis for session management and frequent queries
- **Message Queue**: Bull (Redis-based) for async processing

### Frontend
- **Web App**: React + TypeScript + Tailwind CSS
- **State Management**: Zustand or Redux Toolkit
- **API Client**: Axios with React Query

### DevOps & Infrastructure
- **Containerization**: Docker + Docker Compose
- **API Gateway**: nginx or Traefik
- **Monitoring**: Prometheus + Grafana
- **Logging**: Winston + ELK Stack
- **File Storage**: AWS S3 or MinIO

---

## 📈 Performance & Scalability

### Target Performance
- **User Recommendations**: < 200ms response time
- **Search Results**: < 500ms response time
- **Concurrent Users**: 10,000+
- **Database Size**: 100,000+ users, 1M+ properties

### Optimization Strategies
1. **Database Indexing**: GIN indexes for vector similarity
2. **Caching**: Redis for frequent queries and user sessions
3. **Vector Search**: Consider Pinecone or Weaviate for large-scale similarity search
4. **CDN**: CloudFlare for static assets and API caching
5. **Database Partitioning**: Partition by location/price range for large datasets

### Monitoring Metrics
- API response times
- Database query performance
- Cache hit rates
- User engagement metrics
- Recommendation accuracy (click-through rates)

---

## 🧪 Testing Strategy

### Unit Tests
- Score normalization functions
- Similarity calculations
- Learning algorithm updates
- API endpoint logic

### Integration Tests
- Database operations
- External API calls (LLM services)
- Service communication

### Performance Tests
- Load testing with 10,000+ concurrent users
- Database performance under heavy load
- Memory usage optimization

### A/B Testing
- Different similarity algorithms
- Learning rate adjustments
- UI/UX variations

---

## 🚀 Deployment Plan

### Phase 1: MVP (4-6 weeks)
- ✅ Basic API endpoints
- ✅ Property and user CRUD
- ✅ Simple similarity search
- ✅ Static filter search
- ✅ Basic agent dashboard

### Phase 2: AI Integration (3-4 weeks)
- ✅ Learning algorithm implementation
- ✅ LLM integration for natural language
- ✅ Advanced similarity engine
- ✅ Real-time recommendations

### Phase 3: Scale & Polish (3-4 weeks)
- ✅ Performance optimization
- ✅ Advanced analytics
- ✅ PDF generation for comparisons
- ✅ Mobile-responsive frontend

### Phase 4: Production Ready (2-3 weeks)
- ✅ Security hardening
- ✅ Monitoring & logging
- ✅ Backup strategies
- ✅ Documentation & training

---

## 🔒 Security & Privacy

### Data Protection
- User data encryption at rest and in transit
- GDPR-compliant data handling
- Secure API authentication (JWT)
- Rate limiting and DDoS protection

### Access Control
- Role-based permissions (client/agent/admin)
- API key management for external services
- Audit logging for all data changes

---

## 📊 Success Metrics

### Business Metrics
- Increase in successful property matches
- Reduction in time-to-sale/rent
- Agent productivity improvements
- User engagement rates

### Technical Metrics
- System uptime (99.9%+)
- API response times
- Database performance
- Recommendation accuracy

---

## 🎯 Future Enhancements

### Phase 5: Advanced Features
- Mobile app (React Native)
- Real-time chat between agents and clients
- Virtual property tours integration
- Predictive pricing models
- Market trend analysis

### Phase 6: AI Evolution
- Deep learning models for better recommendations
- Computer vision for property image analysis
- Sentiment analysis from user feedback
- Automated property valuation

---

This roadmap provides a comprehensive foundation for the Smart Contact real estate recommendation system. The architecture is designed to be scalable, maintainable, and aligned with modern best practices while addressing the specific needs of the Algerian real estate market.