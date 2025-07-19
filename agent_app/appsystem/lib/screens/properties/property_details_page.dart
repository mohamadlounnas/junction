import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../services/property_service.dart';

/// صفحة تفاصيل العقار
/// تعرض معلومات العقار مع التوصيات للعملاء المحتملين
/// الميزات:
/// - عرض شامل لتفاصيل العقار
/// - توصيات ذكية للعملاء باستخدام الذكاء الاصطناعي
/// - معرض الصور
/// - معلومات الاتصال والموقع
/// - تقييم المطابقة مع العملاء
class PropertyDetailsPage extends StatefulWidget {
  final String propertyId;

  const PropertyDetailsPage({
    super.key,
    required this.propertyId,
  });

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage>
    with TickerProviderStateMixin {
  Property? _property;
  List<ContactRecommendation> _contactRecommendations = [];
  bool _isLoading = true;
  bool _isLoadingRecommendations = true;
  String _error = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPropertyDetails();
    _loadContactRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// تحميل تفاصيل العقار
  Future<void> _loadPropertyDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final result = await PropertyService().getProperty(widget.propertyId);

      if (result['success'] == true) {
        setState(() {
          _property = Property.fromJson(result['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'فشل في تحميل تفاصيل العقار';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ في تحميل تفاصيل العقار';
        _isLoading = false;
      });
    }
  }

  /// تحميل توصيات العملاء للعقار
  Future<void> _loadContactRecommendations() async {
    try {
      setState(() {
        _isLoadingRecommendations = true;
      });

      final result = await PropertyService().getPropertyRecommendations(widget.propertyId);

      if (result['success'] == true) {
        setState(() {
          _contactRecommendations = (result['data'] as List<ContactRecommendation>?) ?? [];
          _isLoadingRecommendations = false;
        });
        
        // Log metadata for debugging
        final metadata = result['metadata'] as Map<String, dynamic>?;
        final filters = result['filters'] as Map<String, dynamic>?;
        final total = result['total'] as int?;
        
        print('Property recommendations loaded:');
        print('- Total recommendations: $total');
        print('- Metadata: $metadata');
        print('- Filters: $filters');
      } else {
        setState(() {
          _contactRecommendations = [];
          _isLoadingRecommendations = false;
        });
        print('Failed to load recommendations: ${result['message']}');
      }
    } catch (e) {
      setState(() {
        _contactRecommendations = [];
        _isLoadingRecommendations = false;
      });
      print('Error loading recommendations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل تفاصيل العقار...'),
                ],
              ),
            )
          : _error.isNotEmpty
              ? Center(
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
                          onPressed: _loadPropertyDetails,
                          icon: const Icon(Iconsax.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildPropertyDetails(),
    );
  }

  /// بناء تفاصيل العقار
  Widget _buildPropertyDetails() {
    if (_property == null) return const SizedBox.shrink();

    return CustomScrollView(
      slivers: [
        // شريط التطبيق مع الصورة
        _buildPropertyAppBar(),
        
        // محتوى العقار
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات العقار الأساسية
              _buildBasicInfo(),
              
              // التبويبات
              _buildTabSection(),
            ],
          ),
        ),
      ],
    );
  }

  /// بناء شريط التطبيق مع صورة العقار
  Widget _buildPropertyAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Iconsax.arrow_right,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: مشاركة العقار
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.share,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // صورة العقار
            Image.network(
              _property!.mainImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Icon(
                    Iconsax.home,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
            // تدرج
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
            // شارة نوع المعاملة
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getTransactionTypeColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _property!.transactionTypeDisplayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء المعلومات الأساسية للعقار
  Widget _buildBasicInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان والسعر
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _property!.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Iconsax.location,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_property!.city}, ${_property!.wilaya}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _property!.formattedPrice,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // المواصفات السريعة
          _buildQuickSpecs(),

          const SizedBox(height: 24),

          // الوصف
          if (_property!.description != null && _property!.description!.isNotEmpty) ...[
            Text(
              'الوصف',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _property!.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  /// بناء المواصفات السريعة
  Widget _buildQuickSpecs() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildSpecItem(
                icon: Iconsax.home_2,
                label: 'المساحة',
                value: '${_property!.area.toStringAsFixed(0)} م²',
              ),
              const SizedBox(width: 24),
              _buildSpecItem(
                icon: Iconsax.profile_2user,
                label: 'الغرف',
                value: '${_property!.rooms}',
              ),
              const SizedBox(width: 24),
              _buildSpecItem(
                icon: Iconsax.buildings,
                label: 'النوع',
                value: _property!.propertyTypeDisplayName,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSpecItem(
                icon: Iconsax.status,
                label: 'الحالة',
                value: _property!.conditionDisplayName,
              ),
              const SizedBox(width: 24),
              _buildSpecItem(
                icon: Iconsax.car,
                label: 'موقف سيارة',
                value: _property!.hasParking ? 'متوفر' : 'غير متوفر',
              ),
              const SizedBox(width: 24),
              _buildSpecItem(
                icon: Iconsax.security_safe,
                label: 'أمان',
                value: _property!.hasSecurity ? 'متوفر' : 'غير متوفر',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء عنصر مواصفات
  Widget _buildSpecItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// بناء قسم التبويبات
  Widget _buildTabSection() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
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
              Tab(text: 'التفاصيل'),
              Tab(text: 'العملاء المهتمين'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 600, // ارتفاع ثابت للمحتوى
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDetailsTab(),
              _buildContactRecommendationsTab(),
            ],
          ),
        ),
      ],
    );
  }

  /// بناء تبويب التفاصيل
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // المرافق
          _buildFeaturesSection(),
          
          const SizedBox(height: 24),
          
          // معلومات إضافية
          _buildAdditionalInfo(),
        ],
      ),
    );
  }

  /// بناء قسم المرافق
  Widget _buildFeaturesSection() {
    final features = [
      if (_property!.hasParking) {'icon': Iconsax.car, 'label': 'موقف سيارة'},
      if (_property!.hasSecurity) {'icon': Iconsax.security_safe, 'label': 'أمان'},
      if (_property!.hasElevator) {'icon': Iconsax.arrow_up_3, 'label': 'مصعد'},
      if (_property!.hasGarden) {'icon': Iconsax.tree, 'label': 'حديقة'},
      if (_property!.hasBalcony) {'icon': Iconsax.home_trend_up, 'label': 'شرفة'},
      if (_property!.hasSwimmingPool) {'icon': Iconsax.drop, 'label': 'مسبح'},
    ];

    if (features.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المرافق المتوفرة',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: features.map((feature) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    feature['icon'] as IconData,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    feature['label'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// بناء المعلومات الإضافية
  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلومات إضافية',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard([
          if (_property!.bathrooms != null)
            _buildInfoRow(
              icon: Iconsax.home_wifi,
              label: 'الحمامات',
              value: '${_property!.bathrooms}',
            ),
          if (_property!.floor != null)
            _buildInfoRow(
              icon: Iconsax.level,
              label: 'الطابق',
              value: '${_property!.floor}',
            ),
          if (_property!.totalFloors != null)
            _buildInfoRow(
              icon: Iconsax.buildings,
              label: 'إجمالي الطوابق',
              value: '${_property!.totalFloors}',
            ),
          if (_property!.buildingAge != null)
            _buildInfoRow(
              icon: Iconsax.calendar,
              label: 'عمر البناء',
              value: '${_property!.buildingAge} سنة',
            ),
          _buildInfoRow(
            icon: Iconsax.status,
            label: 'الحالة',
            value: _property!.statusDisplayName,
          ),
        ]),
      ],
    );
  }

  /// بناء بطاقة المعلومات
  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  /// بناء صف معلومات
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء تبويب توصيات العملاء
  Widget _buildContactRecommendationsTab() {
    if (_isLoadingRecommendations) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل توصيات العملاء...'),
          ],
        ),
      );
    }

    if (_contactRecommendations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.people,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد توصيات عملاء',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'لم يتم العثور على عملاء مطابقين لهذا العقار حالياً',
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _contactRecommendations.length,
      itemBuilder: (context, index) {
        final recommendation = _contactRecommendations[index];
        return _buildContactRecommendationCard(recommendation);
      },
    );
  }

  /// بناء بطاقة توصية عميل
  Widget _buildContactRecommendationCard(ContactRecommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس البطاقة مع اسم العميل ونسبة المطابقة
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    recommendation.contact.name.isNotEmpty
                        ? recommendation.contact.name[0].toUpperCase()
                        : 'ع',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.contact.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        recommendation.contact.typeDisplayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: recommendation.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${recommendation.similarityPercentage}%',
                    style: TextStyle(
                      color: recommendation.statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // حالة المطابقة
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: recommendation.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                recommendation.matchStatus,
                style: TextStyle(
                  color: recommendation.statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // معلومات العميل
            Row(
              children: [
                Expanded(
                  child: _buildContactInfoItem(
                    icon: Iconsax.moneys,
                    label: 'الميزانية',
                    value: recommendation.contact.formattedBudget,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildContactInfoItem(
                    icon: Iconsax.location,
                    label: 'المناطق المفضلة',
                    value: recommendation.contact.locationWilayas.isNotEmpty
                        ? recommendation.contact.locationWilayas.first
                        : 'غير محدد',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // شرح المطابقة
            if (recommendation.explanation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'تفسير المطابقة:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                recommendation.explanation,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // أزرار الإجراءات
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: عرض تفاصيل العميل
                    },
                    icon: const Icon(Iconsax.user, size: 16),
                    label: const Text('عرض التفاصيل'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: الاتصال بالعميل
                    },
                    icon: const Icon(Iconsax.call, size: 16),
                    label: const Text('اتصال'),
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
    );
  }

  /// بناء عنصر معلومات العميل
  Widget _buildContactInfoItem({
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

  /// الحصول على لون نوع المعاملة
  Color _getTransactionTypeColor() {
    switch (_property?.transactionType) {
      case 'SALE':
        return Colors.green;
      case 'RENT':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
} 