import 'package:appsystem/core/responsive_layout.dart';
import 'package:appsystem/screens/auth/modern_login_page.dart';
import 'package:appsystem/screens/auth/modern_signup_page.dart';
import 'package:appsystem/screens/dashboard/modern_dashboard_page.dart';
import 'package:appsystem/screens/dashboard/content_library_page.dart';
import 'package:appsystem/screens/dashboard/settings_page.dart';
import 'package:appsystem/screens/dashboard/map_page.dart';
import 'package:appsystem/screens/dashboard/leads_page.dart';
import 'package:appsystem/screens/chatbot/chatbot_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: '/dashboard/home',
  redirect: (context, state) {
    return null;
  },
  navigatorKey: _rootNavigatorKey,
  routes: [
    GoRoute(
      path: "/dashboard",
      builder: (context, state) => ResponsiveLayout(
        currentRoute: state.uri.toString(),
        child: const ModernDashboardPage(),
      ),
      routes: [
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return ResponsiveLayout(
              currentRoute: state.uri.toString(),
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const ModernDashboardPage(),
            ),
            GoRoute(path: '/map', builder: (context, state) => const MapPage()),
            GoRoute(
              path: '/leads',
              builder: (context, state) => const LeadsPage(),
            ),
            GoRoute(
              path: '/properties',
              builder: (context, state) => const PropertyListPage(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
            GoRoute(
              path: '/chatbot',
              builder: (context, state) => const ChatBotPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const ModernLoginPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const ModernSignupPage(),
    ),
  ],
);
