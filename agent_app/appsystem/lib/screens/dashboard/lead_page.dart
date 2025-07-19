import 'package:appsystem/services/leads_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'contacts_page.dart';

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
    return const ContactsPage();
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
