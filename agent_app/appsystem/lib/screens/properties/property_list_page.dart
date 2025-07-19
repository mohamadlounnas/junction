import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../services/property_service.dart';

/// صفحة العقارات
/// تعرض جميع العقارات مع إمكانيات البحث والتصفية
/// الميزات:
/// - تصميم Material Design 3 حديث
/// - وظيفة السحب للتحديث
/// - البحث والتصفية
/// - تخطيط شبكي متجاوب
/// - حالات التحميل ومعالجة الأخطاء
/// - بطاقات عقارية مع عرض معلومات غنية
class PropertiesPage extends StatefulWidget {
  const PropertiesPage({super.key});

  @override
  State<PropertiesPage> createState() => _PropertiesPageState();
}

class _PropertiesPageState extends State<PropertiesPage> {
  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _filteredProperties = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _error = '';
  String _searchQuery = '';
  String _selectedFilter = 'الكل';
  
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // خيارات التصفية
  final List<String> _filterOptions = ['الكل', 'للبيع', 'للإيجار', 'شقة', 'فيلا', 'منزل'];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// تحميل العقارات من الخدمة
  Future<void> _loadProperties() async {
    if (!_isRefreshing) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final result = await PropertyService().getProperties();

      if (result['success'] == true) {
        setState(() {
          _properties = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _filteredProperties = _properties;
          _isLoading = false;
          _isRefreshing = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'فشل في تحميل العقارات';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ في الشبكة. يرجى التحقق من اتصالك.';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  /// تحديث قائمة العقارات
  Future<void> _refreshProperties() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadProperties();
  }

  /// تصفية العقارات بناءً على استعلام البحث والتصفية المحددة
  void _filterProperties() {
    setState(() {
      _filteredProperties = _properties.where((property) {
        final matchesSearch = _searchQuery.isEmpty ||
            property['title']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
            property['city']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
            property['wilaya']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true;

        final matchesFilter = _selectedFilter == 'الكل' ||
            property['transactionType']?.toString() == _selectedFilter ||
            property['propertyType']?.toString() == _selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  /// الحصول على عدد الأعمدة بناءً على حجم الشاشة
  int _getCrossAxisCount(double width) {
    if (width >= 1200) return 4; // Desktop large
    if (width >= 900) return 3;  // Desktop medium
    if (width >= 600) return 2;  // Tablet
    return 1; // Mobile
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _getCrossAxisCount(screenWidth);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _refreshProperties,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // قسم البحث والتصفية
            _buildSearchAndFilterSection(),
            
            // المحتوى
            _buildContentSection(crossAxisCount),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/dashboard/add-property'),
        icon: const Icon(Iconsax.add),
        label: const Text('إضافة عقار'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  /// بناء قسم البحث والتصفية
  Widget _buildSearchAndFilterSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // شريط البحث
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
                
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _filterProperties();
                },
                decoration: InputDecoration(
                  hintText: 'البحث في العقارات...',
                  prefixIcon: Icon(
                    Iconsax.search_normal,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                            _filterProperties();
                          },
                          icon: Icon(
                            Iconsax.close_circle,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // رقائق التصفية
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filterOptions.length,
                itemBuilder: (context, index) {
                  final filter = _filterOptions[index];
                  final isSelected = _selectedFilter == filter;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                        _filterProperties();
                      },
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      selectedColor: Theme.of(context).colorScheme.primaryContainer,
                      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء قسم المحتوى الرئيسي
  Widget _buildContentSection(int crossAxisCount) {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري تحميل العقارات...'),
            ],
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.warning_2,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'خطأ',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadProperties,
                  icon: const Icon(Iconsax.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_filteredProperties.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.home,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty || _selectedFilter != 'الكل'
                      ? 'لم يتم العثور على عقارات'
                      : 'لا توجد عقارات بعد',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty || _selectedFilter != 'الكل'
                      ? 'جرب تعديل البحث أو التصفية'
                      : 'أضف أول عقار للبدء',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.go('/dashboard/add-property'),
                  icon: const Icon(Iconsax.add),
                  label: const Text('إضافة عقار'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: crossAxisCount >= 4 ? 0.85 : 0.75, // أصغر للشاشات الكبيرة
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final property = _filteredProperties[index];
            return _buildPropertyCard(property);
          },
          childCount: _filteredProperties.length,
        ),
      ),
    );
  }

  /// بناء بطاقة عقار محسنة
  Widget _buildPropertyCard(Map<String, dynamic> property) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          context.go('/dashboard/property/${property['id']}');
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة العقار
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      color: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                    child: property['image_url'] != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: Image.network(
                              property['image_url'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage();
                              },
                            ),
                          )
                        : _buildPlaceholderImage(),
                  ),
                  // شريط السعر
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${property['price']?.toString() ?? '0'} دج',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  // نوع المعاملة
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTransactionTypeColor(property['transactionType']).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getTransactionTypeText(property['transactionType']),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // تفاصيل العقار
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // العنوان
                    Text(
                      property['title'] ?? 'عقار بدون عنوان',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // الموقع
                    Row(
                      children: [
                        Icon(
                          Iconsax.location,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${property['city'] ?? ''}, ${property['wilaya'] ?? ''}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // نوع العقار
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getPropertyTypeText(property['propertyType']),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء صورة بديلة عندما لا تتوفر صورة
  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Center(
        child: Icon(
          Iconsax.home,
          size: 32,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// الحصول على لون نوع المعاملة
  Color _getTransactionTypeColor(String? transactionType) {
    switch (transactionType?.toLowerCase()) {
      case 'sale':
      case 'للبيع':
        return Colors.green;
      case 'rent':
      case 'للإيجار':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// الحصول على نص نوع المعاملة بالعربية
  String _getTransactionTypeText(String? transactionType) {
    switch (transactionType?.toLowerCase()) {
      case 'sale':
      case 'للبيع':
        return 'للبيع';
      case 'rent':
      case 'للإيجار':
        return 'للإيجار';
      default:
        return 'غير محدد';
    }
  }

  /// الحصول على نص نوع العقار بالعربية
  String _getPropertyTypeText(String? propertyType) {
    switch (propertyType?.toLowerCase()) {
      case 'apartment':
      case 'شقة':
        return 'شقة';
      case 'house':
      case 'منزل':
        return 'منزل';
      case 'villa':
      case 'فيلا':
        return 'فيلا';
      default:
        return propertyType ?? 'غير محدد';
    }
  }
}
