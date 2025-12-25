import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../widgets/toast.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isResendingOtp = false;
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
    // Auto-focus first OTP field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _moveToNext(int index) {
    if (index < 5 && _otpControllers[index].text.isNotEmpty) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _moveToPrevious(int index) {
    if (index > 0 && _otpControllers[index].text.isEmpty) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    
    if (otp.length != 6) {
      Toast.warning(context, 'Please enter the complete 6-digit OTP');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtp(
      email: widget.email,
      otp: otp,
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
        case 'EMPLOYEE':
          route = AppRoutes.employeeDashboard;
          break;
        default:
          route = AppRoutes.login;
      }

      Navigator.of(context).pushReplacementNamed(route);
    } else if (mounted) {
      final errorMessage = authProvider.lastError ?? 'OTP verification failed. Please try again.';
      Toast.error(context, errorMessage);
    }
  }

  Future<void> _handleResendOtp() async {
    setState(() {
      _isResendingOtp = true;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendOtp(email: widget.email);

    if (mounted) {
      setState(() {
        _isResendingOtp = false;
      });

      if (success) {
        // Clear OTP fields
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();

        Toast.success(context, 'OTP sent successfully to your email');
      } else {
        Toast.error(context, authProvider.lastError ?? 'Failed to resend OTP');
      }
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
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.03),
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
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.black.withValues(alpha: 0.02),
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
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(isMobile ? 24 : 32),
            border: Border.all(
              color: borderColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.1),
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
          // Left Section: Logo, Subtitle
          Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.only(right: isTablet ? 24.0 : 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: borderColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.email_outlined,
                      size: isTablet ? 60 : 70,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: isTablet ? 24 : 32),
                  Text(
                    'Civildesk',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: isTablet ? 36 : 42,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Email Verification',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                      fontSize: isTablet ? 15 : 17,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          // Divider
          Container(
            width: 1,
            margin: EdgeInsets.symmetric(vertical: isTablet ? 16.0 : 24.0),
            color: borderColor.withValues(alpha: 0.2),
          ),
          // Right Section: OTP Form
          Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.only(left: isTablet ? 24.0 : 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: isTablet ? 8 : 16),
                  Text(
                    'Verify Your Email',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: isTablet ? 24 : 28,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a verification code to',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: isTablet ? 13 : 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 14 : 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isTablet ? 32 : 40),
                  // OTP fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: isTablet ? 42 : 50,
                        height: isTablet ? 52 : 60,
                        child: TextFormField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(
                            fontSize: isTablet ? 22 : 26,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: borderColor.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: borderColor.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: borderColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              _moveToNext(index);
                            } else {
                              _moveToPrevious(index);
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: isTablet ? 28 : 32),
                  // Verify button
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
                            onTap: authProvider.isLoading ? null : _handleVerifyOtp,
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
                                      'Verify OTP',
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
                  // Resend OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the code? ",
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: isTablet ? 13 : 14,
                        ),
                      ),
                      TextButton(
                        onPressed: _isResendingOtp ? null : _handleResendOtp,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: _isResendingOtp
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                                ),
                              )
                            : Text(
                                'Resend OTP',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: isTablet ? 13 : 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 12 : 16),
                  // Back to login
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.8),
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
                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: borderColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    size: isMobile ? 50 : 60,
                    color: textColor,
                  ),
                ),
                SizedBox(height: isMobile ? 24 : 32),
                // Title
                Text(
                  'Verify Your Email',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: isMobile ? 24 : 28,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Email text
                Text(
                  'We sent a verification code to',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: isMobile ? 13 : 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 14 : 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 40 : 48),
                // OTP fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: isMobile ? 42 : 50,
                      height: isMobile ? 52 : 60,
                      child: TextFormField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: TextStyle(
                          fontSize: isMobile ? 22 : 26,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: borderColor.withValues(alpha: 0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: borderColor.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: borderColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            _moveToNext(index);
                          } else {
                            _moveToPrevious(index);
                          }
                        },
                      ),
                    );
                  }),
                ),
                SizedBox(height: isMobile ? 32 : 40),
                // Verify button
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
                          onTap: authProvider.isLoading ? null : _handleVerifyOtp,
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
                                    'Verify OTP',
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
                SizedBox(height: isMobile ? 20 : 24),
                // Resend OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: isMobile ? 13 : 14,
                      ),
                    ),
                    TextButton(
                      onPressed: _isResendingOtp ? null : _handleResendOtp,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      child: _isResendingOtp
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(textColor),
                              ),
                            )
                          : Text(
                              'Resend OTP',
                              style: TextStyle(
                                color: textColor,
                                fontSize: isMobile ? 13 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 12 : 16),
                // Back to login
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Back to Login',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.8),
                      fontSize: isMobile ? 14 : 15,
                    ),
                  ),
                ),
              ],
            ),
        );
  }
}

