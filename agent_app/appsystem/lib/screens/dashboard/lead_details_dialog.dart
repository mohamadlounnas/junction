import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:appsystem/theme.dart';
import 'package:appsystem/screens/dashboard/leads_page.dart';

/// A beautiful full-screen animated dialog for displaying lead details.
///
/// This dialog provides:
/// - Smooth slide-up animation from bottom
/// - Comprehensive lead information display
/// - Interactive action buttons
/// - Beautiful visual design with gradients
/// - AI-powered insights and recommendations
class LeadDetailsDialog extends StatefulWidget {
  final Lead lead;
  final VoidCallback onClose;

  const LeadDetailsDialog({
    super.key,
    required this.lead,
    required this.onClose,
  });

  @override
  State<LeadDetailsDialog> createState() => _LeadDetailsDialogState();
}

class _LeadDetailsDialogState extends State<LeadDetailsDialog>
    with TickerProviderStateMixin {
  /// Animation controllers for smooth transitions
  late AnimationController _slideController;
  late AnimationController _contentController;
  late AnimationController _actionController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _actionScaleAnimation;

  /// Current tab index
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _contentController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  /// Initialize animation controllers and animations
  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _actionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeInOut),
    );

    _actionScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _actionController, curve: Curves.elasticOut),
    );

    // Start animations
    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _contentController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _actionController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildContent()),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the header section
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _closeDialog,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تفاصيل العميل',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.lead.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          _buildUrgencyIndicator(),
        ],
      ),
    );
  }

  /// Builds the urgency indicator
  Widget _buildUrgencyIndicator() {
    final colors = {
      LeadUrgency.hot: Colors.red,
      LeadUrgency.warm: Colors.orange,
      LeadUrgency.cold: Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors[widget.lead.urgency]!.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors[widget.lead.urgency]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.flash, color: colors[widget.lead.urgency]!, size: 16),
          const SizedBox(width: 4),
          Text(
            _getUrgencyText(widget.lead.urgency),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors[widget.lead.urgency]!,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the main content area
  Widget _buildContent() {
    return FadeTransition(
      opacity: _contentFadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildLeadCard(),
            const SizedBox(height: 24),
            _buildTabs(),
            const SizedBox(height: 16),
            _buildTabContent(),
            const SizedBox(height: 24),
            _buildAIInsights(),
          ],
        ),
      ),
    );
  }

  /// Builds the lead information card
  Widget _buildLeadCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildLeadAvatar(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lead.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.lead.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Iconsax.call,
                          color: Theme.of(context).primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.lead.phone,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildAIScore(),
            ],
          ),
          const SizedBox(height: 20),
          _buildLeadDetails(),
        ],
      ),
    );
  }

  /// Builds the lead avatar
  Widget _buildLeadAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.lead.name.split(' ').first[0],
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Builds the AI score indicator
  Widget _buildAIScore() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '${widget.lead.aiScore.toInt()}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'AI Score',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the lead details grid
  Widget _buildLeadDetails() {
    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            Iconsax.money,
            'الميزانية',
            '${widget.lead.budget} ${widget.lead.currency}',
            Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDetailItem(
            Iconsax.location,
            'الموقع المفضل',
            widget.lead.preferredLocation,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDetailItem(
            Iconsax.building,
            'نوع العقار',
            _getPropertyTypeText(widget.lead.propertyType),
            Colors.orange,
          ),
        ),
      ],
    );
  }

  /// Builds a detail item
  Widget _buildDetailItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the tabs
  Widget _buildTabs() {
    final tabs = ['المعلومات', 'الاهتمامات', 'التفاعل'];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isActive = _currentTabIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentTabIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isActive
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onPrimary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Builds the tab content
  Widget _buildTabContent() {
    switch (_currentTabIndex) {
      case 0:
        return _buildInfoTab();
      case 1:
        return _buildInterestsTab();
      case 2:
        return _buildInteractionTab();
      default:
        return const SizedBox.shrink();
    }
  }

  /// Builds the information tab
  Widget _buildInfoTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('آخر تواصل', _formatDate(widget.lead.lastContact)),
          _buildInfoRow('الحالة', _getStatusText(widget.lead.status)),
          _buildInfoRow(
            'الميزانية',
            '${widget.lead.budget} ${widget.lead.currency}',
          ),
          _buildInfoRow('الموقع المفضل', widget.lead.preferredLocation),
          _buildInfoRow(
            'نوع العقار',
            _getPropertyTypeText(widget.lead.propertyType),
          ),
          const SizedBox(height: 16),
          Text(
            'ملاحظات',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            widget.lead.notes,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// Builds the interests tab
  Widget _buildInterestsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الاهتمامات',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.lead.interests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).primaryColor),
                ),
                child: Text(
                  interest,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Builds the interaction tab
  Widget _buildInteractionTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'سجل التفاعل',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildInteractionItem(
            'تم إنشاء العميل',
            'تم إضافة العميل إلى النظام',
            DateTime.now().subtract(const Duration(days: 2)),
            Iconsax.user_add,
            Colors.green,
          ),
          _buildInteractionItem(
            'تم الاتصال',
            'تم التواصل مع العميل عبر الهاتف',
            DateTime.now().subtract(const Duration(hours: 6)),
            Iconsax.call,
            Colors.blue,
          ),
          _buildInteractionItem(
            'تم إرسال العرض',
            'تم إرسال عرض العقار المطلوب',
            DateTime.now().subtract(const Duration(hours: 2)),
            Iconsax.send,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  /// Builds an interaction item
  Widget _buildInteractionItem(
    String title,
    String description,
    DateTime date,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(date),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds AI insights section
  Widget _buildAIInsights() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.cpu,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'رؤى الذكاء الاصطناعي',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'احتمالية الشراء',
            '${widget.lead.aiScore}%',
            'عالية جداً',
            Colors.green,
          ),
          _buildInsightItem(
            'الوقت المفضل للتواصل',
            'صباحاً',
            '9:00 - 11:00',
            Colors.blue,
          ),
          _buildInsightItem(
            'العقارات الموصى بها',
            '3 عقارات',
            'مطابقة للمعايير',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  /// Builds an insight item
  Widget _buildInsightItem(
    String label,
    String value,
    String description,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the action buttons
  Widget _buildActions() {
    return ScaleTransition(
      scale: _actionScaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _contactLead,
                icon: const Icon(Iconsax.call),
                label: const Text('اتصال'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _scheduleMeeting,
                icon: const Icon(Iconsax.calendar),
                label: const Text('موعد'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _sendOffer,
                icon: const Icon(Iconsax.send),
                label: const Text('عرض'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Closes the dialog
  void _closeDialog() {
    _slideController.reverse().then((_) {
      widget.onClose();
    });
  }

  /// Contact lead action
  void _contactLead() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جاري الاتصال بـ ${widget.lead.name}'),
        backgroundColor: Theme.of(context).primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Schedule meeting action
  void _scheduleMeeting() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جدولة موعد مع ${widget.lead.name}'),
        backgroundColor: Theme.of(context).primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Send offer action
  void _sendOffer() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('إرسال عرض إلى ${widget.lead.name}'),
        backgroundColor: Theme.of(context).primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Builds an info row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Gets urgency text
  String _getUrgencyText(LeadUrgency urgency) {
    switch (urgency) {
      case LeadUrgency.hot:
        return 'ساخن';
      case LeadUrgency.warm:
        return 'دافئ';
      case LeadUrgency.cold:
        return 'بارد';
    }
  }

  /// Gets property type text
  String _getPropertyTypeText(PropertyType type) {
    switch (type) {
      case PropertyType.apartment:
        return 'شقة';
      case PropertyType.villa:
        return 'فيلا';
      case PropertyType.office:
        return 'مكتب';
    }
  }

  /// Gets status text
  String _getStatusText(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return 'عميل جديد';
      case LeadStatus.contacted:
        return 'تم التواصل';
      case LeadStatus.interested:
        return 'مهتم';
      case LeadStatus.qualified:
        return 'مؤهل';
      case LeadStatus.closed:
        return 'مغلق';
    }
  }

  /// Formats date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}
