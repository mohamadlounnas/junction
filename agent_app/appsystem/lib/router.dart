import 'package:appsystem/core/responsive_layout.dart';
import 'package:appsystem/screens/auth/modern_login_page.dart';
import 'package:appsystem/screens/auth/modern_signup_page.dart';

import 'package:appsystem/screens/dashboard/modern_dashboard_page.dart';
import 'package:appsystem/screens/dashboard/map_page.dart';
import 'package:appsystem/screens/chatbot/chatbot_page.dart';
import 'package:appsystem/screens/dashboard/settings_screen.dart';
import 'package:appsystem/screens/properties/add_property_page.dart';
import 'package:appsystem/screens/properties/property_list_page.dart';
import 'package:appsystem/screens/properties/property_details_page.dart';
import 'package:appsystem/screens/dashboard/contacts_page.dart';
import 'package:appsystem/screens/dashboard/contact_details_page.dart';
import 'package:appsystem/screens/dashboard/sales_page.dart';
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
          builder: (context, state) => const ContactsPage(),
        ),
        GoRoute(
          path: '/dashboard/contacts',
          builder: (context, state) => const ContactsPage(),
        ),
        GoRoute(
          path: '/dashboard/contact/:id',
          builder: (context, state) {
            final contactId = state.pathParameters['id']!;
            return ContactDetailsPage(contactId: contactId);
          },
        ),
        GoRoute(
          path: '/dashboard/sales',
          builder: (context, state) => const SalesPage(),
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
          path: '/dashboard/property/:id',
          builder: (context, state) {
            final propertyId = state.pathParameters['id']!;
            return PropertyDetailsPage(propertyId: propertyId);
          },
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
