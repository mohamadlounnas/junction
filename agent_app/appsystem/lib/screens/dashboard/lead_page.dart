import 'package:appsystem/services/leads_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

class LeadPage extends StatefulWidget {
  const LeadPage({super.key});

  @override
  State<LeadPage> createState() => _LeadPageState();
}

class _LeadPageState extends State<LeadPage> with TickerProviderStateMixin {
  bool _isLoading = false;
  ContactModel? _selectedContact;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Search and Filter variables
  final TextEditingController _searchController = TextEditingController();
  List<ContactModel> _filteredContacts = [];
  List<ContactModel> _allContacts = [];

  // Filter states
  String _selectedWilaya = 'الكل';
  String _selectedPropertyType = 'الكل';
  String _selectedTransactionType = 'الكل';
  String _selectedBudgetRange = 'الكل';
  String _selectedStatus = 'الكل';

  // Filter options
  List<String> _wilayas = ['الكل'];
  List<String> _propertyTypes = ['الكل'];
  List<String> _transactionTypes = ['الكل'];
  List<String> _budgetRanges = ['الكل'];
  List<String> _statuses = ['الكل', 'نشط', 'غير نشط'];

  @override
  void initState() {
    super.initState();
    _loadLeads();
    _initializeAnimations();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLeads() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final leadsServices = Provider.of<LeadsServices>(context, listen: false);
      await leadsServices.fetchContacts();

      // Initialize data after loading
      _allContacts = leadsServices.contacts;
      _filteredContacts = List.from(_allContacts);
      _initializeFilterOptions();
      _applyFilters();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading leads: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeFilterOptions() {
    // Extract unique values for filters
    final Set<String> wilayaSet = {'الكل'};
    final Set<String> propertyTypeSet = {'الكل'};
    final Set<String> transactionTypeSet = {'الكل'};
    final Set<String> budgetRangeSet = {'الكل'};

    for (final contact in _allContacts) {
      wilayaSet.addAll(contact.locationWilayas);
      propertyTypeSet.addAll(contact.propertyTypes);
      transactionTypeSet.add(contact.transactionType);

      // Create budget ranges
      final budget = contact.budgetMax;
      if (budget <= 50000) {
        budgetRangeSet.add('أقل من 50 ألف');
      } else if (budget <= 100000) {
        budgetRangeSet.add('50 ألف - 100 ألف');
      } else if (budget <= 200000) {
        budgetRangeSet.add('100 ألف - 200 ألف');
      } else if (budget <= 500000) {
        budgetRangeSet.add('200 ألف - 500 ألف');
      } else {
        budgetRangeSet.add('أكثر من 500 ألف');
      }
    }

    _wilayas = wilayaSet.toList()..sort();
    _propertyTypes = propertyTypeSet.toList()..sort();
    _transactionTypes = transactionTypeSet.toList()..sort();
    _budgetRanges = budgetRangeSet.toList()..sort();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    List<ContactModel> filtered = List.from(_allContacts);

    // Text search
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((contact) {
        return contact.name.toLowerCase().contains(searchTerm) ||
            contact.email.toLowerCase().contains(searchTerm) ||
            contact.phone.toLowerCase().contains(searchTerm) ||
            contact.type.toLowerCase().contains(searchTerm) ||
            contact.locationWilayas.any(
              (wilaya) => wilaya.toLowerCase().contains(searchTerm),
            ) ||
            contact.locationCities.any(
              (city) => city.toLowerCase().contains(searchTerm),
            ) ||
            contact.propertyTypes.any(
              (type) => type.toLowerCase().contains(searchTerm),
            );
      }).toList();
    }

    // Wilaya filter
    if (_selectedWilaya != 'الكل') {
      filtered = filtered
          .where((contact) => contact.locationWilayas.contains(_selectedWilaya))
          .toList();
    }

    // Property type filter
    if (_selectedPropertyType != 'الكل') {
      filtered = filtered
          .where(
            (contact) => contact.propertyTypes.contains(_selectedPropertyType),
          )
          .toList();
    }

    // Transaction type filter
    if (_selectedTransactionType != 'الكل') {
      filtered = filtered
          .where(
            (contact) => contact.transactionType == _selectedTransactionType,
          )
          .toList();
    }

    // Budget range filter
    if (_selectedBudgetRange != 'الكل') {
      filtered = filtered.where((contact) {
        final budget = contact.budgetMax;
        switch (_selectedBudgetRange) {
          case 'أقل من 50 ألف':
            return budget <= 50000;
          case '50 ألف - 100 ألف':
            return budget > 50000 && budget <= 100000;
          case '100 ألف - 200 ألف':
            return budget > 100000 && budget <= 200000;
          case '200 ألف - 500 ألف':
            return budget > 200000 && budget <= 500000;
          case 'أكثر من 500 ألف':
            return budget > 500000;
          default:
            return true;
        }
      }).toList();
    }

    // Status filter
    if (_selectedStatus != 'الكل') {
      filtered = filtered.where((contact) {
        if (_selectedStatus == 'نشط') {
          return contact.isActive;
        } else if (_selectedStatus == 'غير نشط') {
          return !contact.isActive;
        }
        return true;
      }).toList();
    }

    setState(() {
      _filteredContacts = filtered;
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedWilaya = 'الكل';
      _selectedPropertyType = 'الكل';
      _selectedTransactionType = 'الكل';
      _selectedBudgetRange = 'الكل';
      _selectedStatus = 'الكل';
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LeadsServices>(
      builder: (context, leadsServices, child) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_allContacts.isEmpty) {
          return _buildEmptyState();
        }

        return Stack(
          children: [
            Column(
              children: [
                _buildSearchAndFilters(),
                Expanded(child: _buildLeadsWrap(_filteredContacts)),
              ],
            ),
            if (_selectedContact != null)
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildAnimatedDetailWidget(_selectedContact!),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'البحث عن الزبائن...',
                prefixIcon: Icon(
                  Iconsax.search_normal,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchController.clear();
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

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('الولاية', _selectedWilaya, _wilayas, (value) {
                  setState(() {
                    _selectedWilaya = value;
                  });
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'نوع العقار',
                  _selectedPropertyType,
                  _propertyTypes,
                  (value) {
                    setState(() {
                      _selectedPropertyType = value;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'نوع المعاملة',
                  _selectedTransactionType,
                  _transactionTypes,
                  (value) {
                    setState(() {
                      _selectedTransactionType = value;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'الميزانية',
                  _selectedBudgetRange,
                  _budgetRanges,
                  (value) {
                    setState(() {
                      _selectedBudgetRange = value;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip('الحالة', _selectedStatus, _statuses, (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildResetButton(),
              ],
            ),
          ),

          // Results count
          if (_filteredContacts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تم العثور على ${_filteredContacts.length} زبون',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  if (_hasActiveFilters())
                    Text(
                      'تم تطبيق الفلاتر',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String selectedValue,
    List<String> options,
    Function(String) onChanged,
  ) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem<String>(
          value: option,
          child: Row(
            children: [
              Icon(
                selectedValue == option ? Iconsax.tick_circle : Iconsax.radio,
                size: 16,
                color: selectedValue == option
                    ? Theme.of(context).primaryColor
                    : Colors.grey[400],
              ),
              const SizedBox(width: 8),
              Text(option),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selectedValue != 'الكل'
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selectedValue != 'الكل'
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: 0.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $selectedValue',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selectedValue != 'الكل'
                    ? Theme.of(context).primaryColor
                    : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Iconsax.arrow_down_1,
              size: 12,
              color: selectedValue != 'الكل'
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    if (!_hasActiveFilters()) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _resetFilters,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.refresh, size: 12, color: Colors.red[600]),
            const SizedBox(width: 4),
            Text(
              'إعادة تعيين',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.red[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _searchController.text.isNotEmpty ||
        _selectedWilaya != 'الكل' ||
        _selectedPropertyType != 'الكل' ||
        _selectedTransactionType != 'الكل' ||
        _selectedBudgetRange != 'الكل' ||
        _selectedStatus != 'الكل';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.people, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لم يتم العثور على زبائن',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _hasActiveFilters()
                ? 'جرب تعديل الفلاتر أو مصطلحات البحث'
                : 'ستظهر زبائنك هنا بمجرد إضافتهم',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _hasActiveFilters() ? _resetFilters : _loadLeads,
            icon: Icon(_hasActiveFilters() ? Iconsax.refresh : Iconsax.refresh),
            label: Text(_hasActiveFilters() ? 'إعادة تعيين الفلاتر' : 'تحديث'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadsWrap(List<ContactModel> contacts) {
    if (contacts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadLeads,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: contacts.map((contact) => _buildLeadCard(contact)).toList(),
        ),
      ),
    );
  }

  Widget _buildLeadCard(ContactModel contact) {
    return GestureDetector(
      onTap: () => _showContactDetails(contact),
      child: Container(
        width: 180,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!, width: 0.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and type
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getTypeColor(contact.type),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        contact.name.isNotEmpty
                            ? contact.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                          contact.name.isNotEmpty
                              ? contact.name
                              : 'Unnamed Lead',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(contact.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            contact.type,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getTypeColor(contact.type),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Key information
              _buildCompactInfoRow(Iconsax.sms, contact.email, maxLines: 1),
              const SizedBox(height: 8),
              _buildCompactInfoRow(Iconsax.call, contact.phone, maxLines: 1),
              const SizedBox(height: 8),
              _buildCompactInfoRow(
                Iconsax.money,
                '${contact.budgetMin.toStringAsFixed(0)} - ${contact.budgetMax.toStringAsFixed(0)}',
                maxLines: 1,
              ),
              const SizedBox(height: 8),
              _buildCompactInfoRow(
                Iconsax.home,
                contact.propertyTypes.isNotEmpty
                    ? contact.propertyTypes.first
                    : 'No preference',
                maxLines: 1,
              ),

              const Spacer(),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(contact.createdAt),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: contact.isActive ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
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

  Widget _buildCompactInfoRow(IconData icon, String text, {int maxLines = 1}) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'INVESTOR':
      case 'مستثمر':
        return Colors.blue;
      case 'BUYER':
      case 'مشتري':
        return Colors.green;
      case 'SELLER':
      case 'بائع':
        return Colors.orange;
      case 'TENANT':
      case 'مستأجر':
        return Colors.purple;
      case 'LANDLORD':
      case 'مالك':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showContactDetails(ContactModel contact) {
    setState(() {
      _selectedContact = contact;
    });
    _animationController.forward();
  }

  void _hideContactDetails() {
    _animationController.reverse().then((_) {
      setState(() {
        _selectedContact = null;
      });
    });
  }

  Widget _buildAnimatedDetailWidget(ContactModel contact) {
    return Positioned(
      right: 0,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.2,
        height: MediaQuery.of(context).size.height * 0.85,
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.075,
          left: MediaQuery.of(context).size.width * 0.05,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getTypeColor(contact.type).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getTypeColor(contact.type),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        contact.name.isNotEmpty
                            ? contact.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name.isNotEmpty
                              ? contact.name
                              : 'Unnamed Lead',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          contact.type,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _hideContactDetails,
                    icon: const Icon(Iconsax.close_circle),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDetailSection('Contact Information', Iconsax.user, [
                      _buildDetailListTile(Iconsax.sms, 'Email', contact.email),
                      _buildDetailListTile(
                        Iconsax.call,
                        'Phone',
                        contact.phone,
                      ),
                    ]),
                    _buildDetailSection('Property Preferences', Iconsax.home, [
                      _buildDetailListTile(
                        Iconsax.money,
                        'Budget Range',
                        '${contact.budgetMin.toStringAsFixed(0)} - ${contact.budgetMax.toStringAsFixed(0)}',
                      ),
                      _buildDetailListTile(
                        Iconsax.building,
                        'Property Types',
                        contact.propertyTypes.join(', '),
                      ),
                      _buildDetailListTile(
                        Iconsax.arrow_swap_horizontal,
                        'Transaction Type',
                        contact.transactionType,
                      ),
                      _buildDetailListTile(
                        Iconsax.box,
                        'Furnishing',
                        contact.furnishingType,
                      ),
                      _buildDetailListTile(
                        Iconsax.star,
                        'Condition',
                        contact.preferredCondition,
                      ),
                    ]),
                    _buildDetailSection('Location', Iconsax.location, [
                      _buildDetailListTile(
                        Iconsax.map,
                        'Wilayas',
                        contact.locationWilayas.join(', '),
                      ),
                      _buildDetailListTile(
                        Iconsax.building,
                        'Cities',
                        contact.locationCities.join(', '),
                      ),
                    ]),
                    _buildDetailSection('Requirements', Iconsax.clipboard_text, [
                      _buildDetailListTile(
                        Iconsax.people,
                        'Family Size',
                        '${contact.familySize} members',
                      ),
                      _buildDetailListTile(
                        Iconsax.user_add,
                        'Has Children',
                        contact.hasChildren ? 'Yes' : 'No',
                      ),
                      _buildDetailListTile(
                        Iconsax.home_1,
                        'Room Range',
                        '${contact.minRooms} - ${contact.maxRooms}',
                      ),
                      _buildDetailListTile(
                        Iconsax.ruler,
                        'Area Range',
                        '${contact.minArea.toStringAsFixed(0)} - ${contact.maxArea.toStringAsFixed(0)} m²',
                      ),
                      _buildDetailListTile(
                        Iconsax.car,
                        'Parking Required',
                        contact.requiresParking ? 'Yes' : 'No',
                      ),
                      _buildDetailListTile(
                        Iconsax.shield_tick,
                        'Security Required',
                        contact.requiresSecurity ? 'Yes' : 'No',
                      ),
                    ]),
                    if (contact.notes.isNotEmpty)
                      _buildDetailSection('Notes', Iconsax.note, [
                        _buildDetailListTile(
                          Iconsax.document_text,
                          '',
                          contact.notes,
                        ),
                      ]),
                    _buildDetailSection(
                      'System Information',
                      Iconsax.info_circle,
                      [
                        _buildDetailListTile(
                          Iconsax.calendar,
                          'Created',
                          _formatDate(contact.createdAt),
                        ),
                        _buildDetailListTile(
                          Iconsax.timer,
                          'Updated',
                          _formatDate(contact.updatedAt),
                        ),
                        _buildDetailListTile(
                          Iconsax.status_up,
                          'Status',
                          contact.isActive ? 'Active' : 'Inactive',
                          valueColor: contact.isActive
                              ? Colors.green
                              : Colors.red,
                        ),
                        _buildDetailListTile(
                          Iconsax.chart,
                          'Transaction Flexibility',
                          '${(contact.transactionFlexibility * 100).toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDetailListTile(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    if (value.isEmpty) return const SizedBox.shrink();

    return ListTile(
      leading: Icon(icon, color: Colors.grey[600], size: 20),
      title: label.isNotEmpty
          ? Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: valueColor,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
