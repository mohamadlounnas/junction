import 'package:flutter/material.dart';
import 'package:appsystem/core/mobile_layout.dart';
import 'package:appsystem/home.dart';

/// Enhanced responsive layout that shows recommendations in sidebar on desktop
class EnhancedResponsiveLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final Widget? recommendationsSidebar;
  final String? recommendationsTitle;
  final bool showRecommendations;

  const EnhancedResponsiveLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    this.recommendationsSidebar,
    this.recommendationsTitle,
    this.showRecommendations = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const mobileBreakpoint = 768.0; // Standard tablet breakpoint
    const desktopBreakpoint = 1200.0; // Desktop breakpoint for sidebar

    if (screenWidth < mobileBreakpoint) {
      // Mobile layout with bottom navigation
      return MobileLayout(currentRoute: currentRoute, child: child);
    } else if (screenWidth < desktopBreakpoint || !showRecommendations) {
      // Tablet layout or desktop without recommendations
      return DashboardView(content: child);
    } else {
      // Desktop layout with recommendations sidebar
      return _DesktopLayoutWithSidebar(
        child: child,
        recommendationsSidebar: recommendationsSidebar,
        recommendationsTitle: recommendationsTitle,
      );
    }
  }
}

/// Desktop layout with recommendations sidebar
class _DesktopLayoutWithSidebar extends StatefulWidget {
  final Widget child;
  final Widget? recommendationsSidebar;
  final String? recommendationsTitle;

  const _DesktopLayoutWithSidebar({
    required this.child,
    this.recommendationsSidebar,
    this.recommendationsTitle,
  });

  @override
  State<_DesktopLayoutWithSidebar> createState() => _DesktopLayoutWithSidebarState();
}

class _DesktopLayoutWithSidebarState extends State<_DesktopLayoutWithSidebar> {
  bool _isSidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: ColoredBox(color: Theme.of(context).colorScheme.surface),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 300,
              child: Image.asset(
                'assets/images/gard.jpeg',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            child: SizedBox(
              height: 300,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.surface.withAlpha(100),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Row(
              children: [
                // Main navigation sidebar
                _buildMainSidebar(),
                
                // Main content area
                Expanded(
                  child: Column(
                    children: [
                      // App bar
                      _buildAppBar(),
                      
                      // Content area
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadiusDirectional.only(
                              topStart: Radius.circular(17),
                            ),
                          ),
                          padding: const EdgeInsetsDirectional.only(
                            start: 1,
                            top: 1,
                          ),
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadiusDirectional.only(
                                topStart: Radius.circular(16),
                              ),
                            ),
                            child: widget.child,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Recommendations sidebar
                if (widget.recommendationsSidebar != null)
                  _buildRecommendationsSidebar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      width: 200,
      padding: const EdgeInsets.all(8),
      child: NavigationSidebar(
        mode: NavigationSidebarItemMode.full,
        onToggle: (value) {
          setState(() {
            _isSidebarExpanded = value;
          });
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      leading: DrawerButton(),
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      title: Row(
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: const []),
                Text(
                  "Welcome",
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.brightness_6,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.language,
              color: Colors.white,
            ),
            onSelected: (String languageCode) {},
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'en',
                    child: Text('English'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'ar',
                    child: Text('العربية'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'fr',
                    child: Text('Français'),
                  ),
                ],
          ),
        ],
      ),
      automaticallyImplyLeading: false,
      actions: const [AppBarActions(), SizedBox(width: 8)],
    );
  }

  Widget _buildRecommendationsSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 350,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Recommendations header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.recommendationsTitle ?? 'التوصيات الذكية',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    onPressed: () {
                      // TODO: Implement close sidebar functionality
                    },
                  ),
                ],
              ),
            ),
            
            // Recommendations content
            Expanded(
              child: widget.recommendationsSidebar!,
            ),
          ],
        ),
      ),
    );
  }
}

// Import the NavigationSidebar and AppBarActions from the existing home.dart
// These are placeholder references - you'll need to import them properly
class NavigationSidebar extends StatelessWidget {
  final NavigationSidebarItemMode mode;
  final Function(bool) onToggle;

  const NavigationSidebar({
    super.key,
    required this.mode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder implementation
    return Container();
  }
}

enum NavigationSidebarItemMode {
  square,
  squareWithTitle,
  full,
}

class AppBarActions extends StatelessWidget {
  const AppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder implementation
    return Container();
  }
} 