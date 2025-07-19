import 'package:appsystem/providers/language_provider.dart';
import 'package:appsystem/router.dart';
import 'package:appsystem/services/leads_services.dart';
import 'package:appsystem/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => LeadsServices()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<LanguageProvider, ThemeProvider>(
        builder: (context, languageProvider, themeProvider, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: languageProvider.fullAppTitle,
            theme: AppTheme().getTheme(
              brightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
            ),
            routerConfig: router,
            locale: languageProvider.currentLocale,
            supportedLocales: const [
              Locale('ar'), // Arabic (RTL)
              Locale('en'), // English (LTR)
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return Directionality(
                textDirection: languageProvider.textDirection,
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
