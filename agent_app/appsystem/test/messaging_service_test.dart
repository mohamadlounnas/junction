import 'package:flutter_test/flutter_test.dart';
import 'package:appsystem/services/messaging_service.dart';

void main() {
  group('MessagingService Tests', () {
    late MessagingService messagingService;

    setUp(() {
      messagingService = MessagingService();
    });

    tearDown(() {
      messagingService.dispose();
    });

    group('Phone Number Formatting', () {
      test('should format Algerian phone numbers correctly', () {
        final phoneNumbers = [
          '0770123456',
          '0550123456',
          '021123456',
          '+213770123456',
          '213770123456',
        ];

        final formatted = messagingService.formatPhoneNumbers(
          phoneNumbers: phoneNumbers,
        );

        expect(formatted.length, equals(5));
        expect(formatted[0], equals('+213770123456'));
        expect(formatted[1], equals('+213550123456'));
        expect(formatted[2], equals('+21321123456'));
        expect(formatted[3], equals('+213770123456'));
        expect(formatted[4], equals('+213770123456'));
      });

      test('should handle empty phone numbers list', () {
        final formatted = messagingService.formatPhoneNumbers(phoneNumbers: []);

        expect(formatted, isEmpty);
      });
    });

    group('Phone Number Validation', () {
      test('should validate correct phone numbers', () {
        final phoneNumbers = ['+213770123456', '+213550123456', '+21321123456'];

        final validation = messagingService.validatePhoneNumbers(phoneNumbers);

        expect(validation['valid']!.length, equals(3));
        expect(validation['invalid']!.length, equals(0));
      });

      test('should reject invalid phone numbers', () {
        final phoneNumbers = [
          '+213770123456',
          '123', // Too short
          '12345678901234567890', // Too long
          'invalid',
        ];

        final validation = messagingService.validatePhoneNumbers(phoneNumbers);

        expect(validation['valid']!.length, equals(1));
        expect(validation['invalid']!.length, equals(3));
      });
    });

    group('Message Generation', () {
      test('should generate property notification message', () {
        final message = messagingService.generatePropertyNotificationMessage(
          propertyTitle: 'فيلا فاخرة في الجزائر العاصمة',
          propertyType: 'فيلا',
          location: 'الجزائر العاصمة',
          price: '150,000,000 دج',
          contactPhone: '+213770123456',
        );

        expect(message, contains('فيلا فاخرة في الجزائر العاصمة'));
        expect(message, contains('فيلا'));
        expect(message, contains('الجزائر العاصمة'));
        expect(message, contains('150,000,000 دج'));
        expect(message, contains('+213770123456'));
        expect(message, contains('مرحباً! لدينا ما تبحث عنه!'));
      });

      test('should generate message without contact phone', () {
        final message = messagingService.generatePropertyNotificationMessage(
          propertyTitle: 'شقة في وهران',
          propertyType: 'شقة',
          location: 'وهران',
          price: '50,000,000 دج',
        );

        expect(message, contains('شقة في وهران'));
        expect(message, contains('شقة'));
        expect(message, contains('وهران'));
        expect(message, contains('50,000,000 دج'));
        expect(message, contains('📞 للاتصال المباشر'));
        expect(message, isNot(contains('+213')));
      });
    });

    group('Bulk SMS', () {
      test('should handle empty recipients list', () async {
        final result = await messagingService.sendBulkSMS(
          recipients: [],
          message: 'Test message',
        );

        expect(result['success'], isFalse);
        expect(result['message'], contains('خطأ'));
      });

      test('should handle invalid API configuration', () async {
        final result = await messagingService.sendBulkSMS(
          recipients: ['+213770123456'],
          message: 'Test message',
        );

        // This should fail because the API key is not configured
        expect(result['success'], isFalse);
        expect(result['message'], contains('خطأ'));
      });
    });

    group('Bulk WhatsApp', () {
      test('should handle empty recipients list', () async {
        final result = await messagingService.sendBulkWhatsApp(
          recipients: [],
          message: 'Test message',
        );

        expect(result['success'], isFalse);
        expect(result['message'], contains('خطأ'));
      });

      test('should handle invalid WhatsApp configuration', () async {
        final result = await messagingService.sendBulkWhatsApp(
          recipients: ['+213770123456'],
          message: 'Test message',
        );

        // This should fail because the WhatsApp API is not configured
        expect(result['success'], isFalse);
        expect(result['message'], contains('خطأ'));
      });
    });

    group('WhatsApp Templates', () {
      test('should handle template sending', () async {
        final result = await messagingService.sendWhatsAppTemplate(
          recipients: ['+213770123456'],
          templateName: 'property_notification',
          templateData: {
            'property_title': 'فيلا فاخرة',
            'property_type': 'فيلا',
            'location': 'الجزائر العاصمة',
            'price': '150,000,000 دج',
          },
        );

        // This should fail because the WhatsApp API is not configured
        expect(result['success'], isFalse);
        expect(result['message'], contains('خطأ'));
      });
    });

    group('Delivery Status', () {
      test('should handle delivery status check', () async {
        final result = await messagingService.checkDeliveryStatus(
          messageIds: ['test_message_id'],
        );

        // This should fail because the WhatsApp API is not configured
        expect(result['success'], isFalse);
        expect(result['message'], contains('خطأ'));
      });
    });
  });
}
