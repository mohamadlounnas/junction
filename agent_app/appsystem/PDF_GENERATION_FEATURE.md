# PDF Quote Generation Feature

## Overview

The PDF Quote Generation feature allows users to create professional PDF quotes for properties with selected contacts. This feature integrates with the backend API to generate customized quotes with company information and property details.

## Features

- **Contact Selection**: Choose from available contacts for quote generation
- **PDF Generation**: Create professional PDF quotes via API
- **Multiple Actions**: Download, share, or open generated PDFs
- **Arabic Support**: Full Arabic language support for quotes
- **Company Customization**: Configurable company information
- **Error Handling**: Comprehensive error handling and user feedback

## How to Use

### 1. Access Property Details
1. Navigate to the Properties page
2. Select a property to view its details
3. The property details page will display with a floating action button

### 2. Generate PDF Quote
1. Click the "إنشاء عرض سعر PDF" (Generate PDF Quote) floating action button
2. A contact selection dialog will appear
3. Search and select a contact from the list
4. Click "اختيار" (Select) to proceed

### 3. PDF Generation Process
1. The system will show a loading dialog during PDF generation
2. Once complete, a success dialog will display with:
   - Quote number
   - Total amount
   - Validity period
   - Action options

### 4. PDF Actions
Choose from the following actions:
- **تحميل PDF** (Download PDF): Download the file to device
- **مشاركة** (Share): Share the PDF via system share dialog
- **فتح** (Open): Open the PDF in a PDF viewer

## Technical Implementation

### API Integration

The feature uses the following API endpoints:

```dart
// Generate PDF Quote
POST https://junction.feeef.org/api/quotes/pdf

// Download PDF
GET https://junction.feeef.org/api/quotes/download/{fileName}
```

### Request Format

```json
{
  "propertyId": "cmd9e93z9000rmax9hj0a1uyz",
  "contactId": "cmd9h1xtn001t13hmpvjmgwpm",
  "language": "ar",
  "format": "",
  "orientation": "",
  "companyInfo": {
    "name": "شركة العقارات الذكية",
    "address": "الجزائر العاصمة، الجزائر",
    "phone": "+213 123 456 789",
    "email": "info@smartcontact.dz",
    "website": "www.smartcontact.dz",
    "taxId": "123456789"
  }
}
```

### Response Format

```json
{
  "success": true,
  "pdf": {
    "fileName": "quote-QUO-20250719-592957.pdf",
    "downloadUrl": "/api/quotes/download/quote-QUO-20250719-592957.pdf",
    "quote": {
      "quoteNumber": "QUO-20250719-592957",
      "totalAmount": 10245900,
      "currency": "DZD",
      "validUntil": "2025-08-18T07:53:12.957Z"
    }
  }
}
```

## Files Modified/Created

### New Files
- `lib/services/quote_service.dart` - Quote service for API integration
- `lib/widgets/contact_selection_dialog.dart` - Contact selection dialog
- `PDF_GENERATION_FEATURE.md` - This documentation file

### Modified Files
- `lib/screens/properties/property_details_page.dart` - Added PDF generation functionality
- `pubspec.yaml` - Added PDF handling dependencies

## Dependencies Added

```yaml
# PDF handling and file operations
open_file: ^3.3.2
share_plus: ^7.2.1
url_launcher: ^6.2.1
```

## Service Classes

### QuoteService
Main service for PDF quote generation with the following classes:

- `CompanyInfo` - Company information model
- `QuoteRequest` - Quote generation request model
- `QuoteResponse` - API response model
- `QuoteData` - PDF data model
- `QuoteDetails` - Quote details model

### Methods
- `generatePdfQuote()` - Generate PDF quote via API
- `downloadPdfQuote()` - Download PDF file
- `generateAndDownloadPdfQuote()` - Combined generation and download
- `formatPrice()` - Format price in Algerian Dinar
- `getDefaultCompanyInfo()` - Get default company information

## Widgets

### ContactSelectionDialog
A comprehensive dialog for selecting contacts with features:
- Search and filter contacts
- Display contact information
- Loading states and error handling
- Responsive design

## Error Handling

The implementation includes comprehensive error handling:

1. **Network Errors**: Timeout, connection failures
2. **API Errors**: Server errors, invalid responses
3. **File Operations**: Download, share, and open failures
4. **User Feedback**: Clear error messages and success notifications

## Future Enhancements

1. **File Storage**: Implement proper file storage for downloaded PDFs
2. **Offline Support**: Cache generated PDFs for offline access
3. **Template Customization**: Allow users to customize PDF templates
4. **Batch Generation**: Generate multiple quotes at once
5. **Email Integration**: Send quotes directly via email
6. **Signature Support**: Add digital signatures to quotes

## Testing

To test the feature:

1. Ensure the backend API is running and accessible
2. Navigate to a property details page
3. Click the PDF generation button
4. Select a contact and verify the PDF generation process
5. Test all action options (download, share, open)

## Troubleshooting

### Common Issues

1. **API Connection Failed**
   - Check network connectivity
   - Verify API endpoint is accessible
   - Check API authentication if required

2. **Contact Selection Issues**
   - Ensure contacts are available in the system
   - Check contact service connectivity

3. **PDF Generation Failed**
   - Verify property and contact IDs are valid
   - Check API response for specific error messages

4. **File Operations Failed**
   - Ensure proper permissions are granted
   - Check device storage availability
   - Verify PDF viewer is installed

## Security Considerations

1. **API Security**: All API calls use HTTPS
2. **Data Validation**: Input validation for all user data
3. **Error Handling**: No sensitive information in error messages
4. **File Security**: Temporary file handling with proper cleanup

## Performance Considerations

1. **Caching**: API responses are cached where appropriate
2. **Async Operations**: All file operations are asynchronous
3. **Memory Management**: Proper disposal of resources
4. **Loading States**: User feedback during long operations

## Accessibility

1. **Screen Reader Support**: Proper labels and descriptions
2. **Keyboard Navigation**: Full keyboard accessibility
3. **High Contrast**: Compatible with high contrast themes
4. **Font Scaling**: Supports dynamic font scaling 