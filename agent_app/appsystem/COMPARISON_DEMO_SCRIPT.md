# 🎬 Property Comparison Feature Demo Script

## 📱 Demo Flow

### Scene 1: Property List View (0:00 - 0:10)

**Narrator**: "Welcome to the Algeria Real Estate AI system. Here you can see our property listings with a new comparison feature that helps you make informed investment decisions."

**Visual**: Show property cards with "قارن" (Compare) buttons on each card

### Scene 2: First Property Selection (0:10 - 0:20)

**Narrator**: "To compare properties, simply tap the compare button on the first property you're interested in."

**Visual**:

- Tap "قارن" button on first property
- Button changes to "محدد" (Selected) with checkmark icon
- Property card gets colored border
- Other properties show "قارن مع" (Compare with) buttons

### Scene 3: Second Property Selection (0:20 - 0:35)

**Narrator**: "Now tap the 'قارن مع' button on the second property to generate a professional comparison report."

**Visual**:

- Tap "قارن مع" button on second property
- Floating Action Button shows loading state: "جاري إنشاء المقارنة..."
- Loading spinner appears

### Scene 4: Success Dialog (0:35 - 0:50)

**Narrator**: "The system generates a comprehensive comparison and shows you the results with AI-powered recommendations."

**Visual**:

- Success dialog appears
- Shows property names being compared
- Displays recommendation text
- Shows "تحميل PDF" (Download PDF) button

### Scene 5: PDF Download (0:50 - 1:00)

**Narrator**: "You can download the professional PDF report for detailed analysis and sharing with clients."

**Visual**:

- Tap "تحميل PDF" button
- Success message appears: "تم تحميل الملف: professional-comparison-..."
- Dialog closes

### Scene 6: Feature Benefits (1:00 - 1:15)

**Narrator**: "This comparison feature provides data-driven insights, helping you make better investment decisions in the Algerian real estate market."

**Visual**:

- Show multiple property comparisons
- Highlight different property types
- Show various recommendations

## 🎯 Key Messages

### Primary Benefits

1. **Easy to Use**: Simple two-tap comparison process
2. **Professional Reports**: AI-generated PDF comparisons
3. **Data-Driven**: Based on comprehensive property analysis
4. **Algeria-Focused**: Optimized for Algerian real estate market

### Technical Features

1. **Visual Feedback**: Clear state indicators
2. **Loading States**: Progress indication during processing
3. **Error Handling**: Graceful error management
4. **Responsive Design**: Works on all screen sizes

## 📊 Demo Data

### Sample Properties for Demo

1. **Property 1**: "Terrain constructible à Tipaza" (Land)
2. **Property 2**: "Sell Apartment F4 Alger Dely brahim" (Apartment)

### Sample API Response

```json
{
  "success": true,
  "pdf": {
    "fileName": "professional-comparison-2025-07-19T08-00-17.pdf",
    "downloadUrl": "/api/quotes/download-comparison/...",
    "comparison": {
      "property1": "Terrain constructible à Tipaza",
      "property2": "Sell Apartment F4 Alger Dely brahim",
      "recommendedProperty": "property2",
      "confidenceLevel": "Medium",
      "recommendation": "Based on comprehensive analysis, Sell Apartment F4 Alger Dely brahim is recommended due to B+ investment grade and Market-rate pricing aligns with current Alger standards for apartment properties.",
      "analysisType": "PROFESSIONAL"
    }
  }
}
```

## 🎨 Visual Elements

### Color Scheme

- **Primary Blue**: For selected properties
- **Secondary Orange**: For compare buttons
- **Success Green**: For success states
- **Error Red**: For error states

### Icons Used

- **Add Icon**: Default compare state
- **Checkmark**: Selected state
- **Arrow**: Compare with state
- **Download**: PDF download action
- **Loading Spinner**: Processing state

### Typography

- **Arabic Text**: Right-to-left layout
- **Button Text**: 10px, bold
- **Dialog Text**: 14px, regular
- **Recommendation Text**: 12px, italic

## 🚀 Call to Action

### End of Demo

**Narrator**: "Experience the power of AI-driven property comparison. Start comparing properties today and make smarter investment decisions in Algeria's real estate market."

**Visual**:

- Show app logo
- Display contact information
- Show "Download Now" or "Try Demo" button

---

## 🇩🇿 Algeria Real Estate AI - Smart Property Comparison

*Empowering investors with data-driven insights for the Algerian real estate market.*
