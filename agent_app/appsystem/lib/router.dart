import 'package:appsystem/core/responsive_layout.dart';
import 'package:appsystem/screens/auth/modern_login_page.dart';
import 'package:appsystem/screens/auth/modern_signup_page.dart';
import 'package:appsystem/screens/dashboard/modern_dashboard_page.dart';
import 'package:appsystem/screens/dashboard/map_page.dart';
import 'package:appsystem/screens/dashboard/leads_page.dart';
import 'package:appsystem/screens/chatbot/chatbot_page.dart';
import 'package:appsystem/screens/dashboard/settings_screen.dart';
import 'package:appsystem/screens/properties/add_property_page.dart';
import 'package:appsystem/screens/properties/property_list_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: '/dashboard/home',
  redirect: (context, state) {
    // Redirect /dashboard to /dashboard/home
    if (state.uri.toString() == '/dashboard') {
      return '/dashboard/home';
    }
    return null;
  },
  navigatorKey: _rootNavigatorKey,
  routes: [
    // Authentication routes
    GoRoute(
      path: '/auth',
      builder: (context, state) => const ModernLoginPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const ModernSignupPage(),
    ),
    
    // Dashboard shell route with responsive layout wrapper
    ShellRoute(
      builder: (context, state, child) {
        return ResponsiveLayout(
          currentRoute: state.uri.toString(),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/dashboard/home',
          builder: (context, state) => const ModernDashboardPage(),
        ),
        GoRoute(
          path: '/dashboard/overview',
          builder: (context, state) => const ModernDashboardPage(),
        ),
        GoRoute(
          path: '/dashboard/map',
          builder: (context, state) => const MapPage(),
        ),
        GoRoute(
          path: '/dashboard/leads',
          builder: (context, state) => const LeadsPage(),
        ),
        GoRoute(
          path: '/dashboard/properties',
          builder: (context, state) => const PropertiesPage(),
        ),
        GoRoute(
          path: '/dashboard/add-property',
          builder: (context, state) => const AddPropertyPage(),
        ),
        GoRoute(
          path: '/dashboard/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/dashboard/chatbot',
          builder: (context, state) => const ChatBotPage(),
        ),
      ],
    ),
    
    // Fallback route for any unmatched /dashboard/* routes
    GoRoute(
      path: '/dashboard',
      redirect: (context, state) => '/dashboard/home',
    ),
  ],
);
