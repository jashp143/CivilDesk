import 'package:flutter/material.dart';

enum ToastType {
  success,
  error,
  info,
  warning,
}

class Toast {
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    // Hide existing toast if visible
    if (_isVisible) {
      hide();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.shortestSide < 600;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600 && 
                     MediaQuery.of(context).size.shortestSide < 1024;

    // Determine colors based on type
    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;
    IconData defaultIcon;

    switch (type) {
      case ToastType.success:
        backgroundColor = isDark
            ? const Color(0xFF10B981)
            : const Color(0xFFD1FAE5);
        foregroundColor = isDark
            ? Colors.white
            : const Color(0xFF065F46);
        borderColor = const Color(0xFF10B981).withValues(alpha: 0.2);
        defaultIcon = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        backgroundColor = isDark
            ? const Color(0xFFEF4444)
            : const Color(0xFFFEE2E2);
        foregroundColor = isDark
            ? Colors.white
            : const Color(0xFF991B1B);
        borderColor = const Color(0xFFEF4444).withValues(alpha: 0.2);
        defaultIcon = Icons.error_rounded;
        break;
      case ToastType.warning:
        backgroundColor = isDark
            ? const Color(0xFFF59E0B)
            : const Color(0xFFFEF3C7);
        foregroundColor = isDark
            ? Colors.white
            : const Color(0xFF92400E);
        borderColor = const Color(0xFFF59E0B).withValues(alpha: 0.2);
        defaultIcon = Icons.warning_rounded;
        break;
      case ToastType.info:
      default:
        backgroundColor = isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surface;
        foregroundColor = colorScheme.onSurface;
        borderColor = colorScheme.outline.withValues(alpha: 0.2);
        defaultIcon = Icons.info_rounded;
        break;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        borderColor: borderColor,
        icon: icon ?? defaultIcon,
        isMobile: isMobile,
        isTablet: isTablet,
        onDismiss: hide,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isVisible = true;

    // Auto dismiss after duration
    Future.delayed(duration, () {
      if (_isVisible) {
        hide();
      }
    });
  }

  static void hide() {
    if (_overlayEntry != null && _isVisible) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isVisible = false;
    }
  }

  // Convenience methods
  static void success(BuildContext context, String message, {Duration? duration}) {
    show(context, message: message, type: ToastType.success, duration: duration ?? const Duration(seconds: 3));
  }

  static void error(BuildContext context, String message, {Duration? duration}) {
    show(context, message: message, type: ToastType.error, duration: duration ?? const Duration(seconds: 4));
  }

  static void info(BuildContext context, String message, {Duration? duration}) {
    show(context, message: message, type: ToastType.info, duration: duration ?? const Duration(seconds: 3));
  }

  static void warning(BuildContext context, String message, {Duration? duration}) {
    show(context, message: message, type: ToastType.warning, duration: duration ?? const Duration(seconds: 3));
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final IconData icon;
  final bool isMobile;
  final bool isTablet;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.icon,
    required this.isMobile,
    required this.isTablet,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = widget.isMobile;
    final isTablet = widget.isTablet;

    // Responsive sizing
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final verticalPadding = isMobile ? 16.0 : 24.0;
    final maxWidth = isMobile ? double.infinity : (isTablet ? 500.0 : 600.0);
    final iconSize = isMobile ? 20.0 : 22.0;
    final fontSize = isMobile ? 14.0 : 15.0;
    final borderRadius = isMobile ? 12.0 : 14.0;

    return Positioned(
      bottom: verticalPadding,
      right: horizontalPadding,
      left: isMobile ? horizontalPadding : null,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  minWidth: isMobile ? 0 : 300,
                ),
                margin: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: widget.borderColor,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: widget.foregroundColor.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: _dismiss,
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16.0 : 20.0,
                      vertical: isMobile ? 14.0 : 16.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.icon,
                          color: widget.foregroundColor,
                          size: iconSize,
                        ),
                        SizedBox(width: isMobile ? 12.0 : 14.0),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: widget.foregroundColor,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: isMobile ? 8.0 : 12.0),
                        GestureDetector(
                          onTap: _dismiss,
                          child: Icon(
                            Icons.close_rounded,
                            color: widget.foregroundColor.withValues(alpha: 0.6),
                            size: isMobile ? 18.0 : 20.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

