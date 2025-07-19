import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../services/contacts_service.dart';

/// صفحة العملاء
/// تعرض جميع العملاء مع إمكانيات البحث والتصفية المتقدمة
/// الميزات:
/// - تصفية متقدمة حسب النوع والمعاملة والميزانية
/// - بحث في الاسم والبريد الإلكتروني
/// - تصفية حسب المنطقة والمرونة
/// - عرض معلومات شاملة لكل عميل
/// - تصميم متجاوب مع دعم العربية
class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _error = '';
  String _searchQuery = '';
  
  // Filter states
  String _selectedType = 'الكل';
  String _selectedTransactionType = 'الكل';
  String _selectedWilaya = 'الكل';
  String _selectedFlexibility = 'الكل';
  bool? _hasChildren;
  bool _isActive = true;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalContacts = 0;
  bool _hasMorePages = true;
  
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ContactsService _contactsService = ContactsService();

  // Filter options
  final List<String> _typeOptions = ['الكل', 'مشتري', 'مستأجر', 'مستثمر'];
  final List<String> _transactionTypeOptions = ['الكل', 'بيع', 'إيجار'];
  final List<String> _wilayaOptions = [
    'الكل', 'الجزائر', 'وهران', 'قسنطينة', 'عنابة', 'سطيف', 'باتنة', 'بجاية',
    'بسكرة', 'تبسة', 'تلمسان', 'تيزي وزو', 'الجلفة', 'جيجل', 'سطيف', 'سعيدة',
    'سكيكدة', 'سيدي بلعباس', 'عنابة', 'قالمة', 'قسنطينة', 'المدية', 'مستغانم',
    'المسيلة', 'معسكر', 'ورقلة', 'وهران', 'البيض', 'إليزي', 'برج بوعريريج',
    'بومرداس', 'الطارف', 'تندوف', 'تيسمسيلت', 'الوادي', 'خنشلة', 'سوق أهراس',
    'تيبازة', 'ميلة', 'عين الدفلى', 'النعامة', 'غرداية', 'غليزان'
  ];
  final List<String> _flexibilityOptions = ['الكل', 'مرن جداً', 'مرن', 'متوسط', 'غير مرن'];

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _contactsService.dispose();
    super.dispose();
  }

  /// تحميل العملاء
  Future<void> _loadContacts({bool refresh = false}) async {
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
      final result = await _contactsService.getContacts(
        page: _currentPage,
        limit: 20,
        type: _getTypeFilter(),
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        wilaya: _selectedWilaya != 'الكل' ? _selectedWilaya : null,
        transactionType: _getTransactionTypeFilter(),
        budgetMin: _getBudgetMin(),
        budgetMax: _getBudgetMax(),
        hasChildren: _hasChildren,
        isActive: _isActive,
      );

      if (result['success'] == true) {
        final newContacts = result['data'] as List<Contact>;
        final pagination = result['pagination'] as Map<String, dynamic>;
        
        setState(() {
          if (refresh || _currentPage == 1) {
            _contacts = newContacts;
            _filteredContacts = newContacts;
          } else {
            _contacts.addAll(newContacts);
            _filteredContacts.addAll(newContacts);
          }
          
          _totalPages = pagination['pages'] ?? 1;
          _totalContacts = pagination['total'] ?? 0;
          _hasMorePages = _currentPage < _totalPages;
          _isLoading = false;
          _isRefreshing = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'فشل في تحميل العملاء';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ في تحميل العملاء';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  /// تحميل المزيد من العملاء
  Future<void> _loadMoreContacts() async {
    if (!_hasMorePages || _isLoading) return;
    
    setState(() {
      _currentPage++;
    });
    
    await _loadContacts();
  }

  /// معالجة التمرير للتحميل التلقائي
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreContacts();
    }
  }

  /// تطبيق التصفية
  void _applyFilters() {
    setState(() {
      _currentPage = 1;
      _hasMorePages = true;
    });
    _loadContacts(refresh: true);
  }

  /// الحصول على فلتر النوع
  String? _getTypeFilter() {
    switch (_selectedType) {
      case 'مشتري':
        return 'BUYER';
      case 'مستأجر':
        return 'TENANT';
      case 'مستثمر':
        return 'INVESTOR';
      default:
        return null;
    }
  }

  /// الحصول على فلتر نوع المعاملة
  String? _getTransactionTypeFilter() {
    switch (_selectedTransactionType) {
      case 'بيع':
        return 'SALE';
      case 'إيجار':
        return 'RENT';
      default:
        return null;
    }
  }

  /// الحصول على الحد الأدنى للميزانية
  double? _getBudgetMin() {
    // TODO: Implement budget range picker
    return null;
  }

  /// الحصول على الحد الأقصى للميزانية
  double? _getBudgetMax() {
    // TODO: Implement budget range picker
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => _loadContacts(refresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // شريط البحث والتصفية
            _buildSearchAndFilterSection(),
            
            // المحتوى
            _buildContentSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: إضافة عميل جديد
        },
        icon: const Icon(Iconsax.add),
        label: const Text('إضافة عميل'),
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onSubmitted: (_) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: 'البحث في العملاء...',
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
                            _applyFilters();
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
            
            // رقائق التصفية السريعة
            _buildQuickFilters(),
            
            const SizedBox(height: 16),
            
            // التصفية المتقدمة
            _buildAdvancedFilters(),
          ],
        ),
      ),
    );
  }

  /// بناء التصفية السريعة
  Widget _buildQuickFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تصفية سريعة',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              label: 'نشط',
              selected: _isActive,
              onSelected: (selected) {
                setState(() {
                  _isActive = selected;
                });
                _applyFilters();
              },
            ),
            _buildFilterChip(
              label: 'عائلة',
              selected: _hasChildren == true,
              onSelected: (selected) {
                setState(() {
                  _hasChildren = selected ? true : null;
                });
                _applyFilters();
              },
            ),
            _buildFilterChip(
              label: 'بدون أطفال',
              selected: _hasChildren == false,
              onSelected: (selected) {
                setState(() {
                  _hasChildren = selected ? false : null;
                });
                _applyFilters();
              },
            ),
          ],
        ),
      ],
    );
  }

  /// بناء التصفية المتقدمة
  Widget _buildAdvancedFilters() {
    return ExpansionTile(
      title: Text(
        'تصفية متقدمة',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      children: [
        const SizedBox(height: 16),
        
        // نوع العميل
        _buildDropdownFilter(
          label: 'نوع العميل',
          value: _selectedType,
          items: _typeOptions,
          onChanged: (value) {
            setState(() {
              _selectedType = value!;
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        // نوع المعاملة
        _buildDropdownFilter(
          label: 'نوع المعاملة',
          value: _selectedTransactionType,
          items: _transactionTypeOptions,
          onChanged: (value) {
            setState(() {
              _selectedTransactionType = value!;
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        // المنطقة
        _buildDropdownFilter(
          label: 'المنطقة',
          value: _selectedWilaya,
          items: _wilayaOptions,
          onChanged: (value) {
            setState(() {
              _selectedWilaya = value!;
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        // المرونة
        _buildDropdownFilter(
          label: 'المرونة',
          value: _selectedFlexibility,
          items: _flexibilityOptions,
          onChanged: (value) {
            setState(() {
              _selectedFlexibility = value!;
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
                    _selectedType = 'الكل';
                    _selectedTransactionType = 'الكل';
                    _selectedWilaya = 'الكل';
                    _selectedFlexibility = 'الكل';
                    _hasChildren = null;
                    _searchQuery = '';
                    _searchController.clear();
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
    );
  }

  /// بناء رقاقة التصفية
  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: selected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
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

  /// بناء قسم المحتوى
  Widget _buildContentSection() {
    if (_isLoading && _contacts.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري تحميل العملاء...'),
            ],
          ),
        ),
      );
    }

    if (_error.isNotEmpty && _contacts.isEmpty) {
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
                  onPressed: () => _loadContacts(refresh: true),
                  icon: const Icon(Iconsax.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_contacts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
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
                  'لا توجد عملاء',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لم يتم العثور على عملاء مطابقين للتصفية المحددة',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: إضافة عميل جديد
                  },
                  icon: const Icon(Iconsax.add),
                  label: const Text('إضافة عميل'),
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
            if (index >= _contacts.length) {
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
            
            final contact = _contacts[index];
            return _buildContactCard(contact);
          },
          childCount: _contacts.length + (_hasMorePages ? 1 : 0),
        ),
      ),
    );
  }

  /// بناء بطاقة العميل
  Widget _buildContactCard(Contact contact) {
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
          context.go('/dashboard/contact/${contact.id}');
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
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      contact.name.isNotEmpty
                          ? contact.name[0].toUpperCase()
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
                          contact.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          contact.email,
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
                      color: _getTypeColor(contact.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      contact.typeDisplayName,
                      style: TextStyle(
                        color: _getTypeColor(contact.type),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // معلومات الميزانية والمعاملة
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Iconsax.moneys,
                      label: 'الميزانية',
                      value: contact.formattedBudget,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Iconsax.receipt,
                      label: 'المعاملة',
                      value: contact.transactionTypeDisplayName,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // معلومات الموقع والعقارات
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Iconsax.location,
                      label: 'المناطق',
                      value: contact.locationDisplayText,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Iconsax.home_2,
                      label: 'أنواع العقارات',
                      value: contact.propertyTypesDisplayText,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // معلومات إضافية
              Row(
                children: [
                  if (contact.hasChildren)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.profile_2user,
                            size: 12,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'عائلة',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (contact.transactionFlexibility != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: contact.transactionFlexibilityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        contact.transactionFlexibilityText,
                        style: TextStyle(
                          color: contact.transactionFlexibilityColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    Iconsax.arrow_left,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء عنصر معلومات
  Widget _buildInfoItem({
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

  /// الحصول على لون النوع
  Color _getTypeColor(String type) {
    switch (type) {
      case 'BUYER':
        return Colors.blue;
      case 'TENANT':
        return Colors.green;
      case 'INVESTOR':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
} 