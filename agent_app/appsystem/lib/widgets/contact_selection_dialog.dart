import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../services/contacts_service.dart';

/// Contact Selection Dialog
///
/// A dialog that allows users to select a contact for PDF quote generation.
/// Features:
/// - Search and filter contacts
/// - Display contact information
/// - Loading states and error handling
/// - Responsive design
class ContactSelectionDialog extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;

  const ContactSelectionDialog({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
  });

  @override
  State<ContactSelectionDialog> createState() => _ContactSelectionDialogState();
}

class _ContactSelectionDialogState extends State<ContactSelectionDialog> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  String _error = '';
  String _searchQuery = '';
  Contact? _selectedContact;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load contacts from the service
  Future<void> _loadContacts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final result = await ContactsService().getContacts();

      if (result['success'] == true) {
        final contactsData = result['data'] as List<Contact>;
        setState(() {
          _contacts = contactsData;
          _filteredContacts = _contacts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'فشل في تحميل جهات الاتصال';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ في تحميل جهات الاتصال: $e';
        _isLoading = false;
      });
      print('Error loading contacts: $e');
    }
  }

  /// Filter contacts based on search query
  void _filterContacts() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        _filteredContacts = _contacts.where((contact) {
          return contact.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              contact.email.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              (contact.phone?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            _buildHeader(),

            const SizedBox(height: 16),

            // Search bar
            _buildSearchBar(),

            const SizedBox(height: 16),

            // Contacts list
            Expanded(child: _buildContactsList()),

            const SizedBox(height: 16),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// Build dialog header
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Iconsax.user, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختر جهة الاتصال',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'لإنشاء عرض سعر PDF',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Iconsax.close_circle),
        ),
      ],
    );
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _filterContacts();
        },
        decoration: InputDecoration(
          hintText: 'البحث في جهات الاتصال...',
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
                    _filterContacts();
                  },
                  icon: Icon(
                    Iconsax.close_circle,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  /// Build contacts list
  Widget _buildContactsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل جهات الاتصال...'),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.warning_2,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'خطأ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadContacts,
              icon: const Icon(Iconsax.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.user,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'لم يتم العثور على جهات اتصال'
                  : 'لا توجد جهات اتصال',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'جرب تعديل البحث'
                  : 'أضف جهات اتصال للبدء',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        final isSelected = _selectedContact?.id == contact.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedContact = contact;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Contact avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Iconsax.user,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Contact details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contact.email,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        if (contact.phone != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            contact.phone!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                contact.typeDisplayName,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                contact.transactionTypeDisplayName,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onTertiaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Selection indicator
                  if (isSelected)
                    Icon(
                      Iconsax.tick_circle,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build action buttons
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('إلغاء'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _selectedContact != null
                ? () => Navigator.of(context).pop(_selectedContact)
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('اختيار'),
          ),
        ),
      ],
    );
  }
}
