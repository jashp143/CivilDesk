import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../widgets/cached_profile_image.dart';
import '../../widgets/employee_layout.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _appVersion;
  String? _appName;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _loadProfile();
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final personalInfo = dashboardProvider.dashboardStats?.personalInfo;

    return EmployeeLayout(
      currentRoute: AppRoutes.settings,
      title: const Text('Settings'),
      child: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          children: [
            // Profile Information Section
            _buildSectionHeader('Profile Information'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: CachedProfileImage(
                      imageUrl: null,
                      fallbackInitials: authProvider.userName ?? 'E',
                      radius: 20,
                    ),
                    title: Text(
                      authProvider.userName ?? 'Employee',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: personalInfo != null
                        ? Text(personalInfo.designation)
                        : null,
                  ),
                  if (personalInfo != null) ...[
                    const Divider(height: 1),
                    _buildInfoTile(
                      'Employee Code',
                      personalInfo.employeeCode,
                      Icons.badge,
                    ),
                    const Divider(height: 1),
                    _buildInfoTile(
                      'Email',
                      personalInfo.email,
                      Icons.email,
                    ),
                    const Divider(height: 1),
                    _buildInfoTile(
                      'Department',
                      personalInfo.department,
                      Icons.business,
                    ),
                    const Divider(height: 1),
                    _buildInfoTile(
                      'Designation',
                      personalInfo.designation,
                      Icons.work,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Theme Mode Section
            _buildSectionHeader('Theme'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    secondary: const Icon(Icons.brightness_6),
                    title: const Text('System'),
                    subtitle: const Text('Follow system theme'),
                    value: ThemeMode.system,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.setThemeMode(value);
                      }
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    secondary: const Icon(Icons.light_mode),
                    title: const Text('Light'),
                    subtitle: const Text('Always use light theme'),
                    value: ThemeMode.light,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.setThemeMode(value);
                      }
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    secondary: const Icon(Icons.dark_mode),
                    title: const Text('Dark'),
                    subtitle: const Text('Always use dark theme'),
                    value: ThemeMode.dark,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.setThemeMode(value);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Color Palette Section
            _buildSectionHeader('Color Palette'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  RadioListTile<ColorPalette>(
                    secondary: _buildPalettePreview(ColorPalette.palette1),
                    title: const Text('Palette 1'),
                    subtitle: const Text('Blue tones'),
                    value: ColorPalette.palette1,
                    groupValue: themeProvider.colorPalette,
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.setColorPalette(value);
                      }
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<ColorPalette>(
                    secondary: _buildPalettePreview(ColorPalette.palette2),
                    title: const Text('Palette 2'),
                    subtitle: const Text('Grayscale'),
                    value: ColorPalette.palette2,
                    groupValue: themeProvider.colorPalette,
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.setColorPalette(value);
                      }
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<ColorPalette>(
                    secondary: _buildPalettePreview(ColorPalette.palette3),
                    title: const Text('Palette 3'),
                    subtitle: const Text('Green/Red tones'),
                    value: ColorPalette.palette3,
                    groupValue: themeProvider.colorPalette,
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.setColorPalette(value);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // App Info Section
            _buildSectionHeader('App Information'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      // TODO: Show privacy policy
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Privacy Policy coming soon'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Terms & Conditions'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Show terms and conditions
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
            const SizedBox(height: 32),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
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
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildPalettePreview(ColorPalette palette) {
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              width: 1,
            ),
          ),
        );
      }).toList(),
    );
  }
}
