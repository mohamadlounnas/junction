import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../services/contacts_service.dart';
import '../../widgets/enhanced_recommendation_cards.dart';

/// صفحة تفاصيل العميل
/// تعرض معلومات العميل مع التوصيات للعقارات المناسبة
/// الميزات:
/// - عرض شامل لتفاصيل العميل
/// - توصيات ذكية للعقارات باستخدام الذكاء الاصطناعي
/// - معلومات الميزانية والتفضيلات
/// - تقييم المطابقة مع العقارات
class ContactDetailsPage extends StatefulWidget {
  final String contactId;

  const ContactDetailsPage({
    super.key,
    required this.contactId,
  });

  @override
  State<ContactDetailsPage> createState() => _ContactDetailsPageState();
}

class _ContactDetailsPageState extends State<ContactDetailsPage>
    with TickerProviderStateMixin {
  Contact? _contact;
  List<PropertyRecommendation> _propertyRecommendations = [];
  bool _isLoading = true;
  bool _isLoadingRecommendations = true;
  String _error = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContactDetails();
    _loadPropertyRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// تحميل تفاصيل العميل
  Future<void> _loadContactDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final result = await ContactsService().getContact(widget.contactId);

      if (result['success'] == true) {
        setState(() {
          _contact = result['data'] as Contact;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'فشل في تحميل تفاصيل العميل';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ في تحميل تفاصيل العميل';
        _isLoading = false;
      });
    }
  }

  /// تحميل توصيات العقارات للعميل
  Future<void> _loadPropertyRecommendations() async {
    try {
      setState(() {
        _isLoadingRecommendations = true;
      });

      final result = await ContactsService().getContactRecommendations(
        widget.contactId,
        limit: 20,
        minSimilarity: 0.3,
      );

      if (result['success'] == true) {
        setState(() {
          _propertyRecommendations = (result['data'] as List<PropertyRecommendation>?) ?? [];
          _isLoadingRecommendations = false;
        });
        
        // Log metadata for debugging
        final metadata = result['metadata'] as Map<String, dynamic>?;
        final filters = result['filters'] as Map<String, dynamic>?;
        final total = result['total'] as int?;
        
        print('Contact recommendations loaded:');
        print('- Total recommendations: $total');
        print('- Metadata: $metadata');
        print('- Filters: $filters');
      } else {
        setState(() {
          _propertyRecommendations = [];
          _isLoadingRecommendations = false;
        });
        print('Failed to load recommendations: ${result['message']}');
      }
    } catch (e) {
      setState(() {
        _propertyRecommendations = [];
        _isLoadingRecommendations = false;
      });
      print('Error loading recommendations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل تفاصيل العميل...'),
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
                          onPressed: _loadContactDetails,
                          icon: const Icon(Iconsax.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : isDesktop 
                  ? _buildDesktopLayout()
                  : _buildContactDetails(),
    );
  }

  /// Desktop layout with recommendations sidebar
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Main content
        Expanded(
          flex: 2,
          child: _buildContactDetails(),
        ),
        
        // Recommendations sidebar
        Expanded(
          flex: 1,
          child: _buildRecommendationsSidebar(),
        ),
      ],
    );
  }

  /// Recommendations sidebar for desktop
  Widget _buildRecommendationsSidebar() {
    return Container(
      margin: const EdgeInsets.all(16),
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
          // Header
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
                    'التوصيات الذكية',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_propertyRecommendations.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_propertyRecommendations.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoadingRecommendations
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جاري تحميل التوصيات...'),
                      ],
                    ),
                  )
                : _propertyRecommendations.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.psychology_outlined,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد توصيات',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'سيتم إنشاء توصيات ذكية بناءً على تفضيلات العميل',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _propertyRecommendations.length,
                        itemBuilder: (context, index) {
                          final recommendation = _propertyRecommendations[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: EnhancedPropertyRecommendationCard(
                              recommendation: recommendation,
                              onTap: () {
                                context.go('/dashboard/property/${recommendation.property['id']}');
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// بناء تفاصيل العميل
  Widget _buildContactDetails() {
    if (_contact == null) return const SizedBox.shrink();

    return CustomScrollView(
      slivers: [
        // شريط التطبيق مع معلومات العميل
        _buildContactAppBar(),
        
        // محتوى العميل
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات العميل الأساسية
              _buildBasicInfo(),
              
              // التبويبات
              _buildTabSection(),
            ],
          ),
        ),
      ],
    );
  }

  /// بناء شريط التطبيق مع معلومات العميل
  Widget _buildContactAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
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
            // TODO: تعديل العميل
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.edit,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      _contact!.name.isNotEmpty
                          ? _contact!.name[0].toUpperCase()
                          : 'ع',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _contact!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    _contact!.typeDisplayName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// بناء المعلومات الأساسية للعميل
  Widget _buildBasicInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // معلومات الاتصال
          _buildContactInfo(),
          
          const SizedBox(height: 24),
          
          // معلومات الميزانية والمعاملة
          _buildBudgetAndTransactionInfo(),
          
          const SizedBox(height: 24),
          
          // التفضيلات
          _buildPreferencesInfo(),
        ],
      ),
    );
  }

  /// بناء معلومات الاتصال
  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلومات الاتصال',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard([
          _buildInfoRow(
            icon: Iconsax.sms,
            label: 'البريد الإلكتروني',
            value: _contact!.email,
          ),
          if (_contact!.phone != null)
            _buildInfoRow(
              icon: Iconsax.call,
              label: 'رقم الهاتف',
              value: _contact!.phone!,
            ),
          _buildInfoRow(
            icon: Iconsax.calendar,
            label: 'تاريخ التسجيل',
            value: _formatDate(_contact!.createdAt),
          ),
        ]),
      ],
    );
  }

  /// بناء معلومات الميزانية والمعاملة
  Widget _buildBudgetAndTransactionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الميزانية والمعاملة',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard([
          _buildInfoRow(
            icon: Iconsax.moneys,
            label: 'الميزانية',
            value: _contact!.formattedBudget,
          ),
          _buildInfoRow(
            icon: Iconsax.receipt,
            label: 'نوع المعاملة',
            value: _contact!.transactionTypeDisplayName,
          ),
          if (_contact!.transactionFlexibility != null)
            _buildInfoRow(
              icon: Iconsax.refresh,
              label: 'المرونة',
              value: _contact!.transactionFlexibilityText,
              valueColor: _contact!.transactionFlexibilityColor,
            ),
        ]),
      ],
    );
  }

  /// بناء معلومات التفضيلات
  Widget _buildPreferencesInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التفضيلات',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard([
          _buildInfoRow(
            icon: Iconsax.location,
            label: 'المناطق المفضلة',
            value: _contact!.locationDisplayText,
          ),
          _buildInfoRow(
            icon: Iconsax.home_2,
            label: 'أنواع العقارات',
            value: _contact!.propertyTypesDisplayText,
          ),
          if (_contact!.familySize != null)
            _buildInfoRow(
              icon: Iconsax.profile_2user,
              label: 'حجم العائلة',
              value: '${_contact!.familySize} أشخاص',
            ),
          _buildInfoRow(
            icon: Iconsax.profile_2user,
            label: 'الأطفال',
            value: _contact!.hasChildren ? 'نعم' : 'لا',
          ),
          if (_contact!.minRooms != null || _contact!.maxRooms != null)
            _buildInfoRow(
              icon: Iconsax.home_2,
              label: 'عدد الغرف',
              value: _getRoomsText(),
            ),
          if (_contact!.minArea != null || _contact!.maxArea != null)
            _buildInfoRow(
              icon: Iconsax.ruler,
              label: 'المساحة',
              value: _getAreaText(),
            ),
        ]),
      ],
    );
  }

  /// بناء قسم التبويبات
  Widget _buildTabSection() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
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
              Tab(text: 'التفاصيل'),
              Tab(text: 'العقارات المناسبة'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDetailsTab(),
              _buildPropertyRecommendationsTab(),
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
          // المتطلبات الإضافية
          _buildAdditionalRequirements(),
          
          const SizedBox(height: 24),
          
          // معلومات إضافية
          _buildAdditionalInfo(),
        ],
      ),
    );
  }

  /// بناء المتطلبات الإضافية
  Widget _buildAdditionalRequirements() {
    final requirements = [
      if (_contact!.requiresParking) {'icon': Iconsax.car, 'label': 'موقف سيارة'},
      if (_contact!.requiresSecurity) {'icon': Iconsax.security_safe, 'label': 'أمان'},
    ];

    if (requirements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المتطلبات الإضافية',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: requirements.map((requirement) {
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
                    requirement['icon'] as IconData,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    requirement['label'] as String,
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
          if (_contact!.furnishingType != null)
            _buildInfoRow(
              icon: Iconsax.home_2,
              label: 'نوع الأثاث',
              value: _getFurnishingTypeText(_contact!.furnishingType!),
            ),
          if (_contact!.preferredCondition != null)
            _buildInfoRow(
              icon: Iconsax.status,
              label: 'الحالة المفضلة',
              value: _getConditionText(_contact!.preferredCondition!),
            ),
          if (_contact!.notes != null && _contact!.notes!.isNotEmpty)
            _buildInfoRow(
              icon: Iconsax.note,
              label: 'ملاحظات',
              value: _contact!.notes!,
            ),
        ]),
      ],
    );
  }

  /// بناء تبويب توصيات العقارات
  Widget _buildPropertyRecommendationsTab() {
    if (_isLoadingRecommendations) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل توصيات العقارات...'),
          ],
        ),
      );
    }

    if (_propertyRecommendations.isEmpty) {
      return Center(
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
                'لا توجد توصيات عقارات',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'لم يتم العثور على عقارات مطابقة لتفضيلات هذا العميل حالياً',
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
      itemCount: _propertyRecommendations.length,
      itemBuilder: (context, index) {
        final recommendation = _propertyRecommendations[index];
        return _buildPropertyRecommendationCard(recommendation);
      },
    );
  }

  /// بناء بطاقة توصية عقار محسنة
  Widget _buildPropertyRecommendationCard(PropertyRecommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: EnhancedPropertyRecommendationCard(
        recommendation: recommendation,
        onTap: () {
          context.go('/dashboard/property/${recommendation.property['id']}');
        },
      ),
    );
  }

  /// بناء عنصر معلومات العقار
  Widget _buildPropertyInfoItem({
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

  /// بناء بطاقة المعلومات
  Widget _buildInfoCard(List<Widget> children) {
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
        children: children,
      ),
    );
  }

  /// بناء صف معلومات
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
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
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// الحصول على نص الغرف
  String _getRoomsText() {
    if (_contact!.minRooms != null && _contact!.maxRooms != null) {
      return '${_contact!.minRooms} - ${_contact!.maxRooms} غرف';
    } else if (_contact!.minRooms != null) {
      return 'من ${_contact!.minRooms} غرف';
    } else if (_contact!.maxRooms != null) {
      return 'حتى ${_contact!.maxRooms} غرف';
    }
    return 'غير محدد';
  }

  /// الحصول على نص المساحة
  String _getAreaText() {
    if (_contact!.minArea != null && _contact!.maxArea != null) {
      return '${_contact!.minArea} - ${_contact!.maxArea} م²';
    } else if (_contact!.minArea != null) {
      return 'من ${_contact!.minArea} م²';
    } else if (_contact!.maxArea != null) {
      return 'حتى ${_contact!.maxArea} م²';
    }
    return 'غير محدد';
  }

  /// الحصول على نص نوع الأثاث
  String _getFurnishingTypeText(String type) {
    switch (type) {
      case 'FURNISHED':
        return 'مؤثث';
      case 'SEMI_FURNISHED':
        return 'نصف مؤثث';
      case 'UNFURNISHED':
        return 'غير مؤثث';
      default:
        return type;
    }
  }

  /// الحصول على نص الحالة
  String _getConditionText(String condition) {
    switch (condition) {
      case 'NEW':
        return 'جديد';
      case 'EXCELLENT':
        return 'ممتاز';
      case 'GOOD':
        return 'جيد';
      case 'FAIR':
        return 'مقبول';
      case 'POOR':
        return 'سيء';
      default:
        return condition;
    }
  }
} 