# Bulk Messaging Guide

## Overview

The bulk messaging functionality allows you to send SMS and WhatsApp messages to multiple potential clients simultaneously when you find a property that matches their preferences. This feature is integrated into the Map Page and provides a seamless way to notify clients about new properties.

## Features

### 🚀 Core Functionality
- **Bulk SMS**: Send text messages to multiple clients at once
- **Bulk WhatsApp**: Send WhatsApp messages using WhatsApp Business API
- **Phone Number Validation**: Automatically validates and formats phone numbers
- **Progress Tracking**: Real-time progress updates during message sending
- **Error Handling**: Comprehensive error handling and reporting
- **Message Templates**: Pre-formatted messages with property details

### 📱 User Interface
- **Bulk Messaging Button**: Green button in the potential clients overlay
- **Message Preview**: Shows the message content before sending
- **Progress Dialog**: Displays sending progress with animations
- **Results Summary**: Shows success/failure counts after completion

## How to Use

### 1. Access Bulk Messaging
1. Navigate to the **Map Page**
2. Select a property on the map
3. Click **"العملاء المحتملون"** (Potential Clients) button
4. Click the **"رسالة جماعية"** (Bulk Message) button in the header

### 2. Choose Message Type
The dialog will show:
- **Number of recipients**: How many clients will receive the message
- **Message preview**: The content that will be sent
- **Two options**:
  - 📱 **رسالة نصية** (SMS): Send via text message
  - 💬 **واتساب** (WhatsApp): Send via WhatsApp

### 3. Send Messages
1. Select your preferred messaging method
2. The system will:
   - Validate phone numbers
   - Format numbers for international format
   - Send messages in batches
   - Show progress updates
   - Display final results

## Message Content

The automatically generated message includes:
```
مرحباً! لدينا ما تبحث عنه! 🏠

[Property Title]
نوع العقار: [Property Type]
الموقع: [Location]
السعر: [Price]

تواصل معنا الآن للحصول على التفاصيل الكاملة والترتيب لمعاينة العقار!

📞 للاتصال المباشر
📱 أو عبر الواتساب

شكراً لثقتكم بنا! 🙏
```

## Technical Implementation

### MessagingService Class

The `MessagingService` class handles all messaging operations:

```dart
class MessagingService {
  // SMS Methods
  Future<Map<String, dynamic>> sendBulkSMS({
    required List<String> recipients,
    required String message,
    String? senderId,
  });

  // WhatsApp Methods
  Future<Map<String, dynamic>> sendBulkWhatsApp({
    required List<String> recipients,
    required String message,
    String? templateName,
  });

  // Utility Methods
  List<String> formatPhoneNumbers({required List<String> phoneNumbers});
  Map<String, List<String>> validatePhoneNumbers(List<String> phoneNumbers);
  String generatePropertyNotificationMessage({...});
}
```

### API Configuration

To use the messaging service, you need to configure:

#### SMS API (Example providers: Twilio, Vonage, etc.)
```dart
static const String _baseUrl = 'https://your-sms-api.com';
static const String _apiKey = 'your-api-key';
```

#### WhatsApp Business API
```dart
static const String _whatsappEndpoint = 'https://graph.facebook.com/v17.0';
static const String _whatsappPhoneNumberId = 'your-phone-number-id';
static const String _whatsappAccessToken = 'your-access-token';
```

## Setup Instructions

### 1. SMS Provider Setup
1. Choose an SMS provider (Twilio, Vonage, etc.)
2. Get your API credentials
3. Update the `_baseUrl` and `_apiKey` in `MessagingService`

### 2. WhatsApp Business API Setup
1. Create a Meta Developer account
2. Set up WhatsApp Business API
3. Get your Phone Number ID and Access Token
4. Update the WhatsApp configuration in `MessagingService`

### 3. Environment Variables
For security, store API keys in environment variables:

```dart
// In MessagingService
static const String _apiKey = String.fromEnvironment('SMS_API_KEY');
static const String _whatsappAccessToken = String.fromEnvironment('WHATSAPP_ACCESS_TOKEN');
```

## Error Handling

The system handles various error scenarios:

### Common Errors
- **Invalid phone numbers**: Automatically filtered out
- **Network issues**: Retry mechanism with user feedback
- **API rate limits**: Automatic delays between requests
- **Authentication failures**: Clear error messages

### Error Messages
- `لا توجد أرقام هواتف صحيحة للعملاء المحتملين` - No valid phone numbers
- `فشل في إرسال الرسائل النصية` - SMS sending failed
- `خطأ في الاتصال بالشبكة` - Network connection error

## Testing

Run the messaging service tests:

```bash
flutter test test/messaging_service_test.dart
```

The tests cover:
- Phone number formatting
- Phone number validation
- Message generation
- API error handling
- Bulk sending scenarios

## Best Practices

### 1. Rate Limiting
- WhatsApp: 100 messages per second
- SMS: Varies by provider (typically 10-50 per second)
- Built-in delays prevent rate limit violations

### 2. Message Content
- Keep messages concise and professional
- Include clear call-to-action
- Use emojis sparingly for better readability
- Ensure compliance with local regulations

### 3. Phone Number Management
- Always validate phone numbers before sending
- Use international format (+213 for Algeria)
- Handle invalid numbers gracefully

### 4. User Experience
- Show clear progress indicators
- Provide detailed success/failure feedback
- Allow users to retry failed sends
- Maintain responsive UI during operations

## Troubleshooting

### Common Issues

#### Messages Not Sending
1. Check API credentials
2. Verify phone number format
3. Ensure network connectivity
4. Check API rate limits

#### Invalid Phone Numbers
1. Verify phone number validation logic
2. Check country code configuration
3. Ensure proper formatting

#### WhatsApp API Errors
1. Verify WhatsApp Business API setup
2. Check access token validity
3. Ensure phone number is registered
4. Verify message template approval

## Security Considerations

### API Key Management
- Never hardcode API keys in source code
- Use environment variables or secure storage
- Rotate keys regularly
- Monitor API usage for anomalies

### Data Privacy
- Only send messages to opted-in recipients
- Respect local privacy laws (GDPR, etc.)
- Provide opt-out mechanisms
- Log message sending for compliance

### Rate Limiting
- Implement proper rate limiting
- Monitor API quotas
- Handle rate limit errors gracefully
- Provide user feedback on limits

## Future Enhancements

### Planned Features
- **Message Templates**: Customizable message templates
- **Scheduling**: Schedule messages for later delivery
- **Analytics**: Track message delivery and response rates
- **A/B Testing**: Test different message formats
- **Integration**: Connect with CRM systems

### API Improvements
- **Webhook Support**: Real-time delivery status updates
- **Batch Processing**: Optimize for large recipient lists
- **Retry Logic**: Automatic retry for failed messages
- **Queue Management**: Handle message queuing

## Support

For technical support or questions about the bulk messaging functionality:

1. Check the test files for usage examples
2. Review the `MessagingService` documentation
3. Consult the API provider documentation
4. Contact the development team

---

**Note**: This functionality requires proper API credentials and compliance with local messaging regulations. Ensure you have the necessary permissions and follow best practices for bulk messaging. 