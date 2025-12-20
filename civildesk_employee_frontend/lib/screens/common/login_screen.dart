import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _floatController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late Animation<double> _floatAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _pulseAnimation;

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

    // Floating animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -20, end: 20).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Rotation animation
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    // Pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    _floatController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
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
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
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
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = _isMobile(context);
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);

    // Background colors - use theme colors
    final bgColor = colorScheme.surface;
    final textColor = colorScheme.onSurface;
    final borderColor = colorScheme.outline;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: bgColor,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    colorScheme.surface,
                    colorScheme.surfaceContainerHighest,
                  ]
                : [
                    colorScheme.surface,
                    colorScheme.surfaceContainerHighest,
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background shapes and patterns
            ..._buildDecorativeBackground(context, colorScheme, isDark),
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
    final colorScheme = theme.colorScheme;
    final isLandscape = _isLandscape(context);
    final shouldUseTwoColumn = (isTablet || _isDesktop(context)) && isLandscape;

    return ClipRRect(
      borderRadius: BorderRadius.circular(isMobile ? 24 : 32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 24.0 : (isTablet ? 32.0 : 40.0)),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(isMobile ? 24 : 32),
            border: Border.all(
              color: borderColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: shouldUseTwoColumn
              ? _buildTwoColumnLayout(context, isDark, textColor, borderColor, isMobile, isTablet, theme, colorScheme)
              : _buildSingleColumnLayout(context, isDark, textColor, borderColor, isMobile, isTablet, theme, colorScheme),
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
    ColorScheme colorScheme,
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
                  Center(
                    child: Container(
                      width: isTablet ? 140 : 160,
                      height: isTablet ? 140 : 160,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo-app.png',
                          width: isTablet ? 100 : 120,
                          height: isTablet ? 100 : 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.business_rounded,
                              size: isTablet ? 64 : 80,
                              color: colorScheme.primary,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 20 : 28),
                  Text(
                    'CivilDesk',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: isTablet ? 32 : 38,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Employee Portal',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor.withValues(alpha: 0.7),
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
                    color: colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: isDark ? 0.4 : 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    'For Employees Only',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? colorScheme.primaryContainer
                          : colorScheme.primary,
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
                ],
              ),
            ),
          ),
          // Divider
          Container(
            width: 1,
            margin: EdgeInsets.symmetric(vertical: isTablet ? 12.0 : 20.0),
            color: borderColor.withValues(alpha: 0.2),
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
                      labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
                      prefixIcon: Icon(Icons.email_outlined, color: textColor),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
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
                      labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
                      prefixIcon: Icon(Icons.lock_outlined, color: textColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
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
                        activeColor: colorScheme.primary,
                        checkColor: colorScheme.onPrimary,
                      ),
                      Text(
                        'Remember Me',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.8),
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
                          border: Border.all(color: colorScheme.primary, width: 1.5),
                          color: colorScheme.primary,
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
                                          colorScheme.onPrimary,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Login',
                                      style: TextStyle(
                                        color: colorScheme.onPrimary,
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
    ColorScheme colorScheme,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
                // Logo
                Center(
                  child: Container(
                    width: isMobile ? 140 : 160,
                    height: isMobile ? 140 : 160,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo-app.png',
                        width: isMobile ? 100 : 120,
                        height: isMobile ? 100 : 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.business_rounded,
                            size: isMobile ? 64 : 80,
                            color: colorScheme.primary,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 24 : 32),
                // Title
                Text(
                  'CivilDesk',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: isMobile ? 32 : 40,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Employee Portal',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor.withValues(alpha: 0.7),
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
                    color: colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: isDark ? 0.4 : 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    'For Employees Only',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? colorScheme.primaryContainer
                          : colorScheme.primary,
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
                    labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
                    prefixIcon: Icon(Icons.email_outlined, color: textColor),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor.withValues(alpha: 0.3)),
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
                    labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
                    prefixIcon: Icon(Icons.lock_outlined, color: textColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor.withValues(alpha: 0.3)),
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
                      activeColor: colorScheme.primary,
                      checkColor: colorScheme.onPrimary,
                    ),
                    Text(
                      'Remember Me',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.8),
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
                        border: Border.all(color: colorScheme.primary, width: 1.5),
                        color: colorScheme.primary,
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
                                        colorScheme.onPrimary,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Login',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
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
              ],
            ),
        );
  }

  List<Widget> _buildDecorativeBackground(BuildContext context, ColorScheme colorScheme, bool isDark) {
    final screenSize = MediaQuery.of(context).size;
    
    return [
      // Large animated circles
      AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          return Positioned(
            top: -100 + _floatAnimation.value,
            right: -100,
            child: Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.4),
                      colorScheme.primary.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          return Positioned(
            bottom: -150 - _floatAnimation.value * 0.7,
            left: -150,
            child: Transform.scale(
              scale: _pulseAnimation.value * 0.9,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.secondary.withValues(alpha: 0.4),
                      colorScheme.secondary.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      
      // Rotating geometric shapes
      AnimatedBuilder(
        animation: _rotateAnimation,
        builder: (context, child) {
          return Positioned(
            top: screenSize.height * 0.15,
            right: screenSize.width * 0.1,
            child: Transform.rotate(
              angle: _rotateAnimation.value * 2 * math.pi,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      
      // Floating square
      AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          return Positioned(
            top: screenSize.height * 0.7 + _floatAnimation.value * 0.5,
            left: screenSize.width * 0.15,
            child: Transform.rotate(
              angle: _rotateAnimation.value * math.pi,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      
      // Triangle shape (using CustomPaint)
      Positioned(
        top: screenSize.height * 0.3,
        left: -50,
        child: AnimatedBuilder(
          animation: _rotateAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotateAnimation.value * -2 * math.pi,
              child: CustomPaint(
                size: const Size(150, 150),
                painter: _TrianglePainter(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
            );
          },
        ),
      ),
      
      // Small decorative circles
      ...List.generate(5, (index) {
        final positions = [
          Offset(screenSize.width * 0.85, screenSize.height * 0.25),
          Offset(screenSize.width * 0.1, screenSize.height * 0.5),
          Offset(screenSize.width * 0.9, screenSize.height * 0.65),
          Offset(screenSize.width * 0.05, screenSize.height * 0.8),
          Offset(screenSize.width * 0.75, screenSize.height * 0.1),
        ];
        final sizes = [40.0, 60.0, 50.0, 45.0, 35.0];
        final opacities = [0.15, 0.2, 0.18, 0.12, 0.1];
        
        return AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Positioned(
              top: positions[index].dy + _floatAnimation.value * (index % 2 == 0 ? 1 : -1),
              left: positions[index].dx,
              child: Transform.scale(
                scale: _pulseAnimation.value * 0.8,
                child: Container(
                  width: sizes[index],
                  height: sizes[index],
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (index % 2 == 0 
                        ? colorScheme.primary 
                        : colorScheme.secondary).withValues(alpha: opacities[index]),
                    border: Border.all(
                      color: (index % 2 == 0 
                          ? colorScheme.primary 
                          : colorScheme.secondary).withValues(alpha: opacities[index] * 2),
                      width: 1,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
      
      // Pattern dots
      ...List.generate(8, (index) {
        final positions = [
          Offset(screenSize.width * 0.2, screenSize.height * 0.15),
          Offset(screenSize.width * 0.8, screenSize.height * 0.35),
          Offset(screenSize.width * 0.3, screenSize.height * 0.55),
          Offset(screenSize.width * 0.7, screenSize.height * 0.75),
          Offset(screenSize.width * 0.15, screenSize.height * 0.4),
          Offset(screenSize.width * 0.85, screenSize.height * 0.6),
          Offset(screenSize.width * 0.25, screenSize.height * 0.85),
          Offset(screenSize.width * 0.65, screenSize.height * 0.2),
        ];
        
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Positioned(
              top: positions[index].dy,
              left: positions[index].dx,
              child: Transform.scale(
                scale: _pulseAnimation.value * 0.5,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            );
          },
        );
      }),
      
      // Hexagon shape
      Positioned(
        top: screenSize.height * 0.5,
        right: screenSize.width * 0.05,
        child: AnimatedBuilder(
          animation: _rotateAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotateAnimation.value * math.pi,
              child: CustomPaint(
                size: const Size(100, 100),
                painter: _HexagonPainter(
                  color: colorScheme.secondary.withValues(alpha: 0.25),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }
}

// Custom painter for triangle
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for hexagon
class _HexagonPainter extends CustomPainter {
  final Color color;

  _HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) - (math.pi / 6);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
