import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/services/employee_service.dart';
import '../../core/utils/validators.dart';
import '../../widgets/cached_profile_image.dart';
import '../../widgets/employee_layout.dart';
import '../../widgets/toast.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _appVersion;
  String? _appName;
  Map<String, dynamic>? _employeeData;
  bool _isLoadingEmployee = false;
  String? _employeeError;
  final EmployeeService _employeeService = EmployeeService();
  bool _isEmployeeInfoExpanded = false; // Default to collapsed

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    // Defer dashboard stats fetch to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
    _loadEmployeeDetails();
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
        _appName = 'Civildesk Employee';
      });
    }
  }

  Future<void> _loadProfile() async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    if (provider.dashboardStats == null) {
      await provider.fetchDashboardStats();
    }
  }

  Future<void> _loadEmployeeDetails() async {
    setState(() {
      _isLoadingEmployee = true;
      _employeeError = null;
    });

    try {
      final employeeData = await _employeeService.getCurrentEmployeeDetails();
      setState(() {
        _employeeData = employeeData;
        _isLoadingEmployee = false;
      });
    } catch (e) {
      setState(() {
        _employeeError = e.toString();
        _isLoadingEmployee = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final personalInfo = dashboardProvider.dashboardStats?.personalInfo;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return EmployeeLayout(
      currentRoute: AppRoutes.settings,
      title: const Text('Settings'),
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_loadProfile(), _loadEmployeeDetails()]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Employee Information Section
            _buildSectionHeader(
              theme,
              colorScheme,
              'Employee Information',
              Icons.person_rounded,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Profile Header (Always visible)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isEmployeeInfoExpanded = !_isEmployeeInfoExpanded;
                      });
                    },
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CachedProfileImage(
                            imageUrl:
                                _employeeData?['profilePhotoUrl'] ??
                                _employeeData?['employee']?['profilePhotoUrl'],
                            fallbackInitials: authProvider.userName ?? 'E',
                            radius: 30,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authProvider.userName ?? 'Employee',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (personalInfo?.designation != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    personalInfo!.designation,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            _isEmployeeInfoExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Expandable Content
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          const Divider(),
                          const SizedBox(height: 16),
                          // Basic Information
                          if (_isLoadingEmployee)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_employeeError != null)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: colorScheme.error,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Failed to load employee details',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.error,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _loadEmployeeDetails,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          else if (_employeeData != null) ...[
                            // Employee ID
                            _buildInfoRow(
                              theme,
                              colorScheme,
                              Icons.badge_rounded,
                              'Employee ID',
                              _employeeData!['employeeId'] ??
                                  personalInfo?.employeeCode ??
                                  'N/A',
                            ),
                            const SizedBox(height: 12),

                            // Email
                            _buildInfoRow(
                              theme,
                              colorScheme,
                              Icons.email_rounded,
                              'Email',
                              _employeeData!['email'] ??
                                  personalInfo?.email ??
                                  authProvider.user?['email'] ??
                                  'N/A',
                            ),
                            const SizedBox(height: 12),

                            // Phone Number
                            if (_employeeData!['phoneNumber'] != null)
                              _buildInfoRow(
                                theme,
                                colorScheme,
                                Icons.phone_rounded,
                                'Phone Number',
                                _employeeData!['phoneNumber'],
                              ),
                            if (_employeeData!['phoneNumber'] != null)
                              const SizedBox(height: 12),

                            // Department
                            _buildInfoRow(
                              theme,
                              colorScheme,
                              Icons.business_rounded,
                              'Department',
                              _employeeData!['department'] ??
                                  personalInfo?.department ??
                                  'N/A',
                            ),
                            const SizedBox(height: 12),

                            // Designation
                            _buildInfoRow(
                              theme,
                              colorScheme,
                              Icons.work_rounded,
                              'Designation',
                              _employeeData!['designation'] ??
                                  personalInfo?.designation ??
                                  'N/A',
                            ),

                            // Additional fields if available
                            if (_employeeData!['alternatePhoneNumber'] !=
                                null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                theme,
                                colorScheme,
                                Icons.phone_android_rounded,
                                'Alternate Phone',
                                _employeeData!['alternatePhoneNumber'],
                              ),
                            ],

                            if (_employeeData!['joiningDate'] != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                theme,
                                colorScheme,
                                Icons.calendar_today_rounded,
                                'Joining Date',
                                DateFormat('MMM dd, yyyy').format(
                                  DateTime.parse(_employeeData!['joiningDate']),
                                ),
                              ),
                            ],

                            if (_employeeData!['employmentStatus'] != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                theme,
                                colorScheme,
                                Icons.verified_user_rounded,
                                'Employment Status',
                                _employeeData!['employmentStatus'],
                              ),
                            ],

                            if (_employeeData!['employmentType'] != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                theme,
                                colorScheme,
                                Icons.business_center_rounded,
                                'Employment Type',
                                _employeeData!['employmentType'],
                              ),
                            ],

                            if (_employeeData!['workLocation'] != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                theme,
                                colorScheme,
                                Icons.location_on_rounded,
                                'Work Location',
                                _employeeData!['workLocation'],
                              ),
                            ],
                          ] else ...[
                            // Fallback to personalInfo if employeeData is not available
                            _buildInfoRow(
                              theme,
                              colorScheme,
                              Icons.badge_rounded,
                              'Employee Code',
                              personalInfo?.employeeCode ?? 'N/A',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              theme,
                              colorScheme,
                              Icons.email_rounded,
                              'Email',
                              personalInfo?.email ??
                                  authProvider.user?['email'] ??
                                  'N/A',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              theme,
                              colorScheme,
                              Icons.business_rounded,
                              'Department',
                              personalInfo?.department ?? 'N/A',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              theme,
                              colorScheme,
                              Icons.work_rounded,
                              'Designation',
                              personalInfo?.designation ?? 'N/A',
                            ),
                          ],
                        ],
                      ),
                    ),
                    crossFadeState: _isEmployeeInfoExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contact Information Section
            if (_employeeData != null &&
                (_employeeData!['addressLine1'] != null ||
                    _employeeData!['city'] != null ||
                    _employeeData!['state'] != null ||
                    _employeeData!['pincode'] != null ||
                    _employeeData!['country'] != null)) ...[
              _buildSectionHeader(
                theme,
                colorScheme,
                'Contact Information',
                Icons.contact_phone_rounded,
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_employeeData!['addressLine1'] != null)
                        _buildInfoRow(
                          theme,
                          colorScheme,
                          Icons.home_rounded,
                          'Address',
                          _employeeData!['addressLine1'] +
                              (_employeeData!['addressLine2'] != null
                                  ? ', ${_employeeData!['addressLine2']}'
                                  : ''),
                        ),
                      if (_employeeData!['addressLine1'] != null)
                        const SizedBox(height: 12),
                      if (_employeeData!['city'] != null ||
                          _employeeData!['state'] != null ||
                          _employeeData!['pincode'] != null)
                        _buildInfoRow(
                          theme,
                          colorScheme,
                          Icons.location_city_rounded,
                          'City, State, Pincode',
                          [
                            _employeeData!['city'],
                            _employeeData!['state'],
                            _employeeData!['pincode'],
                          ].where((e) => e != null).join(', '),
                        ),
                      if (_employeeData!['city'] != null ||
                          _employeeData!['state'] != null ||
                          _employeeData!['pincode'] != null)
                        const SizedBox(height: 12),
                      if (_employeeData!['country'] != null)
                        _buildInfoRow(
                          theme,
                          colorScheme,
                          Icons.public_rounded,
                          'Country',
                          _employeeData!['country'],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Work Information Section
            if (_employeeData != null &&
                (_employeeData!['reportingManagerName'] != null ||
                    _employeeData!['reportingManagerId'] != null)) ...[
              _buildSectionHeader(
                theme,
                colorScheme,
                'Work Information',
                Icons.work_outline_rounded,
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_employeeData!['reportingManagerName'] != null)
                        _buildInfoRow(
                          theme,
                          colorScheme,
                          Icons.supervisor_account_rounded,
                          'Reporting Manager',
                          _employeeData!['reportingManagerName'],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Password Change Section
            _buildSectionHeader(
              theme,
              colorScheme,
              'Security',
              Icons.lock_rounded,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: Icon(Icons.lock_outline_rounded, color: colorScheme.primary),
                title: const Text('Change Password'),
                subtitle: const Text('Update your account password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showChangePasswordDialog(context, theme, colorScheme);
                },
              ),
            ),
            const SizedBox(height: 24),

            // Theme Mode Section
            _buildSectionHeader(
              theme,
              colorScheme,
              'Theme',
              Icons.palette_rounded,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: RadioGroup<ThemeMode>(
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      secondary: const Icon(Icons.brightness_6),
                      title: const Text('System'),
                      subtitle: const Text('Follow system theme'),
                      value: ThemeMode.system,
                    ),
                    const Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      secondary: const Icon(Icons.light_mode),
                      title: const Text('Light'),
                      subtitle: const Text('Always use light theme'),
                      value: ThemeMode.light,
                    ),
                    const Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      secondary: const Icon(Icons.dark_mode),
                      title: const Text('Dark'),
                      subtitle: const Text('Always use dark theme'),
                      value: ThemeMode.dark,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Color Palette Section
            _buildSectionHeader(
              theme,
              colorScheme,
              'Color Palette',
              Icons.color_lens_rounded,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: RadioGroup<ColorPalette>(
                groupValue: themeProvider.colorPalette,
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setColorPalette(value);
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<ColorPalette>(
                      secondary: _buildPalettePreview(
                        theme,
                        ColorPalette.palette1,
                      ),
                      title: const Text('Palette 1'),
                      subtitle: const Text('Blue tones'),
                      value: ColorPalette.palette1,
                    ),
                    const Divider(height: 1),
                    RadioListTile<ColorPalette>(
                      secondary: _buildPalettePreview(
                        theme,
                        ColorPalette.palette2,
                      ),
                      title: const Text('Palette 2'),
                      subtitle: const Text('Grayscale'),
                      value: ColorPalette.palette2,
                    ),
                    const Divider(height: 1),
                    RadioListTile<ColorPalette>(
                      secondary: _buildPalettePreview(
                        theme,
                        ColorPalette.palette3,
                      ),
                      title: const Text('Palette 3'),
                      subtitle: const Text('Green/Red tones'),
                      value: ColorPalette.palette3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Notification Settings Section
            _buildSectionHeader(
              theme,
              colorScheme,
              'Notifications',
              Icons.notifications_rounded,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Consumer<NotificationProvider>(
                builder: (context, notificationProvider, _) {
                  return SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive push notifications for important updates'),
                    secondary: Icon(
                      Icons.notifications,
                      color: notificationProvider.notificationsEnabled
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    value: notificationProvider.notificationsEnabled,
                    onChanged: (value) async {
                      await notificationProvider.toggleNotifications(value);
                      if (mounted) {
                        Toast.show(
                          context,
                          message: value
                              ? 'Notifications enabled'
                              : 'Notifications disabled',
                          type: value ? ToastType.success : ToastType.info,
                        );
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // App Info Section
            _buildSectionHeader(
              theme,
              colorScheme,
              'App Information',
              Icons.info_rounded,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('Version'),
                    subtitle: Text(_appVersion ?? '1.0.0'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: _appName ?? 'Civildesk Employee',
                        applicationVersion: _appVersion ?? '1.0.0',
                        applicationIcon: const Icon(Icons.business, size: 48),
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text(
                              'Employee management application for Civildesk.',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Toast.info(context, 'Privacy Policy coming soon');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Terms & Conditions'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Toast.info(context, 'Terms & Conditions coming soon');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.error,
                            foregroundColor: colorScheme.onError,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (route) => false,
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
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
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    ColorScheme colorScheme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
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
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPalettePreview(ThemeData theme, ColorPalette palette) {
    List<Color> colors;
    switch (palette) {
      case ColorPalette.palette1:
        colors = [
          const Color(0xFF0047AB),
          const Color(0xFF000080),
          const Color(0xFF82C8E5),
          const Color(0xFF6D8196),
        ];
        break;
      case ColorPalette.palette2:
        colors = [
          const Color(0xFFFFFFFF),
          const Color(0xFFD4D4D4),
          const Color(0xFFB3B3B3),
          const Color(0xFF2B2B2B),
        ];
        break;
      case ColorPalette.palette3:
        colors = [
          const Color(0xFFCBCBCB),
          const Color(0xFFF2F2F2),
          const Color(0xFF174D38),
          const Color(0xFF4D1717),
        ];
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: colors.map((color) {
        return Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showChangePasswordDialog(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final _currentPasswordController = TextEditingController();
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    bool _obscureCurrentPassword = true;
    bool _obscureNewPassword = true;
    bool _obscureConfirmPassword = true;
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrentPassword,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrentPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureCurrentPassword = !_obscureCurrentPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Current password is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: 'Password must be at least 8 characters',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'New password is required';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirm password is required';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _isLoading = true;
                        });

                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final success = await authProvider.changePassword(
                          _currentPasswordController.text,
                          _newPasswordController.text,
                          _confirmPasswordController.text,
                        );

                        if (context.mounted) {
                          setState(() {
                            _isLoading = false;
                          });

                          if (success) {
                            Navigator.of(context).pop();
                            Toast.show(
                              context,
                              message: 'Password changed successfully',
                              type: ToastType.success,
                            );
                          } else {
                            final errorMessage = authProvider.lastError ?? 'Failed to change password';
                            Toast.show(
                              context,
                              message: errorMessage,
                              type: ToastType.error,
                            );
                          }
                        }
                      }
                    },
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}
