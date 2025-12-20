import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../widgets/admin_layout.dart';
import '../../widgets/cached_profile_image.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen>
    with SingleTickerProviderStateMixin {
  String? _appVersion;
  String? _appName;
  bool _isProfileExpanded = false; // Default to expanded
  late AnimationController _expansionController;
  late Animation<double> _expansionAnimation;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _expansionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expansionAnimation = CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeInOut,
    );
    // Start expanded
    _expansionController.value = 1.0;
  }

  @override
  void dispose() {
    _expansionController.dispose();
    super.dispose();
  }

  void _toggleProfileExpansion() {
    setState(() {
      _isProfileExpanded = !_isProfileExpanded;
      if (_isProfileExpanded) {
        _expansionController.forward();
      } else {
        _expansionController.reverse();
      }
    });
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _appName = packageInfo.appName;
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
        _appName = 'Civildesk Admin';
      });
    }
  }

  String _getUserName(AuthProvider authProvider) {
    final user = authProvider.user;
    if (user == null) return 'Admin';
    
    final firstName = user['firstName'] as String? ?? '';
    final lastName = user['lastName'] as String? ?? '';
    
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '${firstName.trim()} ${lastName.trim()}'.trim();
    }
    
    return user['email'] as String? ?? 'Admin';
  }

  String _getUserInitials(AuthProvider authProvider) {
    final userName = _getUserName(authProvider);
    if (userName.isEmpty || userName == 'Admin') return 'A';
    
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return userName[0].toUpperCase();
  }

  Color _getSuccessColor(ColorScheme colorScheme, bool isDark) {
    // Use a theme-adaptive success color
    if (isDark) {
      return const Color(0xFF4CAF50); // Material Green 500
    } else {
      return const Color(0xFF2E7D32); // Material Green 800
    }
  }

  Color _getWarningColor(ColorScheme colorScheme, bool isDark) {
    // Use a theme-adaptive warning color
    if (isDark) {
      return const Color(0xFFFF9800); // Material Orange 500
    } else {
      return const Color(0xFFE65100); // Material Orange 900
    }
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  bool _isTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600 && shortestSide < 1024;
  }

  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 1024;
  }

  double _getPadding(BuildContext context) {
    if (_isMobile(context)) return 16.0;
    if (_isTablet(context)) return 24.0;
    return 32.0;
  }

  double _getCardPadding(BuildContext context) {
    if (_isMobile(context)) return 16.0;
    if (_isTablet(context)) return 20.0;
    return 24.0;
  }

  double _getSpacing(BuildContext context) {
    if (_isMobile(context)) return 16.0;
    if (_isTablet(context)) return 20.0;
    return 24.0;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = _isMobile(context);
    final isDesktop = _isDesktop(context);

    return AdminLayout(
      currentRoute: AppRoutes.adminSettings,
      title: const Text('Settings'),
      child: RefreshIndicator(
        onRefresh: () async {
          await _loadAppInfo();
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            // For desktop, use a centered constrained width layout
            if (isDesktop) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: _buildContent(
                    context,
                    theme,
                    colorScheme,
                    isDark,
                    isMobile,
                    isDesktop,
                    authProvider,
                    themeProvider,
                  ),
                ),
              );
            }
            
            return _buildContent(
              context,
              theme,
              colorScheme,
              isDark,
              isMobile,
              isDesktop,
              authProvider,
              themeProvider,
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    bool isMobile,
    bool isDesktop,
    AuthProvider authProvider,
    ThemeProvider themeProvider,
  ) {
    final padding = _getPadding(context);
    final spacing = _getSpacing(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(padding),
      child: isDesktop
          ? _buildDesktopLayout(
              context,
              theme,
              colorScheme,
              isDark,
              authProvider,
              themeProvider,
              spacing,
            )
          : _buildMobileTabletLayout(
              context,
              theme,
              colorScheme,
              isDark,
              authProvider,
              themeProvider,
              spacing,
            ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    AuthProvider authProvider,
    ThemeProvider themeProvider,
    double spacing,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column - Profile
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildProfileSection(
                context,
                theme,
                colorScheme,
                isDark,
                authProvider,
              ),
              SizedBox(height: spacing),
              _buildAppInfoSection(
                context,
                theme,
                colorScheme,
                isDark,
              ),
            ],
          ),
        ),
        SizedBox(width: spacing),
        // Right column - Theme
        Expanded(
          flex: 1,
          child: _buildThemeSection(
            context,
            theme,
            colorScheme,
            isDark,
            themeProvider,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabletLayout(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    AuthProvider authProvider,
    ThemeProvider themeProvider,
    double spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileSection(
          context,
          theme,
          colorScheme,
          isDark,
          authProvider,
        ),
        SizedBox(height: spacing),
        _buildThemeSection(
          context,
          theme,
          colorScheme,
          isDark,
          themeProvider,
        ),
        SizedBox(height: spacing),
        _buildAppInfoSection(
          context,
          theme,
          colorScheme,
          isDark,
        ),
        SizedBox(height: spacing),
      ],
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    AuthProvider authProvider,
  ) {
    final user = authProvider.user;
    final cardPadding = _getCardPadding(context);
    final isMobile = _isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExpandableSectionHeader(
          theme,
          colorScheme,
          'Admin Profile',
          Icons.person_rounded,
          _isProfileExpanded,
          _toggleProfileExpansion,
        ),
        const SizedBox(height: 12),
        Card(
          elevation: isDark ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
            side: BorderSide(
              color: isDark
                  ? colorScheme.outline.withValues(alpha: 0.2)
                  : colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
              gradient: isDark
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.surface,
                        colorScheme.surface.withValues(alpha: 0.95),
                      ],
                    ),
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                children: [
                  // Profile Header with enhanced design
                  Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                          : colorScheme.primaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CachedProfileImage(
                            imageUrl: null,
                            fallbackInitials: _getUserInitials(authProvider),
                            radius: isMobile ? 35 : 45,
                            backgroundColor: isDark
                                ? colorScheme.primaryContainer
                                : colorScheme.primary,
                            foregroundColor: isDark
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onPrimary,
                          ),
                        ),
                        SizedBox(width: isMobile ? 16 : 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getUserName(authProvider),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 20 : 24,
                                ),
                              ),
                              if (user?['role'] != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    user!['role'] as String? ?? 'Admin',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Only show divider and spacing when expanded
                  SizeTransition(
                    sizeFactor: _expansionAnimation,
                    child: Column(
                      children: [
                        SizedBox(height: isMobile ? 20 : 24),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        SizedBox(height: isMobile ? 20 : 24),
                      ],
                    ),
                  ),
                  
                  // Expandable Information Grid
                  SizeTransition(
                    sizeFactor: _expansionAnimation,
                    child: FadeTransition(
                      opacity: _expansionAnimation,
                      child: _buildInfoGrid(
                        context,
                        theme,
                        colorScheme,
                        isDark,
                        user,
                        isMobile,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    Map<String, dynamic>? user,
    bool isMobile,
  ) {
    final infoItems = <_InfoItem>[];

    if (user?['email'] != null) {
      infoItems.add(_InfoItem(
        icon: Icons.email_rounded,
        label: 'Email',
        value: user!['email'] as String? ?? 'N/A',
      ));
    }

    if (user?['firstName'] != null) {
      infoItems.add(_InfoItem(
        icon: Icons.person_outline_rounded,
        label: 'First Name',
        value: user!['firstName'] as String? ?? 'N/A',
      ));
    }

    if (user?['lastName'] != null) {
      infoItems.add(_InfoItem(
        icon: Icons.person_outline_rounded,
        label: 'Last Name',
        value: user!['lastName'] as String? ?? 'N/A',
      ));
    }

    infoItems.add(_InfoItem(
      icon: Icons.admin_panel_settings_rounded,
      label: 'Role',
      value: user?['role'] as String? ?? 'ADMIN',
    ));

    if (user?['isActive'] != null) {
      infoItems.add(_InfoItem(
        icon: user!['isActive'] == true
            ? Icons.check_circle_rounded
            : Icons.cancel_rounded,
        label: 'Account Status',
        value: user['isActive'] == true ? 'Active' : 'Inactive',
        valueColor: user['isActive'] == true
            ? _getSuccessColor(colorScheme, isDark)
            : colorScheme.error,
      ));
    }

    if (user?['emailVerified'] != null) {
      infoItems.add(_InfoItem(
        icon: user!['emailVerified'] == true
            ? Icons.verified_rounded
            : Icons.verified_user_outlined,
        label: 'Email Verified',
        value: user['emailVerified'] == true ? 'Verified' : 'Not Verified',
        valueColor: user['emailVerified'] == true
            ? _getSuccessColor(colorScheme, isDark)
            : _getWarningColor(colorScheme, isDark),
      ));
    }

    if (isMobile) {
      // Single column for mobile
      return Column(
        children: infoItems
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildInfoRow(
                    theme,
                    colorScheme,
                    item.icon,
                    item.label,
                    item.value,
                    valueColor: item.valueColor,
                  ),
                ))
            .toList(),
      );
    } else {
      // Two columns for tablet/desktop
      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 3.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: infoItems.length,
            itemBuilder: (context, index) {
              final item = infoItems[index];
              return _buildInfoRow(
                theme,
                colorScheme,
                item.icon,
                item.label,
                item.value,
                valueColor: item.valueColor,
              );
            },
          );
        },
      );
    }
  }

  Widget _buildThemeSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    ThemeProvider themeProvider,
  ) {
    final isMobile = _isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          theme,
          colorScheme,
          'Theme Preferences',
          Icons.palette_rounded,
        ),
        const SizedBox(height: 12),
        Card(
          elevation: isDark ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
            side: BorderSide(
              color: isDark
                  ? colorScheme.outline.withValues(alpha: 0.2)
                  : colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
              gradient: isDark
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.surface,
                        colorScheme.surface.withValues(alpha: 0.95),
                      ],
                    ),
            ),
            child: RadioGroup<ThemeMode>(
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .setThemeMode(newValue);
                }
              },
              child: Column(
                children: [
                  _buildThemeOption(
                    context,
                    theme,
                    colorScheme,
                    isDark,
                    Icons.brightness_6,
                    'System',
                    'Follow system theme',
                    ThemeMode.system,
                    themeProvider.themeMode,
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  _buildThemeOption(
                    context,
                    theme,
                    colorScheme,
                    isDark,
                    Icons.light_mode,
                    'Light',
                    'Always use light theme',
                    ThemeMode.light,
                    themeProvider.themeMode,
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  _buildThemeOption(
                    context,
                    theme,
                    colorScheme,
                    isDark,
                    Icons.dark_mode,
                    'Dark',
                    'Always use dark theme',
                    ThemeMode.dark,
                    themeProvider.themeMode,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    IconData icon,
    String title,
    String subtitle,
    ThemeMode value,
    ThemeMode groupValue,
  ) {
    final isSelected = value == groupValue;
    final cardPadding = _getCardPadding(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Provider.of<ThemeProvider>(context, listen: false).setThemeMode(value);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : colorScheme.primaryContainer.withValues(alpha: 0.2))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<ThemeMode>(
                value: value,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final isMobile = _isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          theme,
          colorScheme,
          'App Information',
          Icons.info_rounded,
        ),
        const SizedBox(height: 12),
        Card(
          elevation: isDark ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
            side: BorderSide(
              color: isDark
                  ? colorScheme.outline.withValues(alpha: 0.2)
                  : colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
              gradient: isDark
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.surface,
                        colorScheme.surface.withValues(alpha: 0.95),
                      ],
                    ),
            ),
            child: Column(
              children: [
                _buildAppInfoTile(
                  context,
                  theme,
                  colorScheme,
                  isDark,
                  Icons.info,
                  'Version',
                  _appVersion ?? '1.0.0',
                  () {
                    showAboutDialog(
                      context: context,
                      applicationName: _appName ?? 'Civildesk Admin',
                      applicationVersion: _appVersion ?? '1.0.0',
                      applicationIcon: const Icon(Icons.business, size: 48),
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text(
                            'Admin management application for Civildesk.',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
                _buildAppInfoTile(
                  context,
                  theme,
                  colorScheme,
                  isDark,
                  Icons.privacy_tip,
                  'Privacy Policy',
                  'View privacy policy',
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Privacy Policy coming soon'),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
                _buildAppInfoTile(
                  context,
                  theme,
                  colorScheme,
                  isDark,
                  Icons.description,
                  'Terms & Conditions',
                  'View terms and conditions',
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Terms & Conditions coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfoTile(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final cardPadding = _getCardPadding(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSectionHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    String title,
    IconData icon,
    bool isExpanded,
    VoidCallback onToggle,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              RotationTransition(
                turns: Tween<double>(begin: 0.0, end: 0.5).animate(
                  CurvedAnimation(
                    parent: _expansionController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Icon(
                  Icons.expand_more,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    ColorScheme colorScheme,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: valueColor ?? colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}
