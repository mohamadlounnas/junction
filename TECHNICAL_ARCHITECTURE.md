# Smart Contact: Technical Architecture

## System Overview

The Smart Contact recommendation system is built as a microservices-ready architecture with a focus on scalability, performance, and maintainability. The system uses vector-based scoring and machine learning to provide intelligent property recommendations.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT APPLICATIONS                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  Web App (React/Vue)  │  Mobile App (Flutter)  │  Agent Dashboard (React)  │
└─────────────────────────┬───────────────────────┬───────────────────────────┘
                          │                       │
                          ▼                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              API GATEWAY / LOAD BALANCER                    │
│                              (Nginx / AWS ALB)                              │
└─────────────────────────┬───────────────────────┬───────────────────────────┘
                          │                       │
                          ▼                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              FASTAPI APPLICATION                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐            │
│  │   Auth Module   │  │  User Module    │  │ Property Module │            │
│  │                 │  │                 │  │                 │            │
│  │ • JWT Auth      │  │ • CRUD Users    │  │ • CRUD Props    │            │
│  │ • Role Control  │  │ • Score Vectors │  │ • Score Vectors │            │
│  │ • Security      │  │ • Preferences   │  │ • Features      │            │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘            │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐            │
│  │Recommendation   │  │  Search Module  │  │ Analytics Module│            │
│  │   Engine        │  │                 │  │                 │            │
│  │                 │  │ • Static Search │  │ • Metrics       │            │
│  │ • Similarity    │  │ • NLP Search    │  │ • Reports       │            │
│  │ • Learning      │  │ • LLM Integration│  │ • Dashboard     │            │
│  │ • Ranking       │  │ • Filters       │  │ • Insights      │            │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘            │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐            │
│  │ Interaction     │  │   Cache Layer   │  │ Background      │            │
│  │   Tracker       │  │                 │  │   Tasks         │            │
│  │                 │  │ • Redis         │  │                 │            │
│  │ • User Actions  │  │ • Recommendations│  │ • Score Updates │            │
│  │ • Learning      │  │ • Search Results│  │ • Analytics     │            │
│  │ • Analytics     │  │ • Session Data  │  │ • Reports       │            │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘            │
│                                                                             │
└─────────────────────────┬───────────────────────┬───────────────────────────┘
                          │                       │
                          ▼                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              DATA LAYER                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐            │
│  │   PostgreSQL    │  │     Redis       │  │   File Storage  │            │
│  │   Database      │  │     Cache       │  │                 │            │
│  │                 │  │                 │  │ • Property      │            │
│  │ • Users         │  │ • Session Data  │  │   Images        │            │
│  │ • Properties    │  │ • Cache         │  │ • Documents     │            │
│  │ • Interactions  │  │ • Rate Limiting │  │ • Reports       │            │
│  │ • Analytics     │  │ • Pub/Sub       │  │ • Exports       │            │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                          │                       │
                          ▼                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              EXTERNAL SERVICES                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐            │
│  │   Google Gemini │  │   OpenAI GPT    │  │   Email Service │            │
│  │     API         │  │     API         │  │                 │            │
│  │                 │  │                 │  │ • Notifications │            │
│  │ • NLP Parsing   │  │ • Query Parsing │  │ • Reports       │            │
│  │ • Arabic Support│  │ • Fallback      │  │ • Alerts        │            │
│  │ • Intent Recognition│ • Multi-language│  │ • Marketing     │            │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Architecture

### 1. Core Modules

#### Authentication Module
```python
class AuthModule:
    """
    Handles user authentication, authorization, and security
    """
    def __init__(self):
        self.jwt_secret = os.getenv("JWT_SECRET_KEY")
        self.algorithm = "HS256"
        self.access_token_expire = timedelta(hours=24)
    
    async def authenticate_user(self, email: str, password: str) -> Optional[User]:
        """Authenticate user with email and password"""
        pass
    
    def create_access_token(self, data: dict) -> str:
        """Create JWT access token"""
        pass
    
    def verify_token(self, token: str) -> dict:
        """Verify JWT token and return payload"""
        pass
```

#### User Module
```python
class UserModule:
    """
    Manages user data, preferences, and score vectors
    """
    def __init__(self, db: Database, score_generator: ScoreGenerator):
        self.db = db
        self.score_generator = score_generator
    
    async def create_user(self, user_data: UserCreate) -> User:
        """Create new user with initial random score vector"""
        pass
    
    async def update_user_scores(self, user_id: UUID, new_scores: List[float]) -> User:
        """Update user's preference score vector"""
        pass
    
    async def get_user_preferences(self, user_id: UUID) -> Dict:
        """Get user's current preferences and history"""
        pass
```

#### Property Module
```python
class PropertyModule:
    """
    Manages property data and score vector generation
    """
    def __init__(self, db: Database, score_generator: ScoreGenerator):
        self.db = db
        self.score_generator = score_generator
    
    async def create_property(self, property_data: PropertyCreate) -> Property:
        """Create new property with calculated score vector"""
        pass
    
    async def update_property_scores(self, property_id: UUID) -> Property:
        """Recalculate property score vector based on updated data"""
        pass
    
    async def get_property_features(self, property_id: UUID) -> Dict:
        """Get property features and score breakdown"""
        pass
```

### 2. Recommendation Engine

#### Core Recommendation Logic
```python
class RecommendationEngine:
    """
    Core recommendation system using vector similarity
    """
    def __init__(self, db: Database, similarity_engine: SimilarityEngine):
        self.db = db
        self.similarity_engine = similarity_engine
    
    async def get_property_recommendations(
        self, 
        property_id: UUID, 
        limit: int = 10, 
        min_score: float = 0.3
    ) -> List[Recommendation]:
        """
        Get recommended contacts for a specific property
        """
        # Get property score vector
        property = await self.db.get_property(property_id)
        property_vector = property.score_vector
        
        # Get all active users
        users = await self.db.get_active_users()
        
        # Calculate similarities
        recommendations = []
        for user in users:
            similarity = self.similarity_engine.cosine_similarity(
                property_vector, user.score_vector
            )
            
            if similarity >= min_score:
                explanation = self._generate_explanation(
                    property_vector, user.score_vector, similarity
                )
                
                recommendations.append(Recommendation(
                    contact_id=user.id,
                    contact_name=user.name,
                    match_score=similarity,
                    explanation=explanation
                ))
        
        # Sort by similarity score and return top results
        recommendations.sort(key=lambda x: x.match_score, reverse=True)
        return recommendations[:limit]
    
    def _generate_explanation(
        self, 
        property_vector: List[float], 
        user_vector: List[float], 
        overall_score: float
    ) -> Dict:
        """Generate explanation for recommendation"""
        features = ['price', 'area', 'rooms', 'location', 'property_type', 
                   'furnishing', 'condition', 'transaction_type']
        
        explanation = {}
        for i, feature in enumerate(features):
            feature_score = 1.0 - abs(property_vector[i] - user_vector[i])
            explanation[f"{feature}_match"] = feature_score
        
        # Generate overall reason
        top_matches = sorted(
            [(f, explanation[f"{f}_match"]) for f in features], 
            key=lambda x: x[1], 
            reverse=True
        )[:3]
        
        explanation["overall_reason"] = self._create_reason_text(top_matches)
        
        return explanation
```

#### Learning Engine
```python
class LearningEngine:
    """
    Handles user preference learning from interactions
    """
    def __init__(self, db: Database, learning_rate: float = 0.05):
        self.db = db
        self.learning_rate = learning_rate
        self.interaction_weights = {
            'view': 0.1,
            'like': 0.3,
            'share': 0.5,
            'contact': 0.8,
            'favorite': 0.6
        }
    
    async def learn_from_interaction(
        self, 
        user_id: UUID, 
        property_id: UUID, 
        interaction_type: str, 
        strength: float = 1.0
    ) -> Dict:
        """
        Update user preferences based on interaction
        """
        # Get current vectors
        user = await self.db.get_user(user_id)
        property = await self.db.get_property(property_id)
        
        # Calculate new user vector
        new_user_vector = self._update_user_vector(
            user.score_vector,
            property.score_vector,
            interaction_type,
            strength
        )
        
        # Update user in database
        updated_user = await self.db.update_user_scores(user_id, new_user_vector)
        
        # Log interaction
        await self.db.create_interaction(
            user_id=user_id,
            property_id=property_id,
            interaction_type=interaction_type,
            interaction_strength=strength
        )
        
        return {
            "user_score_updated": True,
            "new_user_score_vector": new_user_vector,
            "learning_rate_applied": self._get_effective_rate(interaction_type, strength)
        }
    
    def _update_user_vector(
        self, 
        user_vector: List[float], 
        property_vector: List[float], 
        interaction_type: str, 
        strength: float
    ) -> List[float]:
        """Update user vector based on interaction"""
        base_weight = self.interaction_weights.get(interaction_type, 0.1)
        effective_rate = self.learning_rate * base_weight * strength
        
        new_vector = []
        for i in range(len(user_vector)):
            diff = property_vector[i] - user_vector[i]
            new_value = user_vector[i] + effective_rate * diff
            new_vector.append(max(0.0, min(1.0, new_value)))  # Clamp to [0,1]
        
        return new_vector
```

### 3. Search System

#### Static Search
```python
class StaticSearchEngine:
    """
    Handles structured search with filters
    """
    def __init__(self, db: Database, score_generator: ScoreGenerator):
        self.db = db
        self.score_generator = score_generator
    
    async def search_properties(
        self, 
        filters: Dict, 
        user_id: Optional[UUID] = None,
        limit: int = 20
    ) -> SearchResult:
        """
        Search properties using structured filters
        """
        # Convert filters to score vector
        search_vector = self.score_generator.filters_to_vector(filters)
        
        # Get user vector if provided
        user_vector = None
        if user_id:
            user = await self.db.get_user(user_id)
            user_vector = user.score_vector
        
        # Get properties matching basic filters
        properties = await self.db.search_properties_by_filters(filters)
        
        # Calculate similarity scores
        results = []
        for property in properties:
            similarity = self.similarity_engine.cosine_similarity(
                search_vector, property.score_vector
            )
            
            # Boost score if user vector is available
            if user_vector:
                user_similarity = self.similarity_engine.cosine_similarity(
                    user_vector, property.score_vector
                )
                similarity = (similarity + user_similarity) / 2
            
            results.append(SearchResultItem(
                property_id=property.id,
                property_title=property.title,
                match_score=similarity,
                price=property.price,
                area=property.area,
                location=property.location
            ))
        
        # Sort by similarity and return
        results.sort(key=lambda x: x.match_score, reverse=True)
        
        return SearchResult(
            query_id=uuid4(),
            generated_score_vector=search_vector,
            results=results[:limit],
            total_count=len(results)
        )
```

#### Natural Language Search
```python
class NaturalLanguageSearchEngine:
    """
    Handles natural language search using LLM
    """
    def __init__(self, llm_parser: LLMQueryParser, static_search: StaticSearchEngine):
        self.llm_parser = llm_parser
        self.static_search = static_search
    
    async def search_with_natural_language(
        self, 
        query: str, 
        user_id: Optional[UUID] = None,
        limit: int = 20
    ) -> SearchResult:
        """
        Parse natural language query and search properties
        """
        try:
            # Parse query using LLM
            parsed_result = await self.llm_parser.parse_natural_query(query)
            
            # Use parsed filters for static search
            search_result = await self.static_search.search_properties(
                filters=parsed_result["parsed_filters"],
                user_id=user_id,
                limit=limit
            )
            
            # Add LLM-specific data
            search_result.llm_confidence = parsed_result["confidence"]
            search_result.parsed_filters = parsed_result["parsed_filters"]
            
            return search_result
            
        except Exception as e:
            # Fallback to basic keyword search
            return await self._fallback_search(query, user_id, limit)
    
    async def _fallback_search(
        self, 
        query: str, 
        user_id: Optional[UUID] = None,
        limit: int = 20
    ) -> SearchResult:
        """Fallback search when LLM parsing fails"""
        # Extract basic keywords and search
        keywords = self._extract_keywords(query)
        filters = self._keywords_to_filters(keywords)
        
        return await self.static_search.search_properties(
            filters=filters,
            user_id=user_id,
            limit=limit
        )
```

### 4. Data Models

#### Core Data Models
```python
from pydantic import BaseModel, Field
from typing import List, Optional, Dict
from uuid import UUID
from datetime import datetime
from enum import Enum

class UserType(str, Enum):
    BUYER = "buyer"
    TENANT = "tenant"
    AGENT = "agent"

class PropertyType(str, Enum):
    APARTMENT = "apartment"
    VILLA = "villa"
    OFFICE = "office"
    LAND = "land"

class TransactionType(str, Enum):
    RENT = "rent"
    SALE = "sale"

class User(BaseModel):
    id: UUID
    email: str
    name: str
    phone: Optional[str] = None
    user_type: UserType
    score_vector: List[float] = Field(..., min_items=8, max_items=8)
    created_at: datetime
    updated_at: datetime

class Property(BaseModel):
    id: UUID
    title: str
    description: Optional[str] = None
    price: float
    area: float
    rooms: int
    location: str
    property_type: PropertyType
    furnishing: str
    condition: str
    transaction_type: TransactionType
    score_vector: List[float] = Field(..., min_items=8, max_items=8)
    agent_id: Optional[UUID] = None
    status: str = "active"
    created_at: datetime
    updated_at: datetime

class Interaction(BaseModel):
    id: UUID
    user_id: UUID
    property_id: UUID
    interaction_type: str
    interaction_strength: float = 1.0
    created_at: datetime

class Recommendation(BaseModel):
    contact_id: UUID
    contact_name: str
    match_score: float
    explanation: Dict

class SearchResultItem(BaseModel):
    property_id: UUID
    property_title: str
    match_score: float
    price: float
    area: float
    location: str

class SearchResult(BaseModel):
    query_id: UUID
    generated_score_vector: List[float]
    results: List[SearchResultItem]
    total_count: int
    parsed_filters: Optional[Dict] = None
    llm_confidence: Optional[float] = None
```

### 5. Database Schema

#### PostgreSQL Tables with Vector Support
```sql
-- Enable vector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('buyer', 'tenant', 'agent')),
    score_vector FLOAT[8] NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Properties table
CREATE TABLE properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(12,2) NOT NULL,
    area DECIMAL(8,2) NOT NULL,
    rooms INTEGER NOT NULL,
    location VARCHAR(255) NOT NULL,
    property_type VARCHAR(20) NOT NULL CHECK (property_type IN ('apartment', 'villa', 'office', 'land')),
    furnishing VARCHAR(20) NOT NULL CHECK (furnishing IN ('furnished', 'unfurnished', 'semi_furnished')),
    condition VARCHAR(20) NOT NULL CHECK (condition IN ('poor', 'fair', 'good', 'excellent')),
    transaction_type VARCHAR(10) NOT NULL CHECK (transaction_type IN ('rent', 'sale')),
    score_vector FLOAT[8] NOT NULL,
    agent_id UUID REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'sold')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User interactions table
CREATE TABLE user_interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    interaction_type VARCHAR(20) NOT NULL CHECK (interaction_type IN ('view', 'like', 'share', 'contact', 'favorite')),
    interaction_strength FLOAT DEFAULT 1.0,
    session_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Search queries table
CREATE TABLE search_queries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    query_type VARCHAR(20) NOT NULL CHECK (query_type IN ('static', 'natural_language')),
    raw_query TEXT,
    parsed_filters JSONB,
    generated_score_vector FLOAT[8],
    results_count INTEGER,
    llm_confidence FLOAT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_user_type ON users(user_type);
CREATE INDEX idx_users_score_vector ON users USING gin(score_vector);

CREATE INDEX idx_properties_location ON properties(location);
CREATE INDEX idx_properties_price ON properties(price);
CREATE INDEX idx_properties_property_type ON properties(property_type);
CREATE INDEX idx_properties_transaction_type ON properties(transaction_type);
CREATE INDEX idx_properties_status ON properties(status);
CREATE INDEX idx_properties_score_vector ON properties USING gin(score_vector);

CREATE INDEX idx_interactions_user_property ON user_interactions(user_id, property_id);
CREATE INDEX idx_interactions_created_at ON user_interactions(created_at);
CREATE INDEX idx_interactions_type ON user_interactions(interaction_type);

CREATE INDEX idx_search_queries_user ON search_queries(user_id);
CREATE INDEX idx_search_queries_created_at ON search_queries(created_at);

-- Triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_properties_updated_at BEFORE UPDATE ON properties
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### 6. Caching Strategy

#### Redis Cache Implementation
```python
class CacheManager:
    """
    Manages Redis caching for recommendations and search results
    """
    def __init__(self, redis_url: str):
        self.redis = redis.from_url(redis_url)
        self.default_ttl = 3600  # 1 hour
    
    async def get_cached_recommendations(self, cache_key: str) -> Optional[List[Dict]]:
        """Get cached recommendations"""
        cached = self.redis.get(f"rec:{cache_key}")
        return json.loads(cached) if cached else None
    
    async def cache_recommendations(self, cache_key: str, recommendations: List[Dict], ttl: int = None):
        """Cache recommendations"""
        ttl = ttl or self.default_ttl
        self.redis.setex(
            f"rec:{cache_key}",
            ttl,
            json.dumps(recommendations)
        )
    
    async def get_cached_search_results(self, cache_key: str) -> Optional[Dict]:
        """Get cached search results"""
        cached = self.redis.get(f"search:{cache_key}")
        return json.loads(cached) if cached else None
    
    async def cache_search_results(self, cache_key: str, results: Dict, ttl: int = None):
        """Cache search results"""
        ttl = ttl or self.default_ttl
        self.redis.setex(
            f"search:{cache_key}",
            ttl,
            json.dumps(results)
        )
    
    async def invalidate_user_cache(self, user_id: UUID):
        """Invalidate all cache entries for a user"""
        pattern = f"*:{user_id}:*"
        keys = self.redis.keys(pattern)
        if keys:
            self.redis.delete(*keys)
```

### 7. Performance Optimization

#### Database Query Optimization
```python
class OptimizedDatabase:
    """
    Optimized database operations with connection pooling and query optimization
    """
    def __init__(self, database_url: str):
        self.engine = create_async_engine(
            database_url,
            pool_size=20,
            max_overflow=30,
            pool_pre_ping=True,
            echo=False
        )
        self.session_factory = sessionmaker(
            bind=self.engine,
            class_=AsyncSession,
            expire_on_commit=False
        )
    
    async def get_property_recommendations_optimized(
        self, 
        property_id: UUID, 
        limit: int = 10,
        min_score: float = 0.3
    ) -> List[Dict]:
        """
        Optimized query for property recommendations using vector similarity
        """
        async with self.session_factory() as session:
            # Use PostgreSQL vector similarity functions
            query = text("""
                SELECT 
                    u.id,
                    u.name,
                    u.email,
                    u.score_vector,
                    (u.score_vector <=> p.score_vector) as similarity
                FROM users u
                CROSS JOIN properties p
                WHERE p.id = :property_id
                AND u.user_type IN ('buyer', 'tenant')
                AND (u.score_vector <=> p.score_vector) <= :max_distance
                ORDER BY similarity ASC
                LIMIT :limit
            """)
            
            result = await session.execute(query, {
                "property_id": property_id,
                "max_distance": 1.0 - min_score,  # Convert similarity to distance
                "limit": limit
            })
            
            return [
                {
                    "contact_id": row.id,
                    "contact_name": row.name,
                    "match_score": 1.0 - row.similarity,  # Convert back to similarity
                    "email": row.email
                }
                for row in result
            ]
```

### 8. Monitoring & Observability

#### Application Monitoring
```python
class MonitoringService:
    """
    Handles application monitoring and metrics collection
    """
    def __init__(self):
        self.metrics = {}
    
    async def track_recommendation_request(self, property_id: UUID, response_time: float):
        """Track recommendation request metrics"""
        key = f"recommendations:{property_id}"
        if key not in self.metrics:
            self.metrics[key] = {
                "count": 0,
                "total_time": 0,
                "avg_time": 0
            }
        
        self.metrics[key]["count"] += 1
        self.metrics[key]["total_time"] += response_time
        self.metrics[key]["avg_time"] = self.metrics[key]["total_time"] / self.metrics[key]["count"]
    
    async def track_search_request(self, query_type: str, response_time: float, result_count: int):
        """Track search request metrics"""
        key = f"search:{query_type}"
        if key not in self.metrics:
            self.metrics[key] = {
                "count": 0,
                "total_time": 0,
                "avg_time": 0,
                "total_results": 0
            }
        
        self.metrics[key]["count"] += 1
        self.metrics[key]["total_time"] += response_time
        self.metrics[key]["avg_time"] = self.metrics[key]["total_time"] / self.metrics[key]["count"]
        self.metrics[key]["total_results"] += result_count
    
    async def get_performance_metrics(self) -> Dict:
        """Get current performance metrics"""
        return {
            "recommendations": {
                k: v for k, v in self.metrics.items() 
                if k.startswith("recommendations:")
            },
            "search": {
                k: v for k, v in self.metrics.items() 
                if k.startswith("search:")
            }
        }
```

This technical architecture provides a comprehensive foundation for the Smart Contact recommendation system, ensuring scalability, performance, and maintainability while implementing the vector-based scoring and learning algorithms as specified in the requirements. 