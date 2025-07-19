import 'package:flutter/material.dart';

/// Language Provider for managing app localization and RTL support
/// 
/// Handles language switching between Arabic (RTL) and English (LTR)
/// with proper locale management and text direction handling.
class LanguageProvider extends ChangeNotifier {
  // Default to Arabic for RTL support
  Locale _currentLocale = const Locale('ar');

  /// Get current locale
  Locale get currentLocale => _currentLocale;

  /// Get current language code
  String get currentLanguageCode => _currentLocale.languageCode;

  /// Get text direction based on current language
  TextDirection get textDirection => isArabic ? TextDirection.rtl : TextDirection.ltr;

  /// Check if current language is Arabic
  bool get isArabic => _currentLocale.languageCode == 'ar';

  /// Check if current language is English
  bool get isEnglish => _currentLocale.languageCode == 'en';

  /// Check if current language uses RTL
  bool get isRTL => isArabic;

  /// Set language by language code
  void setLanguage(String languageCode) {
    if (languageCode != 'ar' && languageCode != 'en') {
      throw ArgumentError('Unsupported language code: $languageCode');
    }
    
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  /// Toggle between Arabic and English
  void toggleLanguage() {
    if (isArabic) {
      _currentLocale = const Locale('en');
    } else {
      _currentLocale = const Locale('ar');
    }
    notifyListeners();
  }

  /// Set to Arabic (RTL)
  void setArabic() {
    _currentLocale = const Locale('ar');
    notifyListeners();
  }

  /// Set to English (LTR)
  void setEnglish() {
    _currentLocale = const Locale('en');
    notifyListeners();
  }

  /// Get localized text based on current language
  String getLocalizedText({
    required String arabic,
    required String english,
  }) {
    return isArabic ? arabic : english;
  }

  /// Get localized text with fallback
  String getLocalizedTextWithFallback({
    String? arabic,
    String? english,
    String fallback = '',
  }) {
    if (isArabic && arabic != null) return arabic;
    if (isEnglish && english != null) return english;
    return fallback;
  }

  /// Get app title based on current language
  String get appTitle => getLocalizedText(
    arabic: 'وكيل عقارات محترف',
    english: 'Professional Real Estate Agent',
  );

  /// Get full app title with both languages
  String get fullAppTitle => 'وكيل عقارات محترف - Professional Real Estate Agent';
}
