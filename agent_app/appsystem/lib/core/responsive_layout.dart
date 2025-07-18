import 'package:flutter/material.dart';
import 'package:appsystem/core/mobile_layout.dart';
import 'package:appsystem/home.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const ResponsiveLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const mobileBreakpoint = 768.0; // Standard tablet breakpoint

    if (screenWidth < mobileBreakpoint) {
      // Mobile layout with bottom navigation
      return MobileLayout(currentRoute: currentRoute, child: child);
    } else {
      // Desktop layout with sidebar
      return DashboardView(content: child);
    }
  }
}
