import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';
import 'package:appsystem/theme.dart';
import 'package:appsystem/services/property_service.dart';

// Property type enum for map filtering
enum PropertyType {
  apartment,
  villa,
  house,
  office,
  shop,
  warehouse,
  land,
  garage,
}

/// A comprehensive map screen that displays OpenStreetMap with interactive features.
///
/// This screen provides:
/// - Interactive map with zoom and pan capabilities
/// - Animated property markers with smooth transitions
/// - Property clustering and detailed information
/// - Advanced filtering and search capabilities
/// - Responsive design that adapts to different screen sizes
/// - Integration with the app's theme system
/// - AI-powered potential clients matching
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

  /// Property service instance
  late final PropertyService _propertyService;

  /// Search and filter controllers
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  /// Default center location (Algiers, Algeria)
  static const LatLng _defaultCenter = LatLng(36.7538, 3.0588);

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
  String? _selectedPropertyType;
  double? _minPrice;
  double? _maxPrice;
  int? _minRooms;
  int? _maxRooms;

  /// Potential clients state
  List<ContactRecommendation> _potentialClients = [];
  bool _showPotentialClients = false;
  bool _isLoadingClients = false;

  /// Properties from API
  List<Property> _properties = [];
  bool _isLoadingProperties = true;
  String? _errorMessage;

  /// Get filtered properties based on search and filter criteria
  List<Property> get _filteredProperties {
    return _properties.where((property) {
      // Only include properties with valid coordinates
      if (property.latitude == null || property.longitude == null ||
          property.latitude == 0 && property.longitude == 0) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch =
            property.title.toLowerCase().contains(query) ||
            property.formattedPrice.toLowerCase().contains(query);
        if (!matchesSearch) return false;
      }

      // Property type filter
      if (_selectedPropertyType != null &&
          property.propertyType != _selectedPropertyType) {
        return false;
      }

      // Price filter
      if (_minPrice != null || _maxPrice != null) {
        final propertyPrice = property.price;
        if (_minPrice != null && propertyPrice < _minPrice!) {
          return false;
        }
        if (_maxPrice != null && propertyPrice > _maxPrice!) {
          return false;
        }
      }

      // Rooms filter
      if (_minRooms != null && property.rooms < _minRooms!) {
        return false;
      }
      if (_maxRooms != null && property.rooms > _maxRooms!) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Extract numeric price value from formatted price string
  double _extractPriceValue(String price) {
    try {
      final cleanPrice = price.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleanPrice) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _propertyService = PropertyService();
    _initializeAnimations();
    _searchController.addListener(_onSearchChanged);
    _loadPropertiesFromAPI();
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
    _propertyService.dispose();
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

  /// Load properties from API using the new Property model with pagination
  Future<void> _loadPropertiesFromAPI() async {
    try {
      setState(() {
        _isLoadingProperties = true;
        _errorMessage = null;
      });

      print('MapPage: Fetching properties from API...');

      // Use the new getPropertiesList method that returns List<Property> with pagination
      final properties = await _propertyService.getPropertiesList();

      print(
        'MapPage: Successfully loaded ${properties.length} properties from API',
      );

      setState(() {
        _properties = properties;
        _isLoadingProperties = false;
        _errorMessage = null;
      });

      // Show success message with property count
      if (properties.isNotEmpty) {
        final totalProperties = properties.length;
        final propertiesWithCoordinates = properties
            .where((p) => p.latitude != null && p.longitude != null && 
                         p.latitude != 0 && p.longitude != 0)
            .length;

        if (propertiesWithCoordinates == totalProperties) {
          _showSuccessSnackBar('تم تحميل $totalProperties عقار بنجاح');
        } else {
          _showSuccessSnackBar(
            'تم تحميل $propertiesWithCoordinates من $totalProperties عقار (بعض العقارات بدون إحداثيات)',
          );
        }
      } else {
        _showInfoSnackBar('لا توجد عقارات متاحة في قاعدة البيانات');
      }
    } catch (e) {
      print('MapPage: Error loading properties: $e');

      String errorMessage = 'فشل في تحميل العقارات';

      // Provide more specific error messages based on the error type
      if (e.toString().contains('timeout')) {
        errorMessage =
            'انتهت مهلة الاتصال - يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'فشل الاتصال بالشبكة - يرجى التحقق من اتصال الإنترنت';
      } else if (e.toString().contains('HttpException')) {
        errorMessage = 'خطأ في الاتصال بالخادم - يرجى المحاولة مرة أخرى لاحقاً';
      } else if (e.toString().contains('404')) {
        errorMessage = 'الخادم غير متاح - يرجى المحاولة مرة أخرى لاحقاً';
      } else if (e.toString().contains('500')) {
        errorMessage = 'خطأ في الخادم - يرجى المحاولة مرة أخرى لاحقاً';
      } else {
        errorMessage = 'خطأ في تحميل العقارات: $e';
      }

      setState(() {
        _errorMessage = errorMessage;
        _isLoadingProperties = false;
        _properties = [];
      });
      _showErrorSnackBar(errorMessage);
    }
  }

  /// Convert API property data to map property
  Property? _convertApiPropertyToMapProperty(
    Map<String, dynamic> propertyData,
  ) {
    try {
      // Check if property has coordinates - these are required for map display
      final latitude = propertyData['latitude'];
      final longitude = propertyData['longitude'];

      if (latitude == null || longitude == null) {
        print(
          'Property ${propertyData['id']} missing coordinates: lat=$latitude, lng=$longitude',
        );
        return null; // Skip properties without coordinates
      }

      // Create Property using the correct constructor
      return Property.fromJson(propertyData);
    } catch (e) {
      print('Error converting property ${propertyData['id']}: $e');
      return null;
    }
  }

  /// Format price in Algerian Dinar
  String _formatPrice(dynamic price) {
    try {
      final numPrice = (price ?? 0).toDouble();
      if (numPrice >= 1000000) {
        return '${(numPrice / 1000000).toStringAsFixed(1)}M';
      } else if (numPrice >= 1000) {
        return '${(numPrice / 1000).toStringAsFixed(0)}K';
      }
      return numPrice.toStringAsFixed(0);
    } catch (e) {
      return '0';
    }
  }

  /// Get default image URL for properties without images
  String _getDefaultImageUrl() {
    return 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400';
  }

  /// Show error message to user
  void _showErrorSnackBar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(message, style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: _loadPropertiesFromAPI,
            ),
          ),
        );
      }
    });
  }

  /// Show success message to user
  void _showSuccessSnackBar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(message, style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  /// Show info message to user
  void _showInfoSnackBar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(message, style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
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
      _minRooms = null;
      _maxRooms = null;
    });
  }

  /// Navigate to property on map
  void _navigateToProperty(Property property) {
    if (property.latitude != null && property.longitude != null) {
      _mapController.move(LatLng(property.latitude!, property.longitude!), 15.0);
      _onPropertyTap(property);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
            // Loading overlay for properties
            if (_isLoadingProperties) _buildPropertiesLoadingOverlay(),
            // Loading overlay for potential clients
            if (_isLoadingClients) _buildLoadingOverlay(),
            // Potential clients display
            if (_showPotentialClients) _buildPotentialClientsOverlay(),
            // Empty state when no properties
            if (!_isLoadingProperties &&
                _properties.isEmpty &&
                _errorMessage == null)
              _buildEmptyState(),
            // Floating action buttons
            _buildFloatingButtons(),
          ],
        ),
      ),
    );
  }

  /// Builds empty state when no properties are available
  Widget _buildEmptyState() {
    // Determine the type of empty state
    bool isErrorState = _errorMessage != null;
    bool isNetworkError =
        _errorMessage?.contains('اتصال') == true ||
        _errorMessage?.contains('شبكة') == true ||
        _errorMessage?.contains('timeout') == true;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isErrorState
                  ? (isNetworkError ? Iconsax.wifi : Iconsax.warning_2)
                  : Iconsax.building,
              size: 64,
              color: isErrorState
                  ? (isNetworkError ? Colors.orange : Colors.red)
                  : Theme.of(context).primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isErrorState
                  ? (isNetworkError
                        ? 'مشكلة في الاتصال'
                        : 'خطأ في تحميل البيانات')
                  : 'لا توجد عقارات متاحة',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isErrorState
                  ? (_errorMessage ?? 'حدث خطأ غير متوقع')
                  : 'لم يتم العثور على عقارات في قاعدة البيانات',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadPropertiesFromAPI,
                  icon: const Icon(Iconsax.refresh),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                if (isNetworkError)
                  ElevatedButton.icon(
                    onPressed: () {
                      // Show network settings or help
                      _showNetworkHelpDialog();
                    },
                    icon: const Icon(Iconsax.info_circle),
                    label: const Text('مساعدة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show network help dialog
  void _showNetworkHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Iconsax.wifi, color: Colors.orange),
            const SizedBox(width: 8),
            Text('مشكلة في الاتصال'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('لحل مشكلة الاتصال:'),
            const SizedBox(height: 8),
            Text('• تأكد من اتصالك بالإنترنت'),
            Text('• تحقق من إعدادات الشبكة'),
            Text('• جرب إعادة تشغيل التطبيق'),
            Text('• تأكد من أن الخادم متاح'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadPropertiesFromAPI();
            },
            child: Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  /// Builds the header section with title and action buttons
  Widget _buildHeader() {
    String statusText;
    Color statusColor = Theme.of(context).primaryColor;
    IconData statusIcon = Iconsax.map;

    if (_isLoadingProperties) {
      statusText = 'جاري تحميل العقارات...';
      statusColor = Colors.blue;
      statusIcon = Icons.hourglass_empty;
    } else if (_errorMessage != null) {
      statusText = 'خطأ في تحميل البيانات';
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
    } else if (_properties.isEmpty) {
      statusText = 'لا توجد عقارات متاحة';
      statusColor = Colors.orange;
      statusIcon = Icons.info_outline;
    } else {
      // Show filtered count vs total count
      final totalCount = _properties.length;
      final filteredCount = _filteredProperties.length;

      if (filteredCount == totalCount) {
        statusText = '$totalCount عقار متاح';
      } else {
        statusText = '$filteredCount من $totalCount عقار (مفلتر)';
      }
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
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
          leading: Icon(
            Iconsax.map,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
          title: Text('الخريطة', style: Theme.of(context).textTheme.titleLarge),
          subtitle: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  statusText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: statusColor),
                ),
              ),
            ],
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
          icon: Iconsax.refresh,
          onPressed: _loadPropertiesFromAPI,
          tooltip: 'تحديث البيانات',
          isLoading: _isLoadingProperties,
        ),
        const SizedBox(width: 8),
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
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).primaryColor.withOpacity(0.2)
            : Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: Theme.of(context).primaryColor, width: 1)
            : null,
      ),
      child: IconButton(
        icon: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              )
            : Icon(
                icon,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ),
        onPressed: isLoading ? null : onPressed,
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
                  color: Theme.of(context).colorScheme.surface,
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
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'البحث عن عقار...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    prefixIcon: Icon(
                      Iconsax.search_normal,
                      color: Theme.of(context).primaryColor,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Iconsax.close_circle,
                              color: Theme.of(context).colorScheme.onPrimary,
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
                  color: Theme.of(context).colorScheme.surface,
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
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'الفلترة',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _clearFilters,
                          child: Text(
                            'مسح الكل',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Property Type Filter
                    Text(
                      'نوع العقار',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['APARTMENT', 'VILLA', 'HOUSE', 'OFFICE', 'SHOP', 'WAREHOUSE', 'LAND', 'GARAGE'].map((type) {
                        final isSelected = _selectedPropertyType == type;
                        return FilterChip(
                          label: Text(_getPropertyTypeName(type)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedPropertyType = selected ? type : null;
                            });
                          },
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          selectedColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.2),
                          checkmarkColor: Theme.of(context).primaryColor,
                          labelStyle: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).colorScheme.onPrimary,
                              ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Price Range Filter
                    Text(
                      'نطاق السعر (درهم)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            style: Theme.of(context).textTheme.bodySmall,
                            decoration: InputDecoration(
                              hintText: 'من',
                              hintStyle: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
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
                            style: Theme.of(context).textTheme.bodySmall,
                            decoration: InputDecoration(
                              hintText: 'إلى',
                              hintStyle: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            style: Theme.of(context).textTheme.bodySmall,
                            decoration: InputDecoration(
                              hintText: 'من',
                              hintStyle: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (value) {
                              _minRooms = int.tryParse(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            style: Theme.of(context).textTheme.bodySmall,
                            decoration: InputDecoration(
                              hintText: 'إلى',
                              hintStyle: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (value) {
                              _maxRooms = int.tryParse(value);
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
          color: Theme.of(context).colorScheme.surface,
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
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getPropertyIcon(property.propertyType),
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      property.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      property.formattedPrice,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Iconsax.location,
                        color: Theme.of(context).primaryColor,
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
  String _getPropertyTypeName(String type) {
    switch (type.toUpperCase()) {
      case 'APARTMENT':
        return 'شقة';
      case 'VILLA':
        return 'فيلا';
      case 'HOUSE':
        return 'بيت';
      case 'OFFICE':
        return 'مكتب';
      case 'SHOP':
        return 'محل';
      case 'WAREHOUSE':
        return 'مستودع';
      case 'LAND':
        return 'أرض';
      case 'GARAGE':
        return 'كراج';
      default:
        return type;
    }
  }

  /// Get the appropriate icon for property type
  IconData _getPropertyIcon(String type) {
    switch (type.toUpperCase()) {
      case 'APARTMENT':
        return Iconsax.building;
      case 'VILLA':
      case 'HOUSE':
        return Iconsax.house;
      case 'OFFICE':
        return Iconsax.briefcase;
      case 'LAND':
        return Iconsax.map;
      case 'WAREHOUSE':
        return Iconsax.box;
      case 'SHOP':
        return Iconsax.shop;
      case 'GARAGE':
        return Iconsax.car;
      default:
        return Iconsax.building;
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
          point: LatLng(property.latitude!, property.longitude!),
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
                          ? Theme.of(context).primaryColor
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
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
                      _getPropertyIcon(property.propertyType),
                      color: _selectedProperty?.id == property.id
                          ? Colors.white
                          : Theme.of(context).primaryColor,
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
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Iconsax.building, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            onPressed: _toggleMapStyle,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: Icon(Iconsax.layer, color: Theme.of(context).primaryColor),
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
                color: Theme.of(context).colorScheme.surface,
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
          image: NetworkImage(_selectedProperty!.mainImageUrl),
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
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selectedProperty!.price} دج',
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
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Iconsax.location,
                color: Theme.of(context).primaryColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${_selectedProperty!.city ?? _selectedProperty!.wilaya ?? 'الجزائر'}, الجزائر',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPropertyFeature(
                Iconsax.home,
                '${_selectedProperty!.rooms} غرف',
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
                '${_selectedProperty!.scores.reduce((a, b) => a + b) / _selectedProperty!.scores.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 8),
              Text(
                'تقييم ممتاز',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
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
        Icon(icon, color: Theme.of(context).primaryColor, size: 16),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  /// Builds the loading overlay for properties
  Widget _buildPropertiesLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'جاري تحميل العقارات...',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'يتم جلب البيانات من الخادم',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
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
            color: Theme.of(context).colorScheme.surface,
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
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.3),
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
                              colors: [
                                Colors.blue,
                                Theme.of(context).primaryColor,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.3),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
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
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
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
                              color: Theme.of(context).primaryColor,
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${_potentialClients.length} عميل مطابق',
                          style: Theme.of(context).textTheme.bodyMedium
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
                  color: Theme.of(context).colorScheme.surface,
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
  Widget _buildAnimatedPotentialClientCard(
    ContactRecommendation client,
    int index,
  ) {
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
  Widget _buildPotentialClientCard(ContactRecommendation recommendation) {
    final contact = recommendation.contact;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: recommendation.statusColor.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _contactPotentialClient(recommendation),
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
                            recommendation.statusColor,
                            recommendation.statusColor.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          contact.name.split(' ').first[0],
                          style: Theme.of(context).textTheme.titleMedium
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
                            contact.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            contact.email,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
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
                        color: recommendation.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${recommendation.similarityPercentage}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: recommendation.statusColor,
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
                      contact.formattedBudget,
                      Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    _buildClientInfo(
                      Iconsax.call,
                      contact.phone ?? 'غير متوفر',
                      Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    _buildClientInfo(
                      Iconsax.flash,
                      recommendation.matchStatus,
                      recommendation.statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Contact type and transaction type
                Row(
                  children: [
                    _buildClientInfo(
                      Iconsax.user,
                      contact.typeDisplayName,
                      Colors.purple,
                    ),
                    const SizedBox(width: 16),
                    _buildClientInfo(
                      Iconsax.document,
                      contact.transactionTypeDisplayName,
                      Colors.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Property preferences
                if (contact.propertyTypes.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: contact.propertyTypes.take(3).map((type) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getPropertyTypeName(type),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 10,
                              ),
                        ),
                      );
                    }).toList(),
                  ),
                // Location preferences
                if (contact.locationWilayas.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Iconsax.location, color: Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'يفضل: ${contact.locationWilayas.take(2).join(', ')}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                          ),
                        ),
                      ],
                    ),
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  /// Contact potential client
  void _contactPotentialClient(ContactRecommendation recommendation) {
    final contact = recommendation.contact;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جاري الاتصال بـ ${contact.name}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
                    backgroundColor: Theme.of(context).primaryColor,
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
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
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
      SnackBar(
        content: Text('قائمة العقارات'),
        backgroundColor: Theme.of(context).primaryColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Toggles map style
  void _toggleMapStyle() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تغيير نمط الخريطة'),
        backgroundColor: Theme.of(context).primaryColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Contact agent action
  void _contactAgent() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جاري الاتصال بالوكيل...'),
        backgroundColor: Theme.of(context).primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Schedule viewing action
  void _scheduleViewing() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جاري فتح صفحة الحجز...'),
        backgroundColor: Theme.of(context).primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Get potential clients for the selected property
  void _getPotentialClients() async {
    if (_selectedProperty == null) return;

    setState(() {
      _isLoadingClients = true;
      _showPotentialClients = false;
    });

    try {
      // Fetch potential clients from API based on property
      final response = await _propertyService.getPropertyRecommendations(
        _selectedProperty!.id,
      );

      if (response['success'] == true) {
        final clientsData = response['data'] as List<ContactRecommendation>;

        setState(() {
          _potentialClients = clientsData;
          _isLoadingClients = false;
          _showPotentialClients = true;
        });

        // Start the staggered animation for clients
        _clientListController.forward();

        if (clientsData.isEmpty) {
          _showInfoSnackBar('لا توجد عملاء محتملين لهذا العقار');
        } else {
          _showSuccessSnackBar(
            'تم العثور على ${clientsData.length} عميل محتمل',
          );
        }
      } else {
        setState(() {
          _isLoadingClients = false;
        });

        String errorMessage =
            response['message'] ?? 'فشل في تحميل العملاء المحتملين';

        // Provide more specific error messages
        if (errorMessage.contains('timeout')) {
          errorMessage = 'انتهت مهلة الاتصال - يرجى المحاولة مرة أخرى';
        } else if (errorMessage.contains('network')) {
          errorMessage = 'خطأ في الاتصال بالشبكة - يرجى التحقق من الإنترنت';
        }

        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      setState(() {
        _isLoadingClients = false;
      });

      String errorMessage = 'خطأ في تحميل العملاء المحتملين';

      // Provide more specific error messages based on the error type
      if (e.toString().contains('timeout')) {
        errorMessage = 'انتهت مهلة الاتصال - يرجى المحاولة مرة أخرى';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'فشل الاتصال بالشبكة - يرجى التحقق من الإنترنت';
      } else if (e.toString().contains('HttpException')) {
        errorMessage = 'خطأ في الاتصال بالخادم - يرجى المحاولة مرة أخرى لاحقاً';
      } else {
        errorMessage = 'خطأ في تحميل العملاء المحتملين: $e';
      }

      _showErrorSnackBar(errorMessage);
    }
  }

  /// Extract interests from client data
  List<String> _extractInterests(Map<String, dynamic> clientData) {
    final interests = <String>[];

    // Add property type preference
    if (clientData['preferredPropertyType'] != null) {
      interests.add(
        _getPropertyTypeName(clientData['preferredPropertyType']),
      );
    }

    // Add location preferences
    if (clientData['locationWilayas'] != null) {
      final locations = clientData['locationWilayas'] as List<dynamic>;
      if (locations.isNotEmpty) {
        interests.add(locations.first.toString());
      }
    }

    // Add transaction type
    if (clientData['transactionType'] != null) {
      interests.add(clientData['transactionType'] == 'RENT' ? 'إيجار' : 'بيع');
    }

    return interests;
  }

  /// Determine client status based on data
  ClientStatus _determineClientStatus(Map<String, dynamic> clientData) {
    final similarity = clientData['similarity'] ?? 0.0;
    if (similarity > 0.8) return ClientStatus.hot;
    if (similarity > 0.6) return ClientStatus.warm;
    return ClientStatus.cold;
  }
}

/// Client status enum
enum ClientStatus { hot, warm, cold }
