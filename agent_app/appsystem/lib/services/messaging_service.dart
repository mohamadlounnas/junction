import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for handling bulk messaging operations including SMS and WhatsApp
///
/// This service provides functionality to:
/// - Send bulk SMS messages to multiple recipients
/// - Send bulk WhatsApp messages using WhatsApp Business API
/// - Track message delivery status
/// - Handle message templates and personalization
/// - Manage rate limiting and error handling
class MessagingService {
  /// Base URL for the messaging API
  static const String _baseUrl = 'https://api.example.com/messaging';

  /// API key for authentication
  static const String _apiKey = 'your-api-key-here';

  /// WhatsApp Business API endpoint
  static const String _whatsappEndpoint = 'https://graph.facebook.com/v17.0';

  /// WhatsApp Business Phone Number ID
  static const String _whatsappPhoneNumberId = 'your-phone-number-id';

  /// WhatsApp Business Access Token
  static const String _whatsappAccessToken = 'your-access-token';

  /// Sends a bulk SMS message to multiple recipients
  ///
  /// [recipients] List of phone numbers to send SMS to
  /// [message] The message content to send
  /// [senderId] Optional sender ID for the SMS
  ///
  /// Returns a map containing success/failure information
  Future<Map<String, dynamic>> sendBulkSMS({
    required List<String> recipients,
    required String message,
    String? senderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sms/bulk'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'recipients': recipients,
          'message': message,
          'sender_id': senderId ?? 'REALESTATE',
          'priority': 'high',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'تم إرسال الرسائل النصية بنجاح',
        };
      } else {
        return {
          'success': false,
          'message': 'فشل في إرسال الرسائل النصية: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  /// Sends a bulk WhatsApp message to multiple recipients
  ///
  /// [recipients] List of phone numbers to send WhatsApp to
  /// [message] The message content to send
  /// [templateName] Optional WhatsApp template name
  ///
  /// Returns a map containing success/failure information
  Future<Map<String, dynamic>> sendBulkWhatsApp({
    required List<String> recipients,
    required String message,
    String? templateName,
  }) async {
    try {
      final results = <Map<String, dynamic>>[];
      int successCount = 0;
      int failureCount = 0;

      // Send WhatsApp to each recipient individually (WhatsApp API limitation)
      for (final phoneNumber in recipients) {
        try {
          final response = await http.post(
            Uri.parse('$_whatsappEndpoint/$_whatsappPhoneNumberId/messages'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_whatsappAccessToken',
            },
            body: jsonEncode({
              'messaging_product': 'whatsapp',
              'to': phoneNumber,
              'type': 'text',
              'text': {'body': message},
            }),
          );

          if (response.statusCode == 200) {
            successCount++;
            results.add({
              'phone': phoneNumber,
              'status': 'success',
              'message_id': jsonDecode(response.body)['messages'][0]['id'],
            });
          } else {
            failureCount++;
            results.add({
              'phone': phoneNumber,
              'status': 'failed',
              'error': 'HTTP ${response.statusCode}',
            });
          }

          // Add delay to respect WhatsApp rate limits
          await Future.delayed(Duration(milliseconds: 100));
        } catch (e) {
          failureCount++;
          results.add({
            'phone': phoneNumber,
            'status': 'failed',
            'error': e.toString(),
          });
        }
      }

      return {
        'success': successCount > 0,
        'data': {
          'total': recipients.length,
          'success': successCount,
          'failed': failureCount,
          'results': results,
        },
        'message': 'تم إرسال $successCount رسالة واتساب بنجاح',
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في إرسال رسائل الواتساب: $e'};
    }
  }

  /// Sends a WhatsApp message using a template
  ///
  /// [recipients] List of phone numbers to send WhatsApp to
  /// [templateName] Name of the WhatsApp template
  /// [templateData] Data to fill in the template
  ///
  /// Returns a map containing success/failure information
  Future<Map<String, dynamic>> sendWhatsAppTemplate({
    required List<String> recipients,
    required String templateName,
    required Map<String, dynamic> templateData,
  }) async {
    try {
      final results = <Map<String, dynamic>>[];
      int successCount = 0;
      int failureCount = 0;

      for (final phoneNumber in recipients) {
        try {
          final response = await http.post(
            Uri.parse('$_whatsappEndpoint/$_whatsappPhoneNumberId/messages'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_whatsappAccessToken',
            },
            body: jsonEncode({
              'messaging_product': 'whatsapp',
              'to': phoneNumber,
              'type': 'template',
              'template': {
                'name': templateName,
                'language': {'code': 'ar'},
                'components': [
                  {
                    'type': 'body',
                    'parameters': templateData.entries.map((entry) {
                      return {'type': 'text', 'text': entry.value.toString()};
                    }).toList(),
                  },
                ],
              },
            }),
          );

          if (response.statusCode == 200) {
            successCount++;
            results.add({
              'phone': phoneNumber,
              'status': 'success',
              'message_id': jsonDecode(response.body)['messages'][0]['id'],
            });
          } else {
            failureCount++;
            results.add({
              'phone': phoneNumber,
              'status': 'failed',
              'error': 'HTTP ${response.statusCode}',
            });
          }

          // Add delay to respect WhatsApp rate limits
          await Future.delayed(Duration(milliseconds: 100));
        } catch (e) {
          failureCount++;
          results.add({
            'phone': phoneNumber,
            'status': 'failed',
            'error': e.toString(),
          });
        }
      }

      return {
        'success': successCount > 0,
        'data': {
          'total': recipients.length,
          'success': successCount,
          'failed': failureCount,
          'results': results,
        },
        'message': 'تم إرسال $successCount رسالة واتساب بنجاح',
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في إرسال رسائل الواتساب: $e'};
    }
  }

  /// Checks the delivery status of sent messages
  ///
  /// [messageIds] List of message IDs to check status for
  ///
  /// Returns a map containing delivery status information
  Future<Map<String, dynamic>> checkDeliveryStatus({
    required List<String> messageIds,
  }) async {
    try {
      final results = <Map<String, dynamic>>[];

      for (final messageId in messageIds) {
        try {
          final response = await http.get(
            Uri.parse('$_whatsappEndpoint/$messageId'),
            headers: {'Authorization': 'Bearer $_whatsappAccessToken'},
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            results.add({
              'message_id': messageId,
              'status': data['status'] ?? 'unknown',
              'timestamp':
                  data['timestamp'] ?? DateTime.now().toIso8601String(),
            });
          } else {
            results.add({
              'message_id': messageId,
              'status': 'error',
              'error': 'HTTP ${response.statusCode}',
            });
          }
        } catch (e) {
          results.add({
            'message_id': messageId,
            'status': 'error',
            'error': e.toString(),
          });
        }
      }

      return {'success': true, 'data': results};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في التحقق من حالة الرسائل: $e'};
    }
  }

  /// Formats phone numbers for international format
  ///
  /// [phoneNumbers] List of phone numbers to format
  /// [countryCode] Country code to add (default: +213 for Algeria)
  ///
  /// Returns formatted phone numbers
  List<String> formatPhoneNumbers({
    required List<String> phoneNumbers,
    String countryCode = '+213',
  }) {
    return phoneNumbers.map((phone) {
      // Remove any non-digit characters
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

      // If phone starts with 0, replace with country code
      if (cleanPhone.startsWith('0')) {
        return countryCode + cleanPhone.substring(1);
      }

      // If phone doesn't start with country code, add it
      if (!cleanPhone.startsWith(countryCode.replaceAll('+', ''))) {
        return countryCode + cleanPhone;
      }

      return '+' + cleanPhone;
    }).toList();
  }

  /// Validates phone numbers
  ///
  /// [phoneNumbers] List of phone numbers to validate
  ///
  /// Returns a map with valid and invalid phone numbers
  Map<String, List<String>> validatePhoneNumbers(List<String> phoneNumbers) {
    final valid = <String>[];
    final invalid = <String>[];

    for (final phone in phoneNumbers) {
      // Basic validation for Algerian phone numbers
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

      if (cleanPhone.length >= 9 && cleanPhone.length <= 12) {
        valid.add(phone);
      } else {
        invalid.add(phone);
      }
    }

    return {'valid': valid, 'invalid': invalid};
  }

  /// Generates a property notification message
  ///
  /// [propertyTitle] Title of the property
  /// [propertyType] Type of the property
  /// [location] Location of the property
  /// [price] Price of the property
  /// [contactPhone] Contact phone number
  ///
  /// Returns formatted message for property notification
  String generatePropertyNotificationMessage({
    required String propertyTitle,
    required String propertyType,
    required String location,
    required String price,
    String? contactPhone,
  }) {
    return '''مرحباً! لدينا ما تبحث عنه! 🏠

$propertyTitle
نوع العقار: $propertyType
الموقع: $location
السعر: $price

تواصل معنا الآن للحصول على التفاصيل الكاملة والترتيب لمعاينة العقار!

📞 للاتصال المباشر${contactPhone != null ? ': $contactPhone' : ''}
📱 أو عبر الواتساب

شكراً لثقتكم بنا! 🙏''';
  }

  /// Disposes the service resources
  void dispose() {
    // Clean up any resources if needed
  }
}
