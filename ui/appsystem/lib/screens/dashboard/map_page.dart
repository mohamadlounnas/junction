import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';
import 'package:appsystem/theme.dart';

/// A comprehensive map screen that displays OpenStreetMap with interactive features.
///
/// This screen provides:
/// - Interactive map with zoom and pan capabilities
/// - Animated property markers with smooth transitions
/// - Property clustering and detailed information
/// - Advanced filtering and search capabilities
/// - Responsive design that adapts to different screen sizes
/// - Integration with the app's theme system
///
/// The map uses OpenStreetMap tiles for free, open-source mapping data.
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  /// Controller for the map widget
  final MapController _mapController = MapController();

  /// Search and filter controllers
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  /// Default center location (Dubai, UAE)
  static const LatLng _defaultCenter = LatLng(25.2048, 55.2708);

  /// Default zoom level for the map
  static const double _defaultZoom = 13.0;

  /// Animation controllers for smooth transitions
  late AnimationController _markerAnimationController;
  late AnimationController _propertyCardController;
  late AnimationController _clientListController;
  late AnimationController _searchAnimationController;
  late AnimationController _filterAnimationController;
  late Animation<double> _markerScaleAnimation;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _clientListFadeAnimation;
  late Animation<double> _searchSlideAnimation;
  late Animation<double> _filterSlideAnimation;

  /// Selected property for detailed view
  Property? _selectedProperty;
  bool _showPropertyCard = false;

  /// Search and filter state
  bool _showSearchBar = false;
  bool _showFilters = false;
  String _searchQuery = '';
  PropertyType? _selectedPropertyType;
  double? _minPrice;
  double? _maxPrice;
  int? _minBedrooms;
  int? _maxBedrooms;

  /// Potential clients state
  List<PotentialClient> _potentialClients = [];
  bool _showPotentialClients = false;
  bool _isLoadingClients = false;

  /// Sample properties data
  final List<Property> _properties = [
    Property(
      id: '1',
      title: 'فيلا فاخرة في دبي مارينا',
      titleEn: 'Luxury Villa in Dubai Marina',
      price: '2,500,000',
      currency: 'درهم',
      location: const LatLng(25.2048, 55.2708),
      type: PropertyType.villa,
      bedrooms: 4,
      bathrooms: 3,
      area: 450,
      rating: 4.8,
      imageUrl:
          'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=400',
    ),
    Property(
      id: '2',
      title: 'شقة عصرية في برج خليفة',
      titleEn: 'Modern Apartment in Burj Khalifa',
      price: '1,800,000',
      currency: 'درهم',
      location: const LatLng(25.1972, 55.2744),
      type: PropertyType.apartment,
      bedrooms: 3,
      bathrooms: 2,
      area: 280,
      rating: 4.6,
      imageUrl:
          'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=400',
    ),
    Property(
      id: '3',
      title: 'مكتب تجاري في وسط المدينة',
      titleEn: 'Commercial Office in City Center',
      price: '3,200,000',
      currency: 'درهم',
      location: const LatLng(25.2285, 55.2867),
      type: PropertyType.office,
      bedrooms: 0,
      bathrooms: 2,
      area: 320,
      rating: 4.7,
      imageUrl:
          'https://images.unsplash.com/photo-1497366216548-37526070297c?w=400',
    ),
    Property(
      id: '4',
      title: 'فيلا عائلية في جميرا',
      titleEn: 'Family Villa in Jumeirah',
      price: '4,500,000',
      currency: 'درهم',
      location: const LatLng(25.1800, 55.2400),
      type: PropertyType.villa,
      bedrooms: 5,
      bathrooms: 4,
      area: 600,
      rating: 4.9,
      imageUrl:
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=400',
    ),
    Property(
      id: '5',
      title: 'شقة استثمارية في دبي هيلز',
      titleEn: 'Investment Apartment in Dubai Hills',
      price: '1,200,000',
      currency: 'درهم',
      location: const LatLng(25.1500, 55.2000),
      type: PropertyType.apartment,
      bedrooms: 2,
      bathrooms: 2,
      area: 180,
      rating: 4.5,
      imageUrl:
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400',
    ),
    Property(
      id: '6',
      title: 'فيلا بحرية في جزيرة النخيل',
      titleEn: 'Beach Villa in Palm Island',
      price: '6,800,000',
      currency: 'درهم',
      location: const LatLng(25.1100, 55.1400),
      type: PropertyType.villa,
      bedrooms: 6,
      bathrooms: 5,
      area: 800,
      rating: 4.9,
      imageUrl:
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=400',
    ),
    Property(
      id: '7',
      title: 'شقة فاخرة في برج العرب',
      titleEn: 'Luxury Apartment in Burj Al Arab',
      price: '3,500,000',
      currency: 'درهم',
      location: const LatLng(25.1412, 55.1854),
      type: PropertyType.apartment,
      bedrooms: 4,
      bathrooms: 3,
      area: 350,
      rating: 4.8,
      imageUrl:
          'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=400',
    ),
  ];

  /// Get filtered properties based on search and filter criteria
  List<Property> get _filteredProperties {
    return _properties.where((property) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch =
            property.title.toLowerCase().contains(query) ||
            property.titleEn.toLowerCase().contains(query) ||
            property.price.contains(query);
        if (!matchesSearch) return false;
      }

      // Property type filter
      if (_selectedPropertyType != null &&
          property.type != _selectedPropertyType) {
        return false;
      }

      // Price filter
      if (_minPrice != null || _maxPrice != null) {
        final propertyPrice =
            double.tryParse(property.price.replaceAll(',', '')) ?? 0;
        if (_minPrice != null && propertyPrice < _minPrice!) {
          return false;
        }
        if (_maxPrice != null && propertyPrice > _maxPrice!) {
          return false;
        }
      }

      // Bedrooms filter
      if (_minBedrooms != null && property.bedrooms < _minBedrooms!) {
        return false;
      }
      if (_maxBedrooms != null && property.bedrooms > _maxBedrooms!) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _markerAnimationController.dispose();
    _propertyCardController.dispose();
    _clientListController.dispose();
    _searchAnimationController.dispose();
    _filterAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Initialize animation controllers and animations
  void _initializeAnimations() {
    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _propertyCardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _markerScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _markerAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _cardSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _propertyCardController, curve: Curves.easeInOut),
    );

    _searchSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _filterSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _filterAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _clientListController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _clientListFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _clientListController, curve: Curves.easeInOut),
    );

    // Start marker animation
    _markerAnimationController.forward();
  }

  /// Handle search text changes
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  /// Toggle search bar visibility
  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (_showSearchBar) {
        _searchAnimationController.forward();
        _searchFocusNode.requestFocus();
      } else {
        _searchAnimationController.reverse();
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  /// Toggle filter panel visibility
  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
      if (_showFilters) {
        _filterAnimationController.forward();
      } else {
        _filterAnimationController.reverse();
      }
    });
  }

  /// Clear all filters
  void _clearFilters() {
    setState(() {
      _selectedPropertyType = null;
      _minPrice = null;
      _maxPrice = null;
      _minBedrooms = null;
      _maxBedrooms = null;
    });
  }

  /// Navigate to property on map
  void _navigateToProperty(Property property) {
    _mapController.move(property.location, 15.0);
    _onPropertyTap(property);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Map section
            _buildMap(),
            // Header section
            _buildHeader(),
            // Search bar
            if (_showSearchBar) _buildSearchBar(),
            // Filter panel
            if (_showFilters) _buildFilterPanel(),
            // Search results
            if (_searchQuery.isNotEmpty && _filteredProperties.isNotEmpty)
              _buildSearchResults(),
            // Property details card
            if (_showPropertyCard) _buildPropertyCard(),
            // Loading overlay for potential clients
            if (_isLoadingClients) _buildLoadingOverlay(),
            // Potential clients display
            if (_showPotentialClients) _buildPotentialClientsOverlay(),
            // Floating action buttons
            _buildFloatingButtons(),
          ],
        ),
      ),
    );
  }

  /// Builds the header section with title and action buttons
  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(Iconsax.map, color: AppTheme.primaryGreen, size: 28),
          title: Text('الخريطة', style: AppTheme.getSafeTextTheme().titleLarge),
          subtitle: Text(
            'استكشف المواقع والعقارات',
            style: AppTheme.getSafeTextTheme().bodyMedium,
          ),
          trailing: _buildActionButtons(),
        ),
      ),
    );
  }

  /// Builds the action buttons for map controls
  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Iconsax.search_normal,
          onPressed: _toggleSearchBar,
          tooltip: 'البحث',
          isActive: _showSearchBar,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Iconsax.filter,
          onPressed: _toggleFilters,
          tooltip: 'الفلترة',
          isActive: _showFilters,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Iconsax.location,
          onPressed: _centerOnUserLocation,
          tooltip: 'موقعي الحالي',
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Iconsax.add,
          onPressed: _zoomIn,
          tooltip: 'تكبير',
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Iconsax.minus,
          onPressed: _zoomOut,
          tooltip: 'تصغير',
        ),
      ],
    );
  }

  /// Builds a single action button with consistent styling
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryGreen.withOpacity(0.2)
            : AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: AppTheme.primaryGreen, width: 1)
            : null,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive
              ? AppTheme.primaryGreen
              : AppTheme.primaryGreen.withOpacity(0.8),
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
      ),
    );
  }

  /// Builds the search bar
  Widget _buildSearchBar() {
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _searchSlideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -50 * (1 - _searchSlideAnimation.value)),
            child: Opacity(
              opacity: _searchSlideAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: AppTheme.getSafeTextTheme().bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'البحث عن عقار...',
                    hintStyle: AppTheme.getSafeTextTheme().bodyMedium?.copyWith(
                      color: AppTheme.textGrey,
                    ),
                    prefixIcon: Icon(
                      Iconsax.search_normal,
                      color: AppTheme.primaryGreen,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Iconsax.close_circle,
                              color: AppTheme.textGrey,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery = '';
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the filter panel
  Widget _buildFilterPanel() {
    return Positioned(
      top: _showSearchBar ? 160 : 100,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _filterSlideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -50 * (1 - _filterSlideAnimation.value)),
            child: Opacity(
              opacity: _filterSlideAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Iconsax.filter,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'الفلترة',
                          style: AppTheme.getSafeTextTheme().titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _clearFilters,
                          child: Text(
                            'مسح الكل',
                            style: AppTheme.getSafeTextTheme().bodySmall
                                ?.copyWith(color: AppTheme.primaryGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Property Type Filter
                    Text(
                      'نوع العقار',
                      style: AppTheme.getSafeTextTheme().bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: PropertyType.values.map((type) {
                        final isSelected = _selectedPropertyType == type;
                        return FilterChip(
                          label: Text(_getPropertyTypeName(type)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedPropertyType = selected ? type : null;
                            });
                          },
                          backgroundColor: AppTheme.cardBackground,
                          selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
                          checkmarkColor: AppTheme.primaryGreen,
                          labelStyle: AppTheme.getSafeTextTheme().bodySmall
                              ?.copyWith(
                                color: isSelected
                                    ? AppTheme.primaryGreen
                                    : AppTheme.textWhite,
                              ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Price Range Filter
                    Text(
                      'نطاق السعر (درهم)',
                      style: AppTheme.getSafeTextTheme().bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            style: AppTheme.getSafeTextTheme().bodySmall,
                            decoration: InputDecoration(
                              hintText: 'من',
                              hintStyle: AppTheme.getSafeTextTheme().bodySmall
                                  ?.copyWith(color: AppTheme.textGrey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppTheme.borderColor,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (value) {
                              _minPrice = double.tryParse(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            style: AppTheme.getSafeTextTheme().bodySmall,
                            decoration: InputDecoration(
                              hintText: 'إلى',
                              hintStyle: AppTheme.getSafeTextTheme().bodySmall
                                  ?.copyWith(color: AppTheme.textGrey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppTheme.borderColor,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (value) {
                              _maxPrice = double.tryParse(value);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Bedrooms Filter
                    Text(
                      'عدد الغرف',
                      style: AppTheme.getSafeTextTheme().bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            style: AppTheme.getSafeTextTheme().bodySmall,
                            decoration: InputDecoration(
                              hintText: 'من',
                              hintStyle: AppTheme.getSafeTextTheme().bodySmall
                                  ?.copyWith(color: AppTheme.textGrey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppTheme.borderColor,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (value) {
                              _minBedrooms = int.tryParse(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            style: AppTheme.getSafeTextTheme().bodySmall,
                            decoration: InputDecoration(
                              hintText: 'إلى',
                              hintStyle: AppTheme.getSafeTextTheme().bodySmall
                                  ?.copyWith(color: AppTheme.textGrey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppTheme.borderColor,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (value) {
                              _maxBedrooms = int.tryParse(value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds search results panel
  Widget _buildSearchResults() {
    final results = _filteredProperties;
    return Positioned(
      top: _showSearchBar
          ? (_showFilters ? 400 : 160)
          : (_showFilters ? 300 : 100),
      left: 16,
      right: 16,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'نتائج البحث (${results.length})',
                style: AppTheme.getSafeTextTheme().titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final property = results[index];
                  return ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getPropertyIcon(property.type),
                        color: AppTheme.primaryGreen,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      property.title,
                      style: AppTheme.getSafeTextTheme().bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${property.price} ${property.currency}',
                      style: AppTheme.getSafeTextTheme().bodySmall?.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Iconsax.location,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
                      onPressed: () => _navigateToProperty(property),
                    ),
                    onTap: () => _navigateToProperty(property),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get property type name in Arabic
  String _getPropertyTypeName(PropertyType type) {
    switch (type) {
      case PropertyType.villa:
        return 'فيلا';
      case PropertyType.apartment:
        return 'شقة';
      case PropertyType.office:
        return 'مكتب';
      case PropertyType.land:
        return 'أرض';
      case PropertyType.warehouse:
        return 'مستودع';
    }
  }

  /// Builds the main map widget with OpenStreetMap tiles
  Widget _buildMap() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _defaultCenter,
          initialZoom: _defaultZoom,
          minZoom: 3.0,
          maxZoom: 18.0,
          onTap: (_, point) => _onMapTap(point),
        ),
        children: [
          // OpenStreetMap tile layer
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.appsystem',
            maxZoom: 19,
            tileProvider: NetworkTileProvider(),
          ),
          // Property markers layer
          _buildPropertyMarkers(),
        ],
      ),
    );
  }

  /// Builds animated property markers
  Widget _buildPropertyMarkers() {
    return MarkerLayer(
      markers: _filteredProperties.map((property) {
        return Marker(
          point: property.location,
          width: 60,
          height: 60,
          child: AnimatedBuilder(
            animation: _markerScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _markerScaleAnimation.value,
                child: GestureDetector(
                  onTap: () => _onPropertyTap(property),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedProperty?.id == property.id
                          ? AppTheme.primaryGreen
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryGreen,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getPropertyIcon(property.type),
                      color: _selectedProperty?.id == property.id
                          ? Colors.white
                          : AppTheme.primaryGreen,
                      size: 24,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  /// Builds floating action buttons for additional features
  Widget _buildFloatingButtons() {
    return Positioned(
      bottom: 100,
      right: 16,
      child: Column(
        children: [
          FloatingActionButton.small(
            onPressed: _showPropertyList,
            backgroundColor: AppTheme.primaryGreen,
            child: const Icon(Iconsax.building, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            onPressed: _toggleMapStyle,
            backgroundColor: AppTheme.cardBackground,
            child: const Icon(Iconsax.layer, color: AppTheme.primaryGreen),
          ),
        ],
      ),
    );
  }

  /// Builds the property details card
  Widget _buildPropertyCard() {
    if (_selectedProperty == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _cardSlideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 300 * _cardSlideAnimation.value),
            child: Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Property image and basic info
                  _buildPropertyHeader(),
                  // Property details
                  _buildPropertyDetails(),
                  // Action buttons
                  _buildPropertyActions(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the property header with image and basic info
  Widget _buildPropertyHeader() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        image: DecorationImage(
          image: NetworkImage(_selectedProperty!.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),
          // Close button
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: _hidePropertyCard,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
          // Price tag
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selectedProperty!.price} ${_selectedProperty!.currency}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the property details section
  Widget _buildPropertyDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedProperty!.title,
            style: AppTheme.getSafeTextTheme().titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Iconsax.location, color: AppTheme.primaryGreen, size: 16),
              const SizedBox(width: 4),
              Text(
                'دبي، الإمارات العربية المتحدة',
                style: AppTheme.getSafeTextTheme().bodyMedium?.copyWith(
                  color: AppTheme.textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPropertyFeature(
                Iconsax.home,
                '${_selectedProperty!.bedrooms} غرف',
              ),
              const SizedBox(width: 16),
              _buildPropertyFeature(
                Iconsax.building,
                '${_selectedProperty!.bathrooms} حمام',
              ),
              const SizedBox(width: 16),
              _buildPropertyFeature(
                Iconsax.ruler,
                '${_selectedProperty!.area} م²',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Iconsax.star1, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                '${_selectedProperty!.rating}',
                style: AppTheme.getSafeTextTheme().bodyMedium,
              ),
              const SizedBox(width: 8),
              Text(
                'تقييم ممتاز',
                style: AppTheme.getSafeTextTheme().bodyMedium?.copyWith(
                  color: AppTheme.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a property feature item
  Widget _buildPropertyFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 16),
        const SizedBox(width: 4),
        Text(text, style: AppTheme.getSafeTextTheme().bodyMedium),
      ],
    );
  }

  /// Builds the loading overlay for potential clients
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AI processing animation with rotating particles
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer rotating ring
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value * 2 * 3.14159,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Inner rotating ring
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1500),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: -value * 2 * 3.14159,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Central AI icon with pulse effect
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.2),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue, AppTheme.primaryGreen],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Iconsax.cpu,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Animated text with typing effect
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: 35),
                duration: const Duration(milliseconds: 2000),
                builder: (context, value, child) {
                  final text = 'جاري البحث عن العملاء المحتملين...';
                  return Text(
                    text.substring(0, value.clamp(0, text.length)),
                    style: AppTheme.getSafeTextTheme().titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
              const SizedBox(height: 16),
              // Animated subtitle
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: 25),
                duration: const Duration(milliseconds: 1500),
                builder: (context, value, child) {
                  final text = 'الذكاء الاصطناعي يحلل البيانات';
                  return Text(
                    text.substring(0, value.clamp(0, text.length)),
                    style: AppTheme.getSafeTextTheme().bodyMedium?.copyWith(
                      color: AppTheme.textGrey,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
              const SizedBox(height: 24),
              // Enhanced progress indicator
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: AppTheme.textGrey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryGreen,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),
              // Particle effects
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 600 + index * 200),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, -10 * value),
                        child: Opacity(
                          opacity: 1 - value,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the potential clients overlay
  Widget _buildPotentialClientsOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showPotentialClients = false;
                        _potentialClients.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'العملاء المحتملون',
                          style: AppTheme.getSafeTextTheme().titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${_potentialClients.length} عميل مطابق',
                          style: AppTheme.getSafeTextTheme().bodyMedium
                              ?.copyWith(color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Clients list
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AnimatedBuilder(
                  animation: _clientListFadeAnimation,
                  builder: (context, child) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _potentialClients.length,
                      itemBuilder: (context, index) {
                        final client = _potentialClients[index];
                        return _buildAnimatedPotentialClientCard(client, index);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an animated potential client card with staggered animation
  Widget _buildAnimatedPotentialClientCard(PotentialClient client, int index) {
    // Calculate delay based on index for staggered effect
    final delay = index * 200.0; // 200ms delay between each card
    final animationValue = _clientListFadeAnimation.value;

    // Calculate if this card should be visible based on delay
    final cardAnimationValue = (animationValue * 1000 - delay) / 800.0;
    final isVisible = cardAnimationValue > 0;

    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return _buildPotentialClientCard(client);
  }

  /// Builds a potential client card
  Widget _buildPotentialClientCard(PotentialClient client) {
    final statusColors = {
      ClientStatus.hot: Colors.red,
      ClientStatus.warm: Colors.orange,
      ClientStatus.cold: Colors.grey,
    };

    final statusLabels = {
      ClientStatus.hot: 'ساخن',
      ClientStatus.warm: 'دافئ',
      ClientStatus.cold: 'بارد',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColors[client.status]!.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _contactPotentialClient(client),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Client avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColors[client.status]!,
                            statusColors[client.status]!.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          client.name.split(' ').first[0],
                          style: AppTheme.getSafeTextTheme().titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.name,
                            style: AppTheme.getSafeTextTheme().titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            client.email,
                            style: AppTheme.getSafeTextTheme().bodySmall
                                ?.copyWith(color: AppTheme.textGrey),
                          ),
                        ],
                      ),
                    ),
                    // Match score
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${client.matchScore.toInt()}%',
                        style: AppTheme.getSafeTextTheme().bodySmall?.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildClientInfo(
                      Iconsax.money,
                      client.budget,
                      AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 16),
                    _buildClientInfo(Iconsax.call, client.phone, Colors.blue),
                    const SizedBox(width: 16),
                    _buildClientInfo(
                      Iconsax.flash,
                      statusLabels[client.status]!,
                      statusColors[client.status]!,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Interests
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: client.interests.take(3).map((interest) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        interest,
                        style: AppTheme.getSafeTextTheme().bodySmall?.copyWith(
                          color: AppTheme.primaryGreen,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds client information item
  Widget _buildClientInfo(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTheme.getSafeTextTheme().bodySmall?.copyWith(
            color: AppTheme.textGrey,
          ),
        ),
      ],
    );
  }

  /// Contact potential client
  void _contactPotentialClient(PotentialClient client) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جاري الاتصال بـ ${client.name}'),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Builds the property action buttons
  Widget _buildPropertyActions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _contactAgent,
                  icon: const Icon(Iconsax.message),
                  label: const Text('تواصل مع الوكيل'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _scheduleViewing,
                  icon: const Icon(Iconsax.calendar),
                  label: const Text('حجز معاينة'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _getPotentialClients,
              icon: const Icon(Iconsax.user_search),
              label: const Text('العملاء المحتملون'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gets the appropriate icon for property type
  IconData _getPropertyIcon(PropertyType type) {
    switch (type) {
      case PropertyType.apartment:
        return Iconsax.building;
      case PropertyType.villa:
        return Iconsax.house;
      case PropertyType.office:
        return Iconsax.briefcase;
      case PropertyType.land:
        return Iconsax.map;
      case PropertyType.warehouse:
        return Iconsax.box;
    }
  }

  /// Handles map tap events
  void _onMapTap(LatLng point) {
    _hidePropertyCard();
  }

  /// Handles property marker tap events
  void _onPropertyTap(Property property) {
    setState(() {
      _selectedProperty = property;
      _showPropertyCard = true;
    });
    _propertyCardController.forward();
  }

  /// Hides the property card
  void _hidePropertyCard() {
    _propertyCardController.reverse().then((_) {
      setState(() {
        _showPropertyCard = false;
        _selectedProperty = null;
      });
    });
  }

  /// Centers the map on user's current location
  void _centerOnUserLocation() {
    _mapController.move(_defaultCenter, _defaultZoom);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم الانتقال إلى موقعك الحالي'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// Zooms in the map
  void _zoomIn() {
    final currentCenter = _mapController.camera.center;
    final currentZoom = _mapController.camera.zoom;
    if (currentZoom < 18.0) {
      _mapController.move(currentCenter, currentZoom + 1);
    }
  }

  /// Zooms out the map
  void _zoomOut() {
    final currentCenter = _mapController.camera.center;
    final currentZoom = _mapController.camera.zoom;
    if (currentZoom > 3.0) {
      _mapController.move(currentCenter, currentZoom - 1);
    }
  }

  /// Shows property list
  void _showPropertyList() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('قائمة العقارات'),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// Toggles map style
  void _toggleMapStyle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تغيير نمط الخريطة'),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// Contact agent action
  void _contactAgent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري الاتصال بالوكيل...'),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Schedule viewing action
  void _scheduleViewing() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري فتح صفحة الحجز...'),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Get potential clients for the selected property
  void _getPotentialClients() async {
    setState(() {
      _isLoadingClients = true;
      _showPotentialClients = false;
    });

    // Simulate AI processing delay
    await Future.delayed(const Duration(seconds: 3));

    // Generate potential clients based on property
    final clients = _generatePotentialClients();

    setState(() {
      _potentialClients = clients;
      _isLoadingClients = false;
      _showPotentialClients = true;
    });

    // Start the staggered animation for clients
    _clientListController.forward();
  }

  /// Generate potential clients based on selected property
  List<PotentialClient> _generatePotentialClients() {
    final property = _selectedProperty!;

    return [
      PotentialClient(
        id: '1',
        name: 'أحمد محمد علي',
        email: 'ahmed.mohamed@email.com',
        phone: '+971 50 123 4567',
        budget: property.price,
        matchScore: 95,
        interests: ['فيلا فاخرة', 'مسبح خاص', 'مطبخ مفتوح'],
        lastActivity: DateTime.now().subtract(const Duration(hours: 2)),
        status: ClientStatus.hot,
      ),
      PotentialClient(
        id: '2',
        name: 'سارة أحمد حسن',
        email: 'sara.ahmed@email.com',
        phone: '+971 55 987 6543',
        budget: property.price,
        matchScore: 87,
        interests: ['شقة عصرية', 'إطلالة على المدينة', 'مرافق رياضية'],
        lastActivity: DateTime.now().subtract(const Duration(days: 1)),
        status: ClientStatus.warm,
      ),
      PotentialClient(
        id: '3',
        name: 'محمد عبدالله سالم',
        email: 'mohamed.abdullah@email.com',
        phone: '+971 52 456 7890',
        budget: property.price,
        matchScore: 92,
        interests: ['مكتب تجاري', 'موقف سيارات', 'موقع استراتيجي'],
        lastActivity: DateTime.now().subtract(const Duration(minutes: 30)),
        status: ClientStatus.hot,
      ),
      PotentialClient(
        id: '4',
        name: 'فاطمة خالد محمد',
        email: 'fatima.khalid@email.com',
        phone: '+971 54 321 0987',
        budget: property.price,
        matchScore: 78,
        interests: ['فيلا عائلية', 'حديقة خاصة', 'غرف ضيوف'],
        lastActivity: DateTime.now().subtract(const Duration(days: 3)),
        status: ClientStatus.cold,
      ),
    ];
  }
}

/// Property data model
class Property {
  final String id;
  final String title;
  final String titleEn;
  final String price;
  final String currency;
  final LatLng location;
  final PropertyType type;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final double rating;
  final String imageUrl;

  Property({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.price,
    required this.currency,
    required this.location,
    required this.type,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.rating,
    required this.imageUrl,
  });
}

/// Property types enum
enum PropertyType { apartment, villa, office, land, warehouse }

/// Potential client data model
class PotentialClient {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String budget;
  final double matchScore;
  final List<String> interests;
  final DateTime lastActivity;
  final ClientStatus status;

  PotentialClient({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.budget,
    required this.matchScore,
    required this.interests,
    required this.lastActivity,
    required this.status,
  });
}

/// Client status enum
enum ClientStatus { hot, warm, cold }
