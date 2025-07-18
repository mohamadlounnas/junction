# Smart Contact: AI-Powered Real Estate Recommendation System

## Project Overview

Smart Contact is an intelligent backend service that revolutionizes real estate matching by using vector-based scoring and machine learning to automatically recommend relevant contacts (potential buyers/tenants) for each property listing.

### Core Innovation: Vector-Based Scoring System

The system uses a unified scoring approach where both users and properties are represented as feature vectors, enabling sophisticated similarity matching and continuous learning from user interactions.

## System Architecture

### 1. Vector-Based Scoring Algorithm

#### Feature Vector Structure
Each entity (user/property) is represented by a normalized feature vector:

```
Vector Format: [price, area, rooms, location, property_type, furnishing, condition, transaction_type]
Range:         [0.0 → 1.0]
Dimensions:    8 features
```

#### Feature Normalization Examples:
- **Price**: `(price - min_price) / (max_price - min_price)`
- **Area**: `(area - min_area) / (max_area - min_area)`
- **Rooms**: `rooms / max_rooms`
- **Location**: One-hot encoded or geographic embedding
- **Property Type**: Categorical encoding (apartment=0.2, villa=0.8, office=0.5)
- **Furnishing**: Binary (furnished=1.0, unfurnished=0.0)
- **Condition**: Quality scale (poor=0.0, excellent=1.0)
- **Transaction Type**: Binary (rent=0.0, sale=1.0)

#### Learning Algorithm
```python
def learn_from_interaction(user_vector, property_vector, interaction_strength=0.1):
    """
    Updates user preferences based on interaction with property
    """
    learning_rate = interaction_strength * 0.05
    return user_vector + learning_rate * (property_vector - user_vector)
```

### 2. Database Design

#### Core Tables

**Users Table**
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    user_type ENUM('buyer', 'tenant', 'agent') NOT NULL,
    score_vector FLOAT[8] NOT NULL, -- 8-dimensional feature vector
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

**Properties Table**
```sql
CREATE TABLE properties (
    id UUID PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(12,2) NOT NULL,
    area DECIMAL(8,2) NOT NULL,
    rooms INTEGER NOT NULL,
    location VARCHAR(255) NOT NULL,
    property_type ENUM('apartment', 'villa', 'office', 'land') NOT NULL,
    furnishing ENUM('furnished', 'unfurnished', 'semi_furnished') NOT NULL,
    condition ENUM('poor', 'fair', 'good', 'excellent') NOT NULL,
    transaction_type ENUM('rent', 'sale') NOT NULL,
    score_vector FLOAT[8] NOT NULL, -- 8-dimensional feature vector
    agent_id UUID REFERENCES users(id),
    status ENUM('active', 'inactive', 'sold') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

**User Interactions Table**
```sql
CREATE TABLE user_interactions (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    property_id UUID REFERENCES properties(id),
    interaction_type ENUM('view', 'like', 'share', 'contact', 'favorite') NOT NULL,
    interaction_strength FLOAT DEFAULT 1.0, -- Weight of interaction
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Search Queries Table**
```sql
CREATE TABLE search_queries (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    query_type ENUM('static', 'natural_language') NOT NULL,
    raw_query TEXT, -- Natural language query
    parsed_filters JSON, -- Structured filters
    generated_score_vector FLOAT[8], -- Generated from filters/LLM
    results_count INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 3. API Design

#### Core Endpoints

**Authentication**
```
POST /api/auth/login
POST /api/auth/register
POST /api/auth/refresh
```

**User Management**
```
GET    /api/users
GET    /api/users/:id
PUT    /api/users/:id
DELETE /api/users/:id
POST   /api/users/:id/update-scores
```

**Property Management**
```
GET    /api/properties
GET    /api/properties/:id
POST   /api/properties
PUT    /api/properties/:id
DELETE /api/properties/:id
POST   /api/properties/:id/update-scores
```

**Recommendation Engine**
```
GET    /api/recommendations/property/:id/contacts
GET    /api/recommendations/user/:id/properties
GET    /api/recommendations/feed/:user_id
POST   /api/recommendations/bulk
```

**Search & Discovery**
```
POST   /api/search/static
POST   /api/search/natural-language
GET    /api/search/history/:user_id
```

**Interaction Tracking**
```
POST   /api/interactions
GET    /api/interactions/:user_id
```

**Analytics & Reports**
```
GET    /api/analytics/property/:id/matches
GET    /api/analytics/user/:id/preferences
GET    /api/analytics/agent/:id/dashboard
```

#### Detailed API Specifications

**1. Property Recommendations for Contacts**
```
GET /api/recommendations/property/:id/contacts
Query Parameters:
- limit: number (default: 10)
- min_score: float (default: 0.3)
- include_explanation: boolean (default: true)

Response:
{
  "property_id": "uuid",
  "recommendations": [
    {
      "contact_id": "uuid",
      "contact_name": "string",
      "match_score": 0.85,
      "explanation": {
        "price_match": 0.9,
        "location_match": 0.8,
        "area_match": 0.7,
        "overall_reason": "High budget alignment and location preference match"
      }
    }
  ],
  "total_count": 150,
  "generated_at": "timestamp"
}
```

**2. Static Search**
```
POST /api/search/static
Body:
{
  "user_id": "uuid",
  "filters": {
    "price_min": 50000,
    "price_max": 200000,
    "area_min": 80,
    "area_max": 150,
    "rooms_min": 2,
    "rooms_max": 4,
    "locations": ["Bab Ezzouar", "Alger Centre"],
    "property_types": ["apartment", "villa"],
    "transaction_type": "sale",
    "furnishing": "furnished"
  },
  "limit": 20
}

Response:
{
  "query_id": "uuid",
  "generated_score_vector": [0.6, 0.7, 0.5, 0.8, 0.3, 1.0, 0.0, 1.0],
  "results": [
    {
      "property_id": "uuid",
      "property_title": "string",
      "match_score": 0.92,
      "price": 150000,
      "area": 120,
      "location": "Bab Ezzouar"
    }
  ],
  "total_count": 45
}
```

**3. Natural Language Search**
```
POST /api/search/natural-language
Body:
{
  "user_id": "uuid",
  "query": "أبحث عن شقة صغيرة بسعر منخفض في باب الزوار مع 2 غرف نوم",
  "limit": 20
}

Response:
{
  "query_id": "uuid",
  "parsed_filters": {
    "price_max": 80000,
    "area_max": 80,
    "rooms": 2,
    "locations": ["Bab Ezzouar"],
    "property_types": ["apartment"]
  },
  "generated_score_vector": [0.2, 0.3, 0.4, 0.9, 0.2, 0.0, 0.0, 0.0],
  "results": [...],
  "llm_confidence": 0.85
}
```

**4. Interaction Tracking**
```
POST /api/interactions
Body:
{
  "user_id": "uuid",
  "property_id": "uuid",
  "interaction_type": "view", // view, like, share, contact, favorite
  "interaction_strength": 1.0, // Optional, defaults to 1.0
  "session_id": "uuid" // Optional for analytics
}

Response:
{
  "interaction_id": "uuid",
  "user_score_updated": true,
  "new_user_score_vector": [0.25, 0.48, 0.42, 0.02, 0.15, 0.8, 0.3, 0.1],
  "learning_rate_applied": 0.05
}
```

### 4. Learning Algorithm Implementation

#### Score Generation from Filters
```python
class ScoreGenerator:
    def __init__(self, price_range, area_range, location_embeddings):
        self.price_range = price_range
        self.area_range = area_range
        self.location_embeddings = location_embeddings
    
    def filters_to_vector(self, filters):
        """Convert search filters to score vector"""
        vector = [0.0] * 8
        
        # Price normalization
        if 'price_min' in filters and 'price_max' in filters:
            avg_price = (filters['price_min'] + filters['price_max']) / 2
            vector[0] = (avg_price - self.price_range[0]) / (self.price_range[1] - self.price_range[0])
        
        # Area normalization
        if 'area_min' in filters and 'area_max' in filters:
            avg_area = (filters['area_min'] + filters['area_max']) / 2
            vector[1] = (avg_area - self.area_range[0]) / (self.area_range[1] - self.area_range[0])
        
        # Rooms normalization
        if 'rooms_min' in filters and 'rooms_max' in filters:
            avg_rooms = (filters['rooms_min'] + filters['rooms_max']) / 2
            vector[2] = min(avg_rooms / 5, 1.0)  # Assuming max 5 rooms
        
        # Location embedding
        if 'locations' in filters:
            vector[3] = self.get_location_score(filters['locations'])
        
        # Property type encoding
        if 'property_types' in filters:
            vector[4] = self.encode_property_types(filters['property_types'])
        
        # Furnishing encoding
        if 'furnishing' in filters:
            vector[5] = self.encode_furnishing(filters['furnishing'])
        
        # Condition (default to good)
        vector[6] = 0.7
        
        # Transaction type
        if 'transaction_type' in filters:
            vector[7] = 1.0 if filters['transaction_type'] == 'sale' else 0.0
        
        return vector
```

#### Learning from Interactions
```python
class LearningEngine:
    def __init__(self, learning_rate=0.05):
        self.learning_rate = learning_rate
        self.interaction_weights = {
            'view': 0.1,
            'like': 0.3,
            'share': 0.5,
            'contact': 0.8,
            'favorite': 0.6
        }
    
    def learn_from_interaction(self, user_vector, property_vector, interaction_type, strength=1.0):
        """Update user preferences based on interaction"""
        base_weight = self.interaction_weights.get(interaction_type, 0.1)
        effective_rate = self.learning_rate * base_weight * strength
        
        # Move user vector closer to property vector
        new_vector = []
        for i in range(len(user_vector)):
            diff = property_vector[i] - user_vector[i]
            new_value = user_vector[i] + effective_rate * diff
            new_vector.append(max(0.0, min(1.0, new_value)))  # Clamp to [0,1]
        
        return new_vector
```

#### Similarity Search
```python
class SimilarityEngine:
    def cosine_similarity(self, vector_a, vector_b):
        """Calculate cosine similarity between two vectors"""
        dot_product = sum(a * b for a, b in zip(vector_a, vector_b))
        norm_a = sum(a * a for a in vector_a) ** 0.5
        norm_b = sum(b * b for b in vector_b) ** 0.5
        
        if norm_a == 0 or norm_b == 0:
            return 0.0
        
        return dot_product / (norm_a * norm_b)
    
    def find_similar_properties(self, target_vector, properties, limit=10, min_score=0.3):
        """Find properties similar to target vector"""
        similarities = []
        
        for property in properties:
            score = self.cosine_similarity(target_vector, property.score_vector)
            if score >= min_score:
                similarities.append((property, score))
        
        # Sort by similarity score (descending)
        similarities.sort(key=lambda x: x[1], reverse=True)
        
        return similarities[:limit]
```

### 5. Natural Language Processing Integration

#### LLM Integration for Query Parsing
```python
class LLMQueryParser:
    def __init__(self, api_key):
        self.api_key = api_key
        self.score_generator = ScoreGenerator()
    
    async def parse_natural_query(self, query_text):
        """Parse natural language query using LLM"""
        prompt = f"""
        Parse the following real estate search query and extract structured filters:
        Query: "{query_text}"
        
        Return JSON with the following structure:
        {{
            "price_min": number or null,
            "price_max": number or null,
            "area_min": number or null,
            "area_max": number or null,
            "rooms_min": number or null,
            "rooms_max": number or null,
            "locations": [string],
            "property_types": [string],
            "transaction_type": "rent" or "sale" or null,
            "furnishing": "furnished" or "unfurnished" or null,
            "condition": "poor" or "fair" or "good" or "excellent" or null,
            "confidence": float
        }}
        """
        
        # Call LLM API (Gemini, GPT, etc.)
        response = await self.call_llm_api(prompt)
        parsed_filters = json.loads(response)
        
        # Generate score vector from parsed filters
        score_vector = self.score_generator.filters_to_vector(parsed_filters)
        
        return {
            "parsed_filters": parsed_filters,
            "score_vector": score_vector,
            "confidence": parsed_filters.get("confidence", 0.8)
        }
```

### 6. Performance Optimization

#### Database Indexing
```sql
-- Vector similarity search optimization
CREATE INDEX idx_properties_score_vector ON properties USING gin(score_vector);
CREATE INDEX idx_users_score_vector ON users USING gin(score_vector);

-- Interaction tracking optimization
CREATE INDEX idx_interactions_user_property ON user_interactions(user_id, property_id);
CREATE INDEX idx_interactions_created_at ON user_interactions(created_at);

-- Search optimization
CREATE INDEX idx_properties_price ON properties(price);
CREATE INDEX idx_properties_location ON properties(location);
CREATE INDEX idx_properties_type ON properties(property_type);
```

#### Caching Strategy
```python
class RecommendationCache:
    def __init__(self, redis_client):
        self.redis = redis_client
        self.cache_ttl = 3600  # 1 hour
    
    def get_cached_recommendations(self, cache_key):
        """Get cached recommendations"""
        cached = self.redis.get(f"rec:{cache_key}")
        return json.loads(cached) if cached else None
    
    def cache_recommendations(self, cache_key, recommendations):
        """Cache recommendations"""
        self.redis.setex(
            f"rec:{cache_key}",
            self.cache_ttl,
            json.dumps(recommendations)
        )
```

### 7. Analytics & Reporting

#### Dashboard Metrics
```python
class AnalyticsEngine:
    def get_property_match_analytics(self, property_id):
        """Get analytics for property matches"""
        return {
            "total_matches": self.count_matches(property_id),
            "avg_match_score": self.avg_match_score(property_id),
            "top_matching_criteria": self.top_criteria(property_id),
            "interaction_rate": self.interaction_rate(property_id),
            "conversion_rate": self.conversion_rate(property_id)
        }
    
    def get_user_preference_analytics(self, user_id):
        """Get user preference analytics"""
        return {
            "preference_evolution": self.get_preference_history(user_id),
            "most_viewed_properties": self.most_viewed(user_id),
            "interaction_patterns": self.interaction_patterns(user_id),
            "search_history": self.search_history(user_id)
        }
```

### 8. Security & Authentication

#### JWT Authentication
```python
class AuthService:
    def generate_token(self, user_id, user_type):
        """Generate JWT token"""
        payload = {
            "user_id": str(user_id),
            "user_type": user_type,
            "exp": datetime.utcnow() + timedelta(hours=24)
        }
        return jwt.encode(payload, self.secret_key, algorithm="HS256")
    
    def verify_token(self, token):
        """Verify JWT token"""
        try:
            payload = jwt.decode(token, self.secret_key, algorithms=["HS256"])
            return payload
        except jwt.ExpiredSignatureError:
            raise HTTPException(status_code=401, detail="Token expired")
        except jwt.InvalidTokenError:
            raise HTTPException(status_code=401, detail="Invalid token")
```

### 9. Testing Strategy

#### Unit Tests
```python
class TestScoreGenerator:
    def test_filters_to_vector(self):
        filters = {
            "price_min": 50000,
            "price_max": 100000,
            "area_min": 80,
            "area_max": 120,
            "rooms_min": 2,
            "rooms_max": 3
        }
        vector = self.score_generator.filters_to_vector(filters)
        assert len(vector) == 8
        assert all(0.0 <= v <= 1.0 for v in vector)

class TestLearningEngine:
    def test_learn_from_interaction(self):
        user_vector = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
        property_vector = [0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8]
        
        new_vector = self.learning_engine.learn_from_interaction(
            user_vector, property_vector, "like"
        )
        
        # User vector should move closer to property vector
        for i in range(len(user_vector)):
            assert new_vector[i] > user_vector[i]
```

### 10. Deployment & Infrastructure

#### Docker Configuration
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

#### Environment Configuration
```env
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/smart_contact
REDIS_URL=redis://localhost:6379

# LLM API
GEMINI_API_KEY=your_gemini_api_key
OPENAI_API_KEY=your_openai_api_key

# JWT
JWT_SECRET_KEY=your_jwt_secret_key

# Feature ranges for normalization
MIN_PRICE=2000
MAX_PRICE=41000
MIN_AREA=20
MAX_AREA=500
```

## Implementation Roadmap

### Phase 1: Core Infrastructure (Week 1-2)
- [ ] Database schema design and implementation
- [ ] Basic API structure with FastAPI
- [ ] Authentication system
- [ ] Core data models (User, Property, Interaction)

### Phase 2: Scoring System (Week 3-4)
- [ ] Score vector generation from property data
- [ ] Filter-to-vector conversion
- [ ] Similarity calculation algorithms
- [ ] Basic recommendation endpoints

### Phase 3: Learning Engine (Week 5-6)
- [ ] Interaction tracking system
- [ ] Learning algorithm implementation
- [ ] User preference evolution
- [ ] Score update mechanisms

### Phase 4: Search & Discovery (Week 7-8)
- [ ] Static search implementation
- [ ] LLM integration for natural language queries
- [ ] Search result ranking
- [ ] Search history tracking

### Phase 5: Analytics & Dashboard (Week 9-10)
- [ ] Analytics engine
- [ ] Dashboard API endpoints
- [ ] Reporting features
- [ ] Performance metrics

### Phase 6: Optimization & Testing (Week 11-12)
- [ ] Performance optimization
- [ ] Caching implementation
- [ ] Comprehensive testing
- [ ] Documentation completion

### Phase 7: Deployment & Monitoring (Week 13-14)
- [ ] Production deployment
- [ ] Monitoring setup
- [ ] Performance tuning
- [ ] Security audit

## Success Metrics

### Technical Metrics
- **Response Time**: < 200ms for recommendations
- **Throughput**: Handle 1000+ concurrent users
- **Accuracy**: > 85% relevant recommendations
- **Scalability**: Support 10,000+ contacts

### Business Metrics
- **User Engagement**: 40% increase in property views
- **Conversion Rate**: 25% improvement in contact-to-property matches
- **Agent Efficiency**: 60% reduction in manual matching time
- **Customer Satisfaction**: > 4.5/5 rating

## Risk Mitigation

### Technical Risks
- **Vector Search Performance**: Implement approximate nearest neighbor search
- **LLM API Reliability**: Fallback to rule-based parsing
- **Data Quality**: Implement data validation and cleaning

### Business Risks
- **User Adoption**: Gradual rollout with feedback collection
- **Data Privacy**: GDPR compliance and data encryption
- **Scalability**: Horizontal scaling architecture

## Conclusion

This Smart Contact recommendation system leverages modern AI techniques to create a sophisticated, learning-based matching system. The vector-based approach ensures scalability and accuracy while the continuous learning mechanism improves recommendations over time.

The system is designed to be:
- **Scalable**: Handle thousands of users and properties
- **Intelligent**: Learn from user interactions
- **Flexible**: Support both structured and natural language queries
- **Transparent**: Provide clear explanations for recommendations
- **Secure**: Robust authentication and data protection

The implementation roadmap provides a clear path to deliver a production-ready system within 14 weeks, with each phase building upon the previous one to create a comprehensive solution. 