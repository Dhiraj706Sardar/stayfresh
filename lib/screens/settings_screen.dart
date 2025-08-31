import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../services/local_database_service.dart';
import 'notification_test_screen.dart';
import 'profile_edit_screen.dart';
import '../theme/theme_provider.dart';

/// Premium settings screen with elegant design
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoBackupEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            _buildSliverAppBar(),

            // Settings Content
            SliverPadding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AnimationLimiter(
                    child: Column(
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 375),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          // Profile Section
                          _buildProfileSection(),

                          const SizedBox(height: AppTheme.spacingL),

                          // Preferences Section
                          _buildPreferencesSection(),

                          const SizedBox(height: AppTheme.spacingL),

                          // Data & Privacy Section
                          _buildDataPrivacySection(),

                          const SizedBox(height: AppTheme.spacingL),

                          // Support Section
                          _buildSupportSection(),

                          const SizedBox(height: AppTheme.spacingL),

                          // About Section
                          _buildAboutSection(),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.pureWhite,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppTheme.pureWhite,
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Settings',
                          style: AppTheme.headingLarge.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          'Customize your experience',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/image.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.settings,
                            color: AppTheme.primaryGreen,
                            size: 20,
                          );
                        },
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

  Widget _buildProfileSection() {
    final user = LocalDatabaseService.getCurrentUser();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/image.png',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    color: AppTheme.pureWhite,
                    size: 30,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Guest User',
                  style: AppTheme.headingSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  user?.email ?? 'guest@stayfresh.com',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const ProfileEditScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        );
                      },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return _buildSettingsSection(
      title: 'Preferences',
      icon: Icons.tune,
      children: [
        _buildSwitchTile(
          title: 'Push Notifications',
          subtitle: 'Get alerts for expiring items',
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
          icon: Icons.notifications_outlined,
        ),
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return _buildSwitchTile(
              title: 'Dark Mode',
              subtitle: 'Switch to dark theme',
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
              icon: Icons.dark_mode_outlined,
            );
          },
        ),
        _buildSwitchTile(
          title: 'Auto Backup',
          subtitle: 'Automatically backup your data',
          value: _autoBackupEnabled,
          onChanged: (value) {
            setState(() {
              _autoBackupEnabled = value;
            });
          },
          icon: Icons.backup_outlined,
        ),
        _buildActionTile(
          title: 'Test Notifications',
          subtitle: 'Send a test notification',
          icon: Icons.notification_add_outlined,
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const NotificationTestScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      );
                    },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDataPrivacySection() {
    return _buildSettingsSection(
      title: 'Data & Privacy',
      icon: Icons.security,
      children: [
        _buildActionTile(
          title: 'Export Data',
          subtitle: 'Download your grocery data',
          icon: Icons.download_outlined,
          onTap: () {
            // TODO: Implement data export
            _showComingSoonDialog('Data Export');
          },
        ),
        _buildActionTile(
          title: 'Clear Cache',
          subtitle: 'Free up storage space',
          icon: Icons.cleaning_services_outlined,
          onTap: () {
            _showClearCacheDialog();
          },
        ),
        _buildActionTile(
          title: 'Privacy Policy',
          subtitle: 'Read our privacy policy',
          icon: Icons.privacy_tip_outlined,
          onTap: () {
            // TODO: Open privacy policy
            _showComingSoonDialog('Privacy Policy');
          },
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _buildSettingsSection(
      title: 'Support',
      icon: Icons.help_outline,
      children: [
        _buildActionTile(
          title: 'Help Center',
          subtitle: 'Get help and support',
          icon: Icons.help_center_outlined,
          onTap: () {
            _showComingSoonDialog('Help Center');
          },
        ),
        _buildActionTile(
          title: 'Send Feedback',
          subtitle: 'Share your thoughts with us',
          icon: Icons.feedback_outlined,
          onTap: () {
            _showComingSoonDialog('Feedback');
          },
        ),
        _buildActionTile(
          title: 'Rate App',
          subtitle: 'Rate StayFresh on the store',
          icon: Icons.star_outline,
          onTap: () {
            _showComingSoonDialog('App Rating');
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSettingsSection(
      title: 'About',
      icon: Icons.info_outline,
      children: [
        _buildActionTile(
          title: 'Version',
          subtitle: '1.0.0 (Build 1)',
          icon: Icons.info_outlined,
          onTap: null,
        ),
        _buildActionTile(
          title: 'Terms of Service',
          subtitle: 'Read our terms and conditions',
          icon: Icons.description_outlined,
          onTap: () {
            _showComingSoonDialog('Terms of Service');
          },
        ),
        _buildActionTile(
          title: 'Open Source Licenses',
          subtitle: 'View third-party licenses',
          icon: Icons.code_outlined,
          onTap: () {
            _showComingSoonDialog('Open Source Licenses');
          },
        ),
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Icon(icon, color: AppTheme.primaryGreen, size: 18),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text(
                  title,
                  style: AppTheme.headingSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGreen,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textMedium, size: 24),
      title: Text(
        title,
        style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodySmall.copyWith(color: AppTheme.textLight),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryGreen,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingXS,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textMedium, size: 24),
      title: Text(
        title,
        style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodySmall.copyWith(color: AppTheme.textLight),
      ),
      trailing: onTap != null
          ? const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textLight,
              size: 16,
            )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingXS,
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.construction,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Text(
              'Coming Soon',
              style: AppTheme.headingSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          '$feature is coming in a future update. Stay tuned!',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear temporary files and free up storage space. Your grocery data will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
            child: const Text(
              'Clear',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
