import 'package:flutter/material.dart';
import 'package:appsystem/theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool darkMode = true; // Default to dark mode for real estate app
  bool notifications = true;
  bool autoPost = false;
  bool analyticsTracking = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),
              const SizedBox(height: 32),

              // Profile Section
              _buildProfileSection(context),
              const SizedBox(height: 24),

              // Preferences Section
              _buildPreferencesSection(context),
              const SizedBox(height: 24),

              // Security Section
              _buildSecuritySection(context),
              const SizedBox(height: 24),

              // Support Section
              _buildSupportSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإعدادات',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 8),
        Text(
          'Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return _buildSection(context, 'الملف الشخصي', 'Profile', [
      _buildSettingsItem(
        context,
        'تعديل الملف الشخصي',
        'Edit Profile',
        Icons.person_outline,
        onTap: () {},
      ),
      _buildSettingsItem(
        context,
        'تغيير كلمة المرور',
        'Change Password',
        Icons.lock_outline,
        onTap: () {},
      ),
      _buildSettingsItem(
        context,
        'الاشتراكات والفوترة',
        'Billing & Subscription',
        Icons.payment_outlined,
        onTap: () {},
      ),
    ]);
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return _buildSection(context, 'التفضيلات', 'Preferences', [
      _buildSwitchItem(
        context,
        'الوضع المظلم',
        'Dark Mode',
        Icons.dark_mode_outlined,
        darkMode,
        (value) => setState(() => darkMode = value),
      ),
      _buildSwitchItem(
        context,
        'الإشعارات',
        'Push Notifications',
        Icons.notifications_outlined,
        notifications,
        (value) => setState(() => notifications = value),
      ),
      _buildSwitchItem(
        context,
        'النشر التلقائي',
        'Auto-posting',
        Icons.schedule_outlined,
        autoPost,
        (value) => setState(() => autoPost = value),
      ),
      _buildSwitchItem(
        context,
        'تتبع التحليلات',
        'Analytics Tracking',
        Icons.analytics_outlined,
        analyticsTracking,
        (value) => setState(() => analyticsTracking = value),
      ),
    ]);
  }

  Widget _buildSecuritySection(BuildContext context) {
    return _buildSection(context, 'الأمان والخصوصية', 'Security & Privacy', [
      _buildSettingsItem(
        context,
        'المصادقة الثنائية',
        'Two-Factor Authentication',
        Icons.security_outlined,
        onTap: () {},
      ),
      _buildSettingsItem(
        context,
        'إعدادات الخصوصية',
        'Privacy Settings',
        Icons.privacy_tip_outlined,
        onTap: () {},
      ),
      _buildSettingsItem(
        context,
        'تصدير البيانات',
        'Data Export',
        Icons.download_outlined,
        onTap: () {},
      ),
    ]);
  }

  Widget _buildSupportSection(BuildContext context) {
    return _buildSection(context, 'الدعم', 'Support', [
      _buildSettingsItem(
        context,
        'مركز المساعدة',
        'Help Center',
        Icons.help_outline,
        onTap: () {},
      ),
      _buildSettingsItem(
        context,
        'تواصل مع الدعم',
        'Contact Support',
        Icons.email_outlined,
        onTap: () {},
      ),
      _buildSettingsItem(
        context,
        'شروط الخدمة',
        'Terms of Service',
        Icons.description_outlined,
        onTap: () {},
      ),
      _buildSettingsItem(
        context,
        'سياسة الخصوصية',
        'Privacy Policy',
        Icons.policy_outlined,
        onTap: () {},
      ),
    ]);
  }

  Widget _buildSection(
    BuildContext context,
    String titleAr,
    String titleEn,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleAr,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          textAlign: TextAlign.right,
        ),
        Text(
          titleEn,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: children.map((child) {
              final index = children.indexOf(child);
              return Column(
                children: [
                  child,
                  if (index < children.length - 1)
                    Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.onPrimary,
                      indent: 20,
                      endIndent: 20,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String titleAr,
    String titleEn,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
      ),
      title: Text(
        titleAr,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      subtitle: Text(
        titleEn,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onPrimary,
        size: 20,
      ),
    );
  }

  Widget _buildSwitchItem(
    BuildContext context,
    String titleAr,
    String titleEn,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
      ),
      title: Text(
        titleAr,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      subtitle: Text(
        titleEn,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
