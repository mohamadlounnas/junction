import 'package:appsystem/providers/language_provider.dart';
import 'package:appsystem/router.dart';
import 'package:appsystem/services/leads_services.dart';
import 'package:appsystem/theme.dart';
import 'package:flutter/material.dart';
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
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'وكيل عقارات محترف - Professional Real Estate Agent',
            theme: AppTheme().getTheme(),
            routerConfig: router,
            locale: languageProvider.currentLocale,
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            builder: (context, child) {
              return Directionality(
                textDirection:
                    languageProvider.currentLocale.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
