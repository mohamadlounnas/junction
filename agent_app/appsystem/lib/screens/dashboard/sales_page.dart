import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../services/sales_service.dart';

/// صفحة المبيعات
/// تعرض جميع المبيعات مع إمكانيات البحث والتصفية والتحليلات
/// الميزات:
/// - تصفية متقدمة حسب العميل والعقار والنجاح
/// - تحليلات شاملة للمبيعات
/// - إدارة المبيعات (إضافة، تعديل، حذف)
/// - عرض معلومات مفصلة لكل عملية بيع
/// - تصميم متجاوب مع دعم العربية
class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage>
    with TickerProviderStateMixin {
  List<Sale> _sales = [];
  List<Sale> _filteredSales = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _error = '';
  
  // Filter states
  String _selectedContactId = 'الكل';
  String _selectedPropertyId = 'الكل';
  String _selectedSuccessRange = 'الكل';

  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMorePages = true;
  
  // Analytics
  SalesAnalytics? _analytics;
  bool _isLoadingAnalytics = false;
  
  final ScrollController _scrollController = ScrollController();
  final SalesService _salesService = SalesService();
  late TabController _tabController;

  // Filter options
  final List<String> _successRangeOptions = [
    'الكل',
    'ممتاز (80%+)',
    'جيد (60-80%)',
    'مقبول (40-60%)',
    'ضعيف (أقل من 40%)'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSales();
    _loadAnalytics();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _salesService.dispose();
    super.dispose();
  }

  /// تحميل المبيعات
  Future<void> _loadSales({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isRefreshing = true;
        _currentPage = 1;
        _hasMorePages = true;
      });
    } else if (!_isRefreshing) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final result = await _salesService.getSales(
        page: _currentPage,
        limit: 20,
        contactId: _getContactIdFilter(),
        propertyId: _getPropertyIdFilter(),
        successScoreMin: _getSuccessScoreMin(),
        successScoreMax: _getSuccessScoreMax(),
      );

      if (result['success'] == true) {
        final newSales = result['data'] as List<Sale>;
        final pagination = result['pagination'] as Map<String, dynamic>;
        
        setState(() {
          if (refresh || _currentPage == 1) {
            _sales = newSales;
            _filteredSales = newSales;
          } else {
            _sales.addAll(newSales);
            _filteredSales.addAll(newSales);
          }
          
          _totalPages = pagination['pages'] ?? 1;
          _hasMorePages = _currentPage < _totalPages;
          _isLoading = false;
          _isRefreshing = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'فشل في تحميل المبيعات';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ في تحميل المبيعات';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  /// تحميل المزيد من المبيعات
  Future<void> _loadMoreSales() async {
    if (!_hasMorePages || _isLoading) return;
    
    setState(() {
      _currentPage++;
    });
    
    await _loadSales();
  }

  /// معالجة التمرير للتحميل التلقائي
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreSales();
    }
  }

  /// تحميل التحليلات
  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoadingAnalytics = true;
    });

    try {
      final result = await _salesService.getSalesAnalytics();

      if (result['success'] == true) {
        setState(() {
          _analytics = result['data'] as SalesAnalytics;
          _isLoadingAnalytics = false;
        });
      } else {
        setState(() {
          _isLoadingAnalytics = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingAnalytics = false;
      });
    }
  }

  /// تطبيق التصفية
  void _applyFilters() {
    setState(() {
      _currentPage = 1;
      _hasMorePages = true;
    });
    _loadSales(refresh: true);
  }

  /// الحصول على فلتر معرف العميل
  String? _getContactIdFilter() {
    return _selectedContactId != 'الكل' ? _selectedContactId : null;
  }

  /// الحصول على فلتر معرف العقار
  String? _getPropertyIdFilter() {
    return _selectedPropertyId != 'الكل' ? _selectedPropertyId : null;
  }

  /// الحصول على الحد الأدنى لدرجة النجاح
  double? _getSuccessScoreMin() {
    switch (_selectedSuccessRange) {
      case 'ممتاز (80%+)':
        return 0.8;
      case 'جيد (60-80%)':
        return 0.6;
      case 'مقبول (40-60%)':
        return 0.4;
      case 'ضعيف (أقل من 40%)':
        return 0.0;
      default:
        return null;
    }
  }

  /// الحصول على الحد الأقصى لدرجة النجاح
  double? _getSuccessScoreMax() {
    switch (_selectedSuccessRange) {
      case 'ممتاز (80%+)':
        return 1.0;
      case 'جيد (60-80%)':
        return 0.8;
      case 'مقبول (40-60%)':
        return 0.6;
      case 'ضعيف (أقل من 40%)':
        return 0.4;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // شريط التبويبات
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'المبيعات'),
                Tab(text: 'التحليلات'),
              ],
            ),
          ),
          
          // محتوى التبويبات
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSalesTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddSaleDialog();
        },
        icon: const Icon(Iconsax.add),
        label: const Text('إضافة مبيعات'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  /// بناء تبويب المبيعات
  Widget _buildSalesTab() {
    return RefreshIndicator(
      onRefresh: () => _loadSales(refresh: true),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // شريط التصفية
          _buildFilterSection(),
          
          // المحتوى
          _buildSalesContent(),
        ],
      ),
    );
  }

  /// بناء تبويب التحليلات
  Widget _buildAnalyticsTab() {
    if (_isLoadingAnalytics) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل التحليلات...'),
          ],
        ),
      );
    }

    if (_analytics == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.chart,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد تحليلات متاحة',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'قم بإضافة بعض المبيعات لرؤية التحليلات',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // نظرة عامة
          _buildOverviewCards(),
          
          const SizedBox(height: 24),
          
          // أفضل الأداء
          _buildPerformanceSection(),
          
          const SizedBox(height: 24),
          
          // الاتجاهات
          _buildTrendsSection(),
        ],
      ),
    );
  }

  /// بناء قسم التصفية
  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تصفية المبيعات',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            // تصفية درجة النجاح
            _buildDropdownFilter(
              label: 'درجة النجاح',
              value: _selectedSuccessRange,
              items: _successRangeOptions,
              onChanged: (value) {
                setState(() {
                  _selectedSuccessRange = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // أزرار التصفية
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('تطبيق التصفية'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedContactId = 'الكل';
                        _selectedPropertyId = 'الكل';
                        _selectedSuccessRange = 'الكل';
                      });
                      _applyFilters();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('إعادة تعيين'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// بناء محتوى المبيعات
  Widget _buildSalesContent() {
    if (_isLoading && _sales.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري تحميل المبيعات...'),
            ],
          ),
        ),
      );
    }

    if (_error.isNotEmpty && _sales.isEmpty) {
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
                  onPressed: () => _loadSales(refresh: true),
                  icon: const Icon(Iconsax.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_sales.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.receipt,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد مبيعات',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لم يتم العثور على مبيعات مطابقة للتصفية المحددة',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showAddSaleDialog(),
                  icon: const Icon(Iconsax.add),
                  label: const Text('إضافة مبيعات'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= _sales.length) {
              if (_hasMorePages && !_isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return null;
            }
            
            final sale = _sales[index];
            return _buildSaleCard(sale);
          },
          childCount: _sales.length + (_hasMorePages ? 1 : 0),
        ),
      ),
    );
  }

  /// بناء بطاقة المبيعات
  Widget _buildSaleCard(Sale sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          _showSaleDetailsDialog(sale);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس البطاقة
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: sale.successStatusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Iconsax.receipt,
                      color: sale.successStatusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.property?.title ?? 'عقار غير محدد',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          sale.contact?.name ?? 'عميل غير محدد',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: sale.successStatusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sale.successStatus,
                      style: TextStyle(
                        color: sale.successStatusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // معلومات المبيعات
              Row(
                children: [
                  Expanded(
                    child: _buildSaleInfoItem(
                      icon: Iconsax.moneys,
                      label: 'سعر البيع',
                      value: sale.formattedSalePrice,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSaleInfoItem(
                      icon: Iconsax.chart,
                      label: 'درجة النجاح',
                      value: '${(sale.successScore * 100).round()}%',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // معلومات إضافية
              Row(
                children: [
                  Expanded(
                    child: _buildSaleInfoItem(
                      icon: Iconsax.calendar,
                      label: 'تاريخ البيع',
                      value: sale.formattedSaleDate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSaleInfoItem(
                      icon: Iconsax.clock,
                      label: 'وقت القرار',
                      value: sale.timeToDecisionText,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // أزرار الإجراءات
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showSaleDetailsDialog(sale),
                      icon: const Icon(Iconsax.eye, size: 16),
                      label: const Text('التفاصيل'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showEditSaleDialog(sale),
                      icon: const Icon(Iconsax.edit, size: 16),
                      label: const Text('تعديل'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء عنصر معلومات المبيعات
  Widget _buildSaleInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// بناء بطاقات النظرة العامة
  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نظرة عامة',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                title: 'إجمالي المبيعات',
                value: _analytics!.totalSales.toString(),
                icon: Iconsax.receipt,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                title: 'متوسط النجاح',
                value: '${_analytics!.averageSuccessScorePercentage}%',
                icon: Iconsax.chart,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// بناء بطاقة النظرة العامة
  Widget _buildOverviewCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء قسم الأداء
  Widget _buildPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أفضل الأداء',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        // أفضل العملاء
        _buildPerformanceCard(
          title: 'أفضل العملاء',
          data: _analytics!.topPerformingContacts,
          itemBuilder: (item) => _buildPerformanceItem(
            title: item['contactName'] ?? 'غير محدد',
            subtitle: '${item['_count']['id']} مبيعات',
            value: '${((item['_avg']['successScore'] ?? 0) * 100).round()}%',
          ),
        ),
        
        const SizedBox(height: 16),
        
        // أفضل العقارات
        _buildPerformanceCard(
          title: 'أفضل العقارات',
          data: _analytics!.topPerformingProperties,
          itemBuilder: (item) => _buildPerformanceItem(
            title: item['propertyTitle'] ?? 'غير محدد',
            subtitle: '${item['_count']['id']} مبيعات',
            value: '${((item['_avg']['successScore'] ?? 0) * 100).round()}%',
          ),
        ),
      ],
    );
  }

  /// بناء بطاقة الأداء
  Widget _buildPerformanceCard({
    required String title,
    required List<Map<String, dynamic>> data,
    required Widget Function(Map<String, dynamic>) itemBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...data.take(5).map(itemBuilder),
        ],
      ),
    );
  }

  /// بناء عنصر الأداء
  Widget _buildPerformanceItem({
    required String title,
    required String subtitle,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء قسم الاتجاهات
  Widget _buildTrendsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اتجاهات المبيعات',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              ..._analytics!.salesByMonth.take(6).map((month) {
                final date = DateTime.parse(month['saleDate']);
                final count = month['_count']['id'] ?? 0;
                final avgScore = (month['_avg']['successScore'] ?? 0) * 100;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${date.month}/${date.year}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '$count مبيعات',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${avgScore.round()}% نجاح',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  /// بناء قائمة منسدلة للتصفية
  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
              isExpanded: true,
              icon: Icon(
                Iconsax.arrow_down_1,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// عرض مربع حوار إضافة مبيعات
  void _showAddSaleDialog() {
    // TODO: Implement add sale dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة هذه الميزة قريباً'),
      ),
    );
  }

  /// عرض مربع حوار تفاصيل المبيعات
  void _showSaleDetailsDialog(Sale sale) {
    // TODO: Implement sale details dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة هذه الميزة قريباً'),
      ),
    );
  }

  /// عرض مربع حوار تعديل المبيعات
  void _showEditSaleDialog(Sale sale) {
    // TODO: Implement edit sale dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة هذه الميزة قريباً'),
      ),
    );
  }
} 