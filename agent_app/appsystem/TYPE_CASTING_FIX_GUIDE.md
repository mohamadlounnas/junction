# 🔧 Type Casting Fix Guide - Flutter JSON Parsing

## 📋 Issue Description

The error `TypeError: Instance of 'LinkedMap<dynamic, dynamic>': type 'LinkedMap<dynamic, dynamic>' is not a subtype of type 'Map<String, dynamic>?'` occurs when parsing JSON data in Flutter. This happens because:

1. **JSON.decode()** returns `Map<dynamic, dynamic>` (LinkedMap)
2. **fromJson methods** expect `Map<String, dynamic>`
3. **Direct casting** fails due to type mismatch

## 🔍 Root Cause

### **JSON Decoding Behavior**
```dart
// This returns LinkedMap<dynamic, dynamic>
final jsonResponse = json.decode(response.body);

// This fails because of type mismatch
Map<String, dynamic>.from(json['contact'] as Map) // ❌ Error
```

### **Type Hierarchy**
```
Map<dynamic, dynamic> (LinkedMap) ← JSON.decode() returns this
    ↓
Map<String, dynamic> ← fromJson methods expect this
```

## ✅ Solution Implemented

### **1. Proper Type Casting**
```dart
// Before (causing error)
Map<String, dynamic>.from(json['contact'] as Map)

// After (fixed)
Map<String, dynamic>.from(json['contact'] as Map<dynamic, dynamic>)
```

### **2. Files Fixed**

#### **PropertyService.dart**
```dart
// ContactRecommendation.fromJson
factory ContactRecommendation.fromJson(Map<String, dynamic> json) {
  return ContactRecommendation(
    contact: Contact.fromJson(
      json['contact'] != null 
        ? Map<String, dynamic>.from(json['contact'] as Map<dynamic, dynamic>)
        : <String, dynamic>{}
    ),
    similarity: (json['similarity'] ?? 0.0).toDouble(),
    explanation: json['explanation'] ?? '',
  );
}

// Property parsing in getPropertiesList
final property = Property.fromJson(Map<String, dynamic>.from(propertyData as Map<dynamic, dynamic>));

// Property parsing in getProperty
return Property.fromJson(Map<String, dynamic>.from(jsonResponse['data'] as Map<dynamic, dynamic>));

// ContactRecommendation parsing in getPropertyRecommendations
recommendations = recommendationsList
    .map((item) => ContactRecommendation.fromJson(Map<String, dynamic>.from(item as Map<dynamic, dynamic>)))
    .toList();
```

#### **ContactsService.dart**
```dart
// PropertyRecommendation.fromJson
factory PropertyRecommendation.fromJson(Map<String, dynamic> json) {
  return PropertyRecommendation(
    property: json['property'] != null 
      ? Map<String, dynamic>.from(json['property'] as Map<dynamic, dynamic>)
      : <String, dynamic>{},
    similarity: (json['similarity'] ?? 0.0).toDouble(),
    combinedScore: (json['combinedScore'] ?? 0.0).toDouble(),
    matchType: json['matchType'] ?? 'primary',
    explanation: json['explanation'] ?? '',
  );
}

// Contact list parsing
'data': data.map((item) => Contact.fromJson(
  Map<String, dynamic>.from(item as Map<dynamic, dynamic>)
)).toList(),

// Single contact parsing
'data': Contact.fromJson(
  Map<String, dynamic>.from(jsonResponse['data'] as Map<dynamic, dynamic>)
),

// PropertyRecommendation parsing in getContactRecommendations
recommendations = recommendationsList
    .map((item) => PropertyRecommendation.fromJson(Map<String, dynamic>.from(item as Map<dynamic, dynamic>)))
    .toList();
```

#### **SalesService.dart**
```dart
// Sale.fromJson
contact: json['contact'] != null 
  ? Contact.fromJson(Map<String, dynamic>.from(json['contact'] as Map<dynamic, dynamic>)) 
  : null,
property: json['property'] != null 
  ? Property.fromJson(Map<String, dynamic>.from(json['property'] as Map<dynamic, dynamic>)) 
  : null,
```

#### **PropertyDetailsPage.dart**
```dart
// Property parsing in property details page
_property = Property.fromJson(Map<String, dynamic>.from(result['data'] as Map<dynamic, dynamic>));
```

#### **MapPage.dart**
```dart
// Property parsing in map page
return Property.fromJson(Map<String, dynamic>.from(propertyData as Map<dynamic, dynamic>));
```

## 🎯 Best Practices

### **1. Always Use Explicit Type Casting**
```dart
// ✅ Good - Explicit type casting
Map<String, dynamic>.from(json['data'] as Map<dynamic, dynamic>)

// ❌ Bad - Implicit casting
Map<String, dynamic>.from(json['data'] as Map)
```

### **2. Handle Null Values Properly**
```dart
// ✅ Good - Null safety
json['contact'] != null 
  ? Map<String, dynamic>.from(json['contact'] as Map<dynamic, dynamic>)
  : <String, dynamic>{}

// ❌ Bad - No null check
Map<String, dynamic>.from(json['contact'] as Map<dynamic, dynamic>)
```

### **3. Use Type-Safe Parsing**
```dart
// ✅ Good - Type-safe parsing
factory Model.fromJson(Map<String, dynamic> json) {
  return Model(
    field: json['field'] != null 
      ? Map<String, dynamic>.from(json['field'] as Map<dynamic, dynamic>)
      : <String, dynamic>{},
  );
}
```

### **4. Consistent Error Handling**
```dart
try {
  final data = Map<String, dynamic>.from(json['data'] as Map<dynamic, dynamic>);
  return Model.fromJson(data);
} catch (e) {
  print('JSON parsing error: $e');
  return Model.empty(); // Provide fallback
}
```

## 🔧 Alternative Solutions

### **1. Using json_annotation Package**
```dart
import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

@JsonSerializable()
class Model {
  final Map<String, dynamic> data;
  
  Model({required this.data});
  
  factory Model.fromJson(Map<String, dynamic> json) => _$ModelFromJson(json);
  Map<String, dynamic> toJson() => _$ModelToJson(this);
}
```

### **2. Using Built-Value Package**
```dart
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'model.g.dart';

abstract class Model implements Built<Model, ModelBuilder> {
  Map<String, dynamic> get data;
  
  Model._();
  factory Model([updates(ModelBuilder b)]) = _$Model;
  
  static Serializer<Model> get serializer => _$modelSerializer;
}
```

### **3. Manual Type Checking**
```dart
Map<String, dynamic> parseMap(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data;
  } else if (data is Map) {
    return Map<String, dynamic>.from(data);
  } else {
    throw FormatException('Expected Map, got ${data.runtimeType}');
  }
}
```

## ✅ **Fix Verification**

### **Test Results**
```bash
flutter test test/type_casting_test.dart
00:08 +6: All tests passed!
```

All type casting tests pass successfully, confirming that:
- ✅ ContactRecommendation.fromJson handles LinkedMap correctly
- ✅ PropertyRecommendation.fromJson handles LinkedMap correctly  
- ✅ Contact.fromJson handles LinkedMap correctly
- ✅ Property.fromJson handles LinkedMap correctly
- ✅ Null values are handled gracefully
- ✅ Empty maps are handled gracefully

## 🧪 Testing the Fix

### **1. Test JSON Parsing**
```dart
void testJsonParsing() {
  final jsonData = {
    'contact': {
      'id': '123',
      'name': 'Test Contact',
      'email': 'test@example.com'
    },
    'similarity': 0.85,
    'explanation': 'Test explanation'
  };
  
  // This should work without errors
  final recommendation = ContactRecommendation.fromJson(jsonData);
  expect(recommendation.contact.name, 'Test Contact');
  expect(recommendation.similarity, 0.85);
}
```

### **2. Test API Response**
```dart
void testApiResponse() async {
  final service = PropertyService();
  final result = await service.getPropertyRecommendations('property-id');
  
  expect(result['success'], true);
  expect(result['data'], isA<List<ContactRecommendation>>());
}
```

### **3. Test Error Handling**
```dart
void testErrorHandling() {
  final invalidJson = {
    'contact': 'invalid_data', // Should be Map, not String
    'similarity': 0.85
  };
  
  expect(() => ContactRecommendation.fromJson(invalidJson), 
         throwsA(isA<TypeError>()));
}
```

## 🚀 Performance Considerations

### **1. Minimize Type Conversions**
```dart
// ✅ Good - Single conversion
final data = Map<String, dynamic>.from(json['data'] as Map<dynamic, dynamic>);
final model = Model.fromJson(data);

// ❌ Bad - Multiple conversions
final model = Model.fromJson(Map<String, dynamic>.from(json['data'] as Map<dynamic, dynamic>));
```

### **2. Use Efficient Parsing**
```dart
// ✅ Good - Efficient parsing
factory Model.fromJson(Map<String, dynamic> json) {
  return Model(
    field: json['field'] as String? ?? '',
    number: (json['number'] as num?)?.toDouble() ?? 0.0,
  );
}
```

### **3. Cache Parsed Data**
```dart
// ✅ Good - Cache parsed data
class ApiService {
  final Map<String, dynamic> _cache = {};
  
  Future<Model> getModel(String id) async {
    if (_cache.containsKey(id)) {
      return Model.fromJson(_cache[id]!);
    }
    
    final response = await _fetchData(id);
    _cache[id] = response;
    return Model.fromJson(response);
  }
}
```

## 🔍 Debugging Tips

### **1. Print JSON Structure**
```dart
void debugJson(dynamic json) {
  print('JSON Type: ${json.runtimeType}');
  print('JSON Content: $json');
  
  if (json is Map) {
    print('Map Keys: ${json.keys.toList()}');
    print('Map Values: ${json.values.toList()}');
  }
}
```

### **2. Type Checking**
```dart
void checkTypes(dynamic data) {
  print('Data type: ${data.runtimeType}');
  print('Is Map: ${data is Map}');
  print('Is Map<String, dynamic>: ${data is Map<String, dynamic>}');
  print('Is Map<dynamic, dynamic>: ${data is Map<dynamic, dynamic>}');
}
```

### **3. Safe Parsing**
```dart
Map<String, dynamic> safeParseMap(dynamic data) {
  try {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      return Map<String, dynamic>.from(data);
    } else {
      print('Unexpected type: ${data.runtimeType}');
      return <String, dynamic>{};
    }
  } catch (e) {
    print('Parsing error: $e');
    return <String, dynamic>{};
  }
}
```

## 📚 Additional Resources

### **1. Flutter Documentation**
- [JSON and serialization](https://flutter.dev/docs/development/data-and-backend/json)
- [Type system](https://dart.dev/guides/language/language-tour#type-system)

### **2. Dart Documentation**
- [Type casting](https://dart.dev/guides/language/language-tour#type-test-operators)
- [Collections](https://dart.dev/guides/language/language-tour#lists)

### **3. Best Practices**
- [Error handling](https://dart.dev/guides/language/language-tour#exceptions)
- [Null safety](https://dart.dev/null-safety)

---

## 🇩🇿 Algeria Real Estate AI - Type Casting Fix

This guide ensures proper JSON parsing in the Algeria Real Estate AI system, preventing type casting errors and maintaining robust data handling across all API interactions. 