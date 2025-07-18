import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:appsystem/theme.dart';
import 'package:appsystem/screens/dashboard/lead_details_dialog.dart';

/// A comprehensive leads management screen with beautiful animations and potential client tracking.
///
/// This screen provides:
/// - Animated potential client cards with smooth transitions
/// - Hot leads identification with priority indicators
/// - Full-screen animated dialog for lead details
/// - AI-powered client matching (UI only, backend to be implemented)
/// - Interactive lead management with beautiful animations
class LeadsPage extends StatefulWidget {
  const LeadsPage({super.key});

  @override
  State<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage> with TickerProviderStateMixin {
  /// Animation controllers for smooth transitions
  late AnimationController _pageAnimationController;
  late AnimationController _dialogAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _pageFadeAnimation;
  late Animation<Offset> _pageSlideAnimation;
  late Animation<double> _dialogScaleAnimation;
  late Animation<double> _dialogFadeAnimation;
  late Animation<double> _cardScaleAnimation;

  /// Selected lead for detailed view
  Lead? _selectedLead;
  bool _showLeadDialog = false;
  bool _showHotLeads = false;

  /// Sample leads data
  final List<Lead> _leads = [
    Lead(
      id: '1',
      name: 'أحمد محمد علي',
      email: 'ahmed.mohamed@email.com',
      phone: '+971 50 123 4567',
      budget: '2,500,000',
      currency: 'درهم',
      preferredLocation: 'دبي مارينا',
      propertyType: PropertyType.villa,
      urgency: LeadUrgency.hot,
      lastContact: DateTime.now().subtract(const Duration(hours: 2)),
      interests: ['فيلا فاخرة', 'مسبح خاص', 'مطبخ مفتوح'],
      aiScore: 95,
      status: LeadStatus.newLead,
      notes: 'مهتم بفيلا فاخرة مع إطلالة على البحر',
    ),
    Lead(
      id: '2',
      name: 'سارة أحمد حسن',
      email: 'sara.ahmed@email.com',
      phone: '+971 55 987 6543',
      budget: '1,800,000',
      currency: 'درهم',
      preferredLocation: 'برج خليفة',
      propertyType: PropertyType.apartment,
      urgency: LeadUrgency.warm,
      lastContact: DateTime.now().subtract(const Duration(days: 1)),
      interests: ['شقة عصرية', 'إطلالة على المدينة', 'مرافق رياضية'],
      aiScore: 87,
      status: LeadStatus.contacted,
      notes: 'تبحث عن شقة استثمارية في منطقة مميزة',
    ),
    Lead(
      id: '3',
      name: 'محمد عبدالله سالم',
      email: 'mohamed.abdullah@email.com',
      phone: '+971 52 456 7890',
      budget: '3,200,000',
      currency: 'درهم',
      preferredLocation: 'وسط المدينة',
      propertyType: PropertyType.office,
      urgency: LeadUrgency.hot,
      lastContact: DateTime.now().subtract(const Duration(minutes: 30)),
      interests: ['مكتب تجاري', 'موقف سيارات', 'موقع استراتيجي'],
      aiScore: 92,
      status: LeadStatus.newLead,
      notes: 'يحتاج مكتب تجاري فوري للشركة الجديدة',
    ),
    Lead(
      id: '4',
      name: 'فاطمة خالد محمد',
      email: 'fatima.khalid@email.com',
      phone: '+971 54 321 0987',
      budget: '4,500,000',
      currency: 'درهم',
      preferredLocation: 'جميرا',
      propertyType: PropertyType.villa,
      urgency: LeadUrgency.cold,
      lastContact: DateTime.now().subtract(const Duration(days: 3)),
      interests: ['فيلا عائلية', 'حديقة خاصة', 'غرف ضيوف'],
      aiScore: 78,
      status: LeadStatus.interested,
      notes: 'تبحث عن فيلا عائلية كبيرة مع حديقة',
    ),
    Lead(
      id: '5',
      name: 'علي حسن راشد',
      email: 'ali.hassan@email.com',
      phone: '+971 56 789 0123',
      budget: '1,200,000',
      currency: 'درهم',
      preferredLocation: 'دبي هيلز',
      propertyType: PropertyType.apartment,
      urgency: LeadUrgency.warm,
      lastContact: DateTime.now().subtract(const Duration(hours: 6)),
      interests: ['شقة استثمارية', 'عائد جيد', 'موقع هادئ'],
      aiScore: 83,
      status: LeadStatus.contacted,
      notes: 'مهتم بالاستثمار العقاري للدخل الإيجاري',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    _dialogAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  /// Initialize animation controllers and animations
  void _initializeAnimations() {
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _dialogAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _pageSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _pageAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _dialogScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _dialogAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _dialogFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _dialogAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _cardScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    // Start page animation
    _pageAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _pageAnimationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _pageFadeAnimation,
              child: SlideTransition(
                position: _pageSlideAnimation,
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildStatsCards(),
                    _buildFilterTabs(),
                    Expanded(child: _buildLeadsList()),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Builds the header section
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.user_search,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'العملاء المحتملون',
                  style: AppTheme.getSafeTextTheme().titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'إدارة العملاء والفرص الساخنة',
                  style: AppTheme.getSafeTextTheme().bodyMedium?.copyWith(
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          _buildAIButton(),
        ],
      ),
    );
  }

  /// Builds the AI analysis button
  Widget _buildAIButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAIAnalysis,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.cpu, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  'تحليل AI',
                  style: AppTheme.getSafeTextTheme().bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the statistics cards
  Widget _buildStatsCards() {
    final hotLeads = _leads
        .where((lead) => lead.urgency == LeadUrgency.hot)
        .length;
    final totalLeads = _leads.length;
    final avgScore =
        _leads.fold(0.0, (sum, lead) => sum + lead.aiScore) / totalLeads;

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard(
            'العملاء الساخنون',
            hotLeads.toString(),
            Iconsax.flash,
            Colors.orange,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'إجمالي العملاء',
            totalLeads.toString(),
            Iconsax.people,
            AppTheme.primaryGreen,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'متوسط التقييم',
            '${avgScore.toStringAsFixed(1)}%',
            Iconsax.chart,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  /// Builds a single statistics card
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.getSafeTextTheme().titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTheme.getSafeTextTheme().bodySmall?.copyWith(
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the filter tabs
  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterTab(
              'جميع العملاء',
              !_showHotLeads,
              () => setState(() => _showHotLeads = false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFilterTab(
              'العملاء الساخنون',
              _showHotLeads,
              () => setState(() => _showHotLeads = true),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single filter tab
  Widget _buildFilterTab(String title, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryGreen : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppTheme.primaryGreen : AppTheme.borderColor,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: AppTheme.getSafeTextTheme().bodyMedium?.copyWith(
            color: isActive ? Colors.white : AppTheme.textGrey,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Builds the leads list
  Widget _buildLeadsList() {
    final filteredLeads = _showHotLeads
        ? _leads.where((lead) => lead.urgency == LeadUrgency.hot).toList()
        : _leads;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredLeads.length,
      itemBuilder: (context, index) {
        final lead = filteredLeads[index];
        return AnimatedBuilder(
          animation: _cardAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _cardScaleAnimation.value,
              child: _buildLeadCard(lead),
            );
          },
        );
      },
    );
  }

  /// Builds a single lead card
  Widget _buildLeadCard(Lead lead) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getUrgencyColor(lead.urgency).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLeadDetails(lead),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildLeadAvatar(lead),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead.name,
                            style: AppTheme.getSafeTextTheme().titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            lead.email,
                            style: AppTheme.getSafeTextTheme().bodySmall
                                ?.copyWith(color: AppTheme.textGrey),
                          ),
                        ],
                      ),
                    ),
                    _buildUrgencyBadge(lead.urgency),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildLeadInfo(
                      Iconsax.money,
                      '${lead.budget} ${lead.currency}',
                      AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 16),
                    _buildLeadInfo(
                      Iconsax.location,
                      lead.preferredLocation,
                      Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    _buildLeadInfo(
                      Iconsax.chart,
                      '${lead.aiScore}%',
                      Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInterestsChips(lead.interests),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the lead avatar
  Widget _buildLeadAvatar(Lead lead) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _getUrgencyColor(lead.urgency).withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: _getUrgencyColor(lead.urgency), width: 2),
      ),
      child: Center(
        child: Text(
          lead.name.split(' ').first[0],
          style: AppTheme.getSafeTextTheme().titleMedium?.copyWith(
            color: _getUrgencyColor(lead.urgency),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Builds the urgency badge
  Widget _buildUrgencyBadge(LeadUrgency urgency) {
    final colors = {
      LeadUrgency.hot: Colors.red,
      LeadUrgency.warm: Colors.orange,
      LeadUrgency.cold: Colors.grey,
    };

    final labels = {
      LeadUrgency.hot: 'ساخن',
      LeadUrgency.warm: 'دافئ',
      LeadUrgency.cold: 'بارد',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors[urgency]!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors[urgency]!),
      ),
      child: Text(
        labels[urgency]!,
        style: AppTheme.getSafeTextTheme().bodySmall?.copyWith(
          color: colors[urgency]!,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Builds lead information item
  Widget _buildLeadInfo(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTheme.getSafeTextTheme().bodySmall?.copyWith(
            color: AppTheme.textGrey,
          ),
        ),
      ],
    );
  }

  /// Builds interests chips
  Widget _buildInterestsChips(List<String> interests) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: interests.take(3).map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            interest,
            style: AppTheme.getSafeTextTheme().bodySmall?.copyWith(
              color: AppTheme.primaryGreen,
              fontSize: 10,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Builds the floating action button
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _addNewLead,
      backgroundColor: AppTheme.primaryGreen,
      icon: const Icon(Iconsax.add, color: Colors.white),
      label: Text(
        'إضافة عميل',
        style: AppTheme.getSafeTextTheme().bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Shows lead details dialog
  void _showLeadDetails(Lead lead) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LeadDetailsDialog(
        lead: lead,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Shows AI analysis dialog
  void _showAIAnalysis() {
    showDialog(
      context: context,
      builder: (context) => _buildAIAnalysisDialog(),
    );
  }

  /// Builds AI analysis dialog
  Widget _buildAIAnalysisDialog() {
    return Dialog(
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.cpu,
                color: AppTheme.primaryGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'تحليل الذكاء الاصطناعي',
              style: AppTheme.getSafeTextTheme().titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جاري تحليل العملاء المحتملين...',
              style: AppTheme.getSafeTextTheme().bodyMedium?.copyWith(
                color: AppTheme.textGrey,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppTheme.primaryGreen),
          ],
        ),
      ),
    );
  }

  /// Adds new lead
  void _addNewLead() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('إضافة عميل جديد'),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// Gets urgency color
  Color _getUrgencyColor(LeadUrgency urgency) {
    switch (urgency) {
      case LeadUrgency.hot:
        return Colors.red;
      case LeadUrgency.warm:
        return Colors.orange;
      case LeadUrgency.cold:
        return Colors.grey;
    }
  }
}

/// Lead data model
class Lead {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String budget;
  final String currency;
  final String preferredLocation;
  final PropertyType propertyType;
  final LeadUrgency urgency;
  final DateTime lastContact;
  final List<String> interests;
  final double aiScore;
  final LeadStatus status;
  final String notes;

  Lead({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.budget,
    required this.currency,
    required this.preferredLocation,
    required this.propertyType,
    required this.urgency,
    required this.lastContact,
    required this.interests,
    required this.aiScore,
    required this.status,
    required this.notes,
  });
}

/// Lead urgency enum
enum LeadUrgency { hot, warm, cold }

/// Lead status enum
enum LeadStatus { newLead, contacted, interested, qualified, closed }

/// Property types enum
enum PropertyType { apartment, villa, office }
