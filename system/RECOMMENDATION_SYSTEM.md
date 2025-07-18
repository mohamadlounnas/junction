# Smart Contact: AI-Powered Recommendation System Architecture

## 🎯 **Challenge Overview**

**Mission**: Design an intelligent backend service that automatically recommends relevant contacts (potential buyers/tenants) for each new real estate listing in Algeria.

**Scale**: Handle 10,000+ contacts with optimal performance and provide transparent, explainable recommendations.

---

## 📊 **Database Schema Design**

### **Core Philosophy**
Our schema is built around three core principles:
1. **Performance at Scale**: Optimized for 10,000+ contacts
2. **Algeria-Specific**: Tailored for Algerian real estate market
3. **AI-Ready**: Designed for machine learning and recommendations

### **Key Entities**

#### **1. Contacts (From ERP System)**
```sql
-- Core matching criteria as specified by judge:
- Budget ranges (budgetMin, budgetMax)
- Geographic preferences (preferredWilayas, preferredCities)  
- Property type preferences (propertyTypes[])
- Desired surface area (minArea, maxArea)
- Number of rooms (minRooms, maxRooms)
- Family context (hasChildren, familySize, age)

-- AI Enhancement:
- 16-dimensional preference vector for ML
- Profile completeness score
- ERP synchronization tracking
```

#### **2. Properties (Available Listings)**
```sql
-- Core property data:
- Location (wilaya, city, commune) - Algeria-specific
- Price in DZD
- Area and rooms
- Property type and transaction type

-- Enhanced features:
- 16-dimensional feature vector for ML
- Market attractiveness score
- Comprehensive feature flags
```

#### **3. Recommendations (AI-Generated)**
```sql
-- Scoring system:
- Overall match score (0.0 - 1.0)
- Detailed breakdown (budget, location, type, size, features)
- Transparent explanation (JSON format)

-- Performance tracking:
- View/contact/conversion tracking
- Batch processing support
- Algorithm attribution
```

---

## 🧠 **Recommendation Algorithm Architecture**

### **Multi-Algorithm Approach**

Our system uses a **hybrid recommendation approach** combining multiple algorithms for optimal results:

#### **1. Content-Based Filtering (Primary)**
```typescript
// 16-Dimensional Vector Matching
const contactVector = [
  // Financial (indices 0-2)
  budgetScore,           // 0: Normalized budget preference
  priceFlexibility,      // 1: How flexible on price
  financialStability,    // 2: Based on budget range width
  
  // Location (indices 3-5)
  wilayaPreference,      // 3: Primary wilaya preference
  cityPreference,        // 4: City-level preference
  proximityTolerance,    // 5: How far willing to travel
  
  // Property (indices 6-9)
  propertyTypeScore,     // 6: Type preference strength
  sizeRequirement,       // 7: Area preference
  roomsRequirement,      // 8: Rooms preference
  conditionPreference,   // 9: Property condition importance
  
  // Lifestyle (indices 10-13)
  familyNeeds,          // 10: Family-oriented features
  modernityPreference,   // 11: Modern vs traditional
  amenitiesImportance,   // 12: Parking, elevator, etc.
  investmentIntent,      // 13: Investment vs personal use
  
  // Context (indices 14-15)
  urgency,              // 14: How quickly they need property
  decisionMaking        // 15: Individual vs family decision
];
```

#### **2. Collaborative Filtering (Secondary)**
```typescript
// "Contacts like you also liked..."
- Analyze interaction patterns of similar contacts
- Find contacts with similar vectors and preferences
- Recommend properties that similar contacts engaged with
- Weight by conversion success rate
```

#### **3. Business Rules Engine (Filters)**
```typescript
// Hard constraints that must be met:
- Budget compatibility (property price within contact's range)
- Geographic match (property location in preferred areas)
- Property type match (apartment/villa/office/land)
- Size requirements (area and rooms within acceptable range)
- Transaction type (rent/sale compatibility)
```

### **Scoring Calculation**

#### **Overall Match Score Formula**
```typescript
const matchScore = (
  budgetScore * 0.25 +        // 25% - Budget compatibility
  locationScore * 0.20 +      // 20% - Geographic match
  propertyTypeScore * 0.15 +  // 15% - Property type match
  sizeScore * 0.15 +          // 15% - Size requirements
  featuresScore * 0.10 +      // 10% - Additional features
  collaborativeScore * 0.10 + // 10% - Collaborative filtering
  marketScore * 0.05          // 5% - Market attractiveness
);
```

#### **Detailed Scoring Components**

1. **Budget Score**
   ```typescript
   if (propertyPrice >= contactBudgetMin && propertyPrice <= contactBudgetMax) {
     budgetScore = 1.0 - Math.abs(propertyPrice - optimalPrice) / budgetRange;
   }
   ```

2. **Location Score**
   ```typescript
   // Perfect match for preferred wilaya
   if (propertyWilaya in preferredWilayas) locationScore = 1.0;
   // Partial match for neighboring wilayas
   else if (isNeighboringWilaya(propertyWilaya)) locationScore = 0.7;
   ```

3. **Property Type Score**
   ```typescript
   if (propertyType in contactPreferredTypes) propertyTypeScore = 1.0;
   else propertyTypeScore = getTypeCompatibility(propertyType, preferredTypes);
   ```

---

## 🔄 **Learning System Architecture**

### **Continuous Learning Pipeline**

#### **1. Interaction Tracking**
Every contact interaction is captured:
```typescript
interface Interaction {
  type: 'VIEW' | 'FAVORITE' | 'CONTACT' | 'VISIT_REQUEST' | 'PHONE_CALL';
  duration: number;           // How long they viewed
  outcome: 'INTERESTED' | 'NOT_INTERESTED' | 'CONVERTED';
  feedback: string;           // Optional text feedback
  rating: 1-5;               // Star rating
}
```

#### **2. Preference Learning Algorithm**
```typescript
// Update contact preference vector based on interactions
function updatePreferences(contact: Contact, interaction: Interaction) {
  const property = interaction.property;
  const weight = getInteractionWeight(interaction.type, interaction.outcome);
  
  // Positive reinforcement for interested/converted interactions
  if (interaction.outcome === 'INTERESTED' || interaction.outcome === 'CONVERTED') {
    contact.preferenceVector = adjustTowards(
      contact.preferenceVector, 
      property.featureVector, 
      weight
    );
  }
  
  // Negative feedback for not interested
  if (interaction.outcome === 'NOT_INTERESTED') {
    contact.preferenceVector = adjustAway(
      contact.preferenceVector, 
      property.featureVector, 
      weight * 0.5
    );
  }
}
```

#### **3. Market Learning**
```typescript
// Property market score adjustments based on performance
function updateMarketScore(property: Property) {
  const metrics = getPropertyMetrics(property.id);
  
  property.marketScore = calculateScore([
    metrics.viewCount * 0.2,        // Interest level
    metrics.contactRate * 0.3,      // Contact conversion
    metrics.conversionRate * 0.4,   // Final conversion
    metrics.timeOnMarket * 0.1      // How quickly it moves
  ]);
}
```

### **Algorithm Performance Tracking**

#### **A/B Testing Framework**
```typescript
// Test different algorithm weights and approaches
const algorithmVariants = {
  'vector_heavy': { vectorWeight: 0.7, collaborativeWeight: 0.3 },
  'collaborative_heavy': { vectorWeight: 0.4, collaborativeWeight: 0.6 },
  'balanced': { vectorWeight: 0.5, collaborativeWeight: 0.5 }
};

// Track performance per variant
interface AlgorithmMetrics {
  clickThroughRate: number;   // Views per recommendation
  contactRate: number;        // Contacts per view
  conversionRate: number;     // Conversions per contact
  userSatisfaction: number;   // Average rating
}
```

---

## 🚀 **API Implementation Strategy**

### **Core Endpoints**

#### **1. Property Recommendations**
```typescript
GET /api/recommendations/property/:id
// Returns ranked list of contacts for a property

Response: {
  property: PropertyDetails,
  recommendations: [
    {
      contact: ContactSummary,
      matchScore: 0.94,
      rank: 1,
      explanation: {
        budgetMatch: "Perfect fit - property at 85% of max budget",
        locationMatch: "Preferred wilaya: Algiers",
        typeMatch: "Exact match: VILLA",
        sizeMatch: "Within preferred range: 250m² (200-300m²)",
        features: ["Has parking (required)", "Has garden (preferred)"]
      },
      confidence: "HIGH"
    }
  ],
  meta: {
    totalContacts: 156,
    algorithm: "hybrid_v2",
    generatedAt: "2025-01-18T10:30:00Z"
  }
}
```

#### **2. Bulk Recommendations**
```typescript
GET /api/recommendations/bulk
// Generate recommendations for all active properties

Response: {
  batchId: "batch_2025_01_18_001",
  processed: 150,
  recommendations: 1250,
  status: "COMPLETED",
  results: [
    {
      propertyId: "prop_123",
      contactCount: 8,
      topMatchScore: 0.96
    }
  ]
}
```

#### **3. Property Comparison**
```typescript
POST /api/compare/properties
Body: { property1Id: "prop_123", property2Id: "prop_456" }

Response: {
  comparison: {
    price: { property1: 25000000, property2: 30000000, advantage: "property1" },
    location: { property1: "Algiers", property2: "Oran", neutral: true },
    size: { property1: "250m²", property2: "200m²", advantage: "property1" },
    features: {
      parking: { property1: true, property2: false, advantage: "property1" },
      garden: { property1: true, property2: true, neutral: true }
    }
  },
  recommendation: "Property 1 offers better value with larger size and parking"
}
```

#### **4. Quote Generation**
```typescript
POST /api/quotes/generate/:propertyId
Body: { contactId: "contact_123", includeDetails: true }

Response: {
  quoteId: "quote_789",
  quoteNumber: "QUO-2025-001",
  property: PropertyDetails,
  contact: ContactDetails,
  pricing: {
    basePrice: 25000000,
    agentCommission: 1250000,
    legalFees: 500000,
    totalAmount: 26750000
  },
  pdfUrl: "/quotes/QUO-2025-001.pdf",
  validUntil: "2025-02-18T00:00:00Z"
}
```

---

## 📈 **Performance Optimization**

### **Database Optimization**
1. **Strategic Indexing**: All query patterns have optimized indexes
2. **Vector Storage**: Efficient float array storage and similarity searches
3. **Partitioning**: Large tables partitioned by date/wilaya
4. **Caching**: Redis for frequent queries and recommendation results

### **Algorithm Optimization**
1. **Batch Processing**: Process multiple recommendations simultaneously
2. **Lazy Loading**: Calculate detailed scores only for top candidates
3. **Precomputed Vectors**: Update vectors during off-peak hours
4. **Smart Filtering**: Apply business rules before expensive ML calculations

### **API Performance**
1. **Response Caching**: Cache recommendation results for 5-15 minutes
2. **Pagination**: Efficient handling of large result sets
3. **Async Processing**: Background processing for bulk operations
4. **Rate Limiting**: Protect against abuse while maintaining performance

---

## 🔍 **Transparency & Explainability**

### **Explanation System**
Every recommendation includes:

1. **Match Breakdown**: Detailed scoring for each criterion
2. **Key Factors**: Primary reasons for the recommendation
3. **Confidence Level**: Algorithm confidence in the match
4. **Alternative Options**: Why other properties scored lower

### **Audit Trail**
Complete tracking of:
- Algorithm decisions and parameters used
- Data sources and version timestamps
- User interactions and feedback
- Performance metrics and improvements

---

## 🎯 **Success Metrics**

### **Recommendation Quality**
- **Precision**: % of recommendations that lead to contact
- **Recall**: % of successful matches found by system  
- **F1 Score**: Balanced precision/recall metric
- **User Satisfaction**: Average rating from real estate agents

### **System Performance**
- **Response Time**: < 100ms for single property recommendations
- **Throughput**: Handle 1000+ concurrent recommendation requests
- **Accuracy**: > 85% match accuracy for converted contacts
- **Coverage**: Recommendations available for 95%+ of properties

This architecture provides a solid foundation for building the competition-winning Smart Contact system! 🏆 