import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (success && mounted) {
      final role = authProvider.userRole;
      String route;
      
      switch (role) {
        case 'ADMIN':
          route = AppRoutes.adminDashboard;
          break;
        case 'HR_MANAGER':
          route = AppRoutes.hrDashboard;
          break;
        default:
          route = AppRoutes.login;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Access denied. This app is for administrators only.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return;
      }

      Navigator.of(context).pushReplacementNamed(route);
    } else if (mounted) {
      final errorMessage = authProvider.lastError ?? 'Login failed. Please check your credentials.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  bool _isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  bool _isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = _isMobile(context);
    final isTablet = _isTablet(context);
    final isDesktop = _isDesktop(context);
    final isLandscape = _isLandscape(context);

    // Background colors
    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: bgColor,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Colors.black,
                    Colors.grey.shade900,
                  ]
                : [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background shapes
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.black.withOpacity(0.03),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withOpacity(0.02)
                      : Colors.black.withOpacity(0.02),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      isMobile ? 20.0 : (isTablet ? 40.0 : 60.0),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile
                            ? double.infinity
                            : (isLandscape
                                ? MediaQuery.of(context).size.width * 0.7
                                : (isTablet ? 500 : 450)),
                      ),
                      child: _buildGlassCard(
                        context,
                        isDark,
                        textColor,
                        borderColor,
                        isMobile,
                        isTablet,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color borderColor,
    bool isMobile,
    bool isTablet,
  ) {
    final theme = Theme.of(context);
    final isLandscape = _isLandscape(context);
    final shouldUseTwoColumn = (isTablet || _isDesktop(context)) && isLandscape;

    return ClipRRect(
      borderRadius: BorderRadius.circular(isMobile ? 24 : 32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 24.0 : (isTablet ? 32.0 : 40.0)),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(isMobile ? 24 : 32),
            border: Border.all(
              color: borderColor.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: shouldUseTwoColumn
              ? _buildTwoColumnLayout(context, isDark, textColor, borderColor, isMobile, isTablet, theme)
              : _buildSingleColumnLayout(context, isDark, textColor, borderColor, isMobile, isTablet, theme),
        ),
      ),
    );
  }

  Widget _buildTwoColumnLayout(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color borderColor,
    bool isMobile,
    bool isTablet,
    ThemeData theme,
  ) {
    return Form(
      key: _formKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Section: Logo, Subtitle, Mark Attendance Button
          Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.only(right: isTablet ? 20.0 : 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: borderColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Image.asset(
                      'assets/app-logo.png',
                      width: isTablet ? 56 : 64,
                      height: isTablet ? 56 : 64,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: isTablet ? 20 : 28),
                  Text(
                    'CivilTech EMS',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: isTablet ? 32 : 38,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Admin Portal',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                      fontSize: isTablet ? 14 : 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  // Badge with proper constraints
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.orange.withOpacity(0.15)
                            : Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.orange.withOpacity(0.4)
                              : Colors.orange.withOpacity(0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        'For Administrators & HR Managers Only',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? Colors.orange.shade300
                              : Colors.orange.shade800,
                          fontSize: isTablet ? 10 : 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 28 : 36),
                  // Mark Attendance button with proper constraints
                  Container(
                    height: isTablet ? 48 : 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1.5),
                      color: Colors.transparent,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pushNamed(AppRoutes.faceAttendance);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.face_retouching_natural,
                                color: textColor,
                                size: isTablet ? 18 : 20,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Mark Attendance',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: isTablet ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Divider
          Container(
            width: 1,
            margin: EdgeInsets.symmetric(vertical: isTablet ? 12.0 : 20.0),
            color: borderColor.withOpacity(0.2),
          ),
          // Right Section: Login Form
          Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.only(left: isTablet ? 20.0 : 28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: isTablet ? 4 : 8),
                  Text(
                    'Login',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: isTablet ? 22 : 26,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isTablet ? 20 : 28),
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.email_outlined, color: textColor),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1),
                      ),
                    ),
                    validator: Validators.validateEmail,
                  ),
                  SizedBox(height: isTablet ? 16 : 20),
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.lock_outlined, color: textColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: textColor.withOpacity(0.7),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1),
                      ),
                    ),
                    validator: (value) => Validators.validateRequired(
                      value,
                      fieldName: 'Password',
                    ),
                  ),
                  SizedBox(height: isTablet ? 16 : 20),
                  // Remember Me checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: borderColor,
                        checkColor: isDark ? Colors.black : Colors.white,
                      ),
                      Text(
                        'Remember Me',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: isTablet ? 14 : 15,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 24 : 28),
                  // Login button
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      return Container(
                        height: isTablet ? 50 : 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 1.5),
                          color: textColor,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: authProvider.isLoading ? null : _handleLogin,
                            borderRadius: BorderRadius.circular(12),
                            child: Center(
                              child: authProvider.isLoading
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isDark ? Colors.black : Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Login',
                                      style: TextStyle(
                                        color: isDark ? Colors.black : Colors.white,
                                        fontSize: isTablet ? 16 : 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isTablet ? 16 : 20),
                  // Sign up link
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.signup);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Don\'t have an account? Sign Up',
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontSize: isTablet ? 14 : 15,
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSingleColumnLayout(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color borderColor,
    bool isMobile,
    bool isTablet,
    ThemeData theme,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: borderColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Image.asset(
                    'assets/app-logo.png',
                    width: isMobile ? 50 : 60,
                    height: isMobile ? 50 : 60,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: isMobile ? 24 : 32),
                // Title
                Text(
                  'CivilTech EMS',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: isMobile ? 32 : 40,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Admin Portal',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: isMobile ? 14 : 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.orange.withOpacity(0.15)
                        : Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.orange.withOpacity(0.4)
                          : Colors.orange.withOpacity(0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    'For Administrators & HR Managers Only',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? Colors.orange.shade300
                          : Colors.orange.shade800,
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: isMobile ? 32 : 40),
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.email_outlined, color: textColor),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 1),
                    ),
                  ),
                  validator: Validators.validateEmail,
                ),
                SizedBox(height: isMobile ? 16 : 20),
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.lock_outlined, color: textColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: textColor.withOpacity(0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 1),
                    ),
                  ),
                  validator: (value) => Validators.validateRequired(
                    value,
                    fieldName: 'Password',
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 20),
                // Remember Me checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      activeColor: borderColor,
                      checkColor: isDark ? Colors.black : Colors.white,
                    ),
                    Text(
                      'Remember Me',
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontSize: isMobile ? 14 : 15,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 28 : 32),
                // Login button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return Container(
                      height: isMobile ? 50 : 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1.5),
                        color: textColor,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: authProvider.isLoading ? null : _handleLogin,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: authProvider.isLoading
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isDark ? Colors.black : Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Login',
                                    style: TextStyle(
                                      color: isDark ? Colors.black : Colors.white,
                                      fontSize: isMobile ? 16 : 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: isMobile ? 16 : 20),
                // Mark Attendance button
                Container(
                  height: isMobile ? 50 : 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1.5),
                    color: Colors.transparent,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRoutes.faceAttendance);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.face_retouching_natural,
                                color: textColor,
                                size: isMobile ? 20 : 22,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Mark Attendance',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 20 : 24),
                // Sign up link
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.signup);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Don\'t have an account? Sign Up',
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: isMobile ? 14 : 15,
                    ),
                  ),
                ),
              ],
            ),
        );
  }
}

