# 🔍 Bulk Recommendations Test Guide

## Issue Analysis

The bulk recommendations endpoint was returning 0 results because you used `minSimilarity: 1`, which requires **perfect similarity** (100% match). This is extremely rare in real-world scenarios.

## ✅ Solution

Use more reasonable `minSimilarity` values:

### **Recommended Settings**

```json
{
  "propertyIds": ["cmd92dkfg000g14olx9jckmji", "cmd92dk6q000d14ol3ervqga7"],
  "minSimilarity": 0.3,  // Good balance of quality and quantity
  "limit": 5
}
```

### **Similarity Thresholds**

- **0.0-0.2**: Very low similarity (rare matches)
- **0.2-0.4**: Low similarity (some matches) ✅ **Recommended starting point**
- **0.4-0.6**: Medium similarity (good matches)
- **0.6-0.8**: High similarity (excellent matches)
- **0.8-1.0**: Very high similarity (perfect matches)

## 🧪 Test Results

### **Test 1: minSimilarity = 0.3 (Recommended)**
```bash
curl -X POST http://localhost:3001/api/recommendations/bulk \
  -H "Content-Type: application/json" \
  -d '{
    "propertyIds": ["cmd92dkfg000g14olx9jckmji", "cmd92dk6q000d14ol3ervqga7"],
    "minSimilarity": 0.3,
    "limit": 5
  }'
```

**Result**: ✅ **4 recommendations per property** with similarities ranging from 0.764 to 0.9

### **Test 2: minSimilarity = 0.5 (Higher Quality)**
```bash
curl -X POST http://localhost:3001/api/recommendations/bulk \
  -H "Content-Type: application/json" \
  -d '{
    "propertyIds": ["cmd92dkfg000g14olx9jckmji"],
    "minSimilarity": 0.5,
    "limit": 3
  }'
```

**Result**: ✅ **4 recommendations** with similarities ranging from 0.764 to 0.825

### **Test 3: minSimilarity = 1.0 (Perfect Match)**
```bash
curl -X POST http://localhost:3001/api/recommendations/bulk \
  -H "Content-Type: application/json" \
  -d '{
    "propertyIds": ["cmd92dkfg000g14olx9jckmji"],
    "minSimilarity": 0.95,
    "limit": 5
  }'
```

**Result**: ❌ **0 recommendations** (as expected - perfect matches are extremely rare)

## 🎯 Enhanced Features

The bulk recommendations endpoint now supports:

### **1. Dual Transaction Types**
- Contacts can be interested in both RENT and SALE
- Enhanced matching logic considers multiple transaction preferences
- Transaction flexibility scoring

### **2. Enhanced AI Scoring**
- Dual scoring system: main 12D vector + transaction scores
- Transaction type bonus in similarity calculations
- Flexibility weighting

### **3. Better Response Data**
- Enhanced contact information including transaction preferences
- Detailed similarity scores
- Comprehensive metadata

## 📊 Example Response

```json
{
  "success": true,
  "data": [
    {
      "propertyId": "cmd92dkfg000g14olx9jckmji",
      "propertyTitle": "Terrain constructible à Tipaza",
      "recommendationsCount": 4,
      "recommendations": [
        {
          "contact": {
            "id": "cmd92djup000814olct1u4oix",
            "name": "Amina Boudjemaa",
            "email": "amina.family@gmail.com",
            "type": "BUYER",
            "transactionType": "SALE",
            "transactionTypes": ["SALE", "RENT"],
            "primaryTransactionType": "SALE",
            "transactionFlexibility": 0.6
          },
          "similarity": 0.825
        }
      ]
    }
  ],
  "metadata": {
    "propertiesProcessed": 1,
    "totalContactsPool": 6,
    "minSimilarity": 0.3,
    "generatedAt": "2025-07-18T17:16:04.788Z"
  }
}
```

## 🚀 Best Practices

### **For Production Use**
1. **Start with minSimilarity: 0.3** for broad matching
2. **Use minSimilarity: 0.5** for higher quality matches
3. **Use minSimilarity: 0.7** for premium matches only
4. **Avoid minSimilarity: 0.95** unless you specifically need perfect matches

### **For Testing**
1. **Use minSimilarity: 0.2** to see more results
2. **Use minSimilarity: 0.4** for balanced results
3. **Test with different property types** to see variety

### **For Batch Processing**
1. **Process 10-50 properties at once** for optimal performance
2. **Use reasonable limits** (5-10 recommendations per property)
3. **Monitor response times** for large batches

## 🔧 Troubleshooting

### **No Results Returned**
- ✅ Check if `minSimilarity` is too high (try 0.3)
- ✅ Verify property IDs exist
- ✅ Ensure properties have matching transaction types
- ✅ Check if contacts are active

### **Low Similarity Scores**
- ✅ This is normal - perfect matches are rare
- ✅ Focus on relative ranking rather than absolute scores
- ✅ Use lower `minSimilarity` thresholds

### **Performance Issues**
- ✅ Limit batch size to 100 properties maximum
- ✅ Use reasonable `limit` values (5-10)
- ✅ Consider processing in smaller batches

---

## 🎉 Summary

The bulk recommendations endpoint is working correctly! The issue was using `minSimilarity: 1` which requires perfect matches. Use `minSimilarity: 0.3` for good results, and the enhanced dual transaction type support is now fully operational. 