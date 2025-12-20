import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import 'cached_profile_image.dart';

class CollapsibleSidebar extends StatefulWidget {
  final Widget child;
  final List<SidebarItem> items;
  final SidebarItem? logoutItem;
  final String currentRoute;
  final Widget? title;
  final List<Widget>? actions;
  final bool showBackButton;

  const CollapsibleSidebar({
    super.key,
    required this.child,
    required this.items,
    this.logoutItem,
    required this.currentRoute,
    this.title,
    this.actions,
    this.showBackButton = false,
  });

  @override
  State<CollapsibleSidebar> createState() => _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends State<CollapsibleSidebar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    // Start collapsed by default on all screen sizes
    _animationController.value = 0.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  bool _isMobile(BuildContext context) {
    // Use shortestSide for better device detection regardless of orientation
    // Mobile devices typically have shortestSide < 600px
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  bool _isTablet(BuildContext context) {
    // Tablets typically have shortestSide >= 600px
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600 && shortestSide < 1024;
  }

  bool _isDesktop(BuildContext context) {
    // Desktop typically has shortestSide >= 1024px
    return MediaQuery.of(context).size.shortestSide >= 1024;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    if (isMobile) {
      // Mobile layout with drawer
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          titleSpacing: 16,
          toolbarHeight: kToolbarHeight + 4,
          title: DefaultTextStyle(
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              height: 1.2,
              color: colorScheme.onSurface,
            ) ?? TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              height: 1.2,
              color: colorScheme.onSurface,
            ),
            child: widget.title ?? const SizedBox.shrink(),
          ),
          actions: widget.actions,
          leading: widget.showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  iconSize: 24,
                  padding: const EdgeInsets.all(8),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                )
              : IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  iconSize: 24,
                  padding: const EdgeInsets.all(8),
                  onPressed: _openDrawer,
                  tooltip: 'Menu',
                ),
          automaticallyImplyLeading: false,
        ),
        drawer: Drawer(
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              _buildAdminInfoHeader(context),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount:
                      widget.items.length + (widget.logoutItem != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (widget.logoutItem != null &&
                        index == widget.items.length) {
                      // Logout item at the end
                      return Column(
                        children: [
                          Divider(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                          _MobileDrawerMenuItem(
                            item: widget.logoutItem!,
                            isActive: false,
                            isLogout: true,
                            onTap: () {
                              Navigator.pop(context); // Close drawer
                              widget.logoutItem!.onTap();
                            },
                          ),
                        ],
                      );
                    }
                    final item = widget.items[index];
                    final isActive = widget.currentRoute == item.route;
                    return _MobileDrawerMenuItem(
                      item: item,
                      isActive: isActive,
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        item.onTap();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        body: widget.child,
      );
    }

    // Desktop/Tablet layout with collapsible sidebar (always visible)
    return Row(
      children: [
        // Sidebar (full height, always visible)
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: Theme.of(context).brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
              child: Container(
                width: _isExpanded ? 250 : 70,
                constraints: BoxConstraints(
                  maxWidth: _isExpanded ? 250 : 70,
                  minWidth: _isExpanded ? 250 : 70,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(2, 0),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Sidebar header (meets appbar at right angle, no SafeArea on top)
                    Container(
                      height: kToolbarHeight + (_isTablet(context) || _isDesktop(context) ? 16: MediaQuery.of(context).padding.top),
                      padding: EdgeInsets.only(top: (_isTablet(context) || _isDesktop(context)) ? 16 : MediaQuery.of(context).padding.top),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Container(
                        height: kToolbarHeight,
                        padding: EdgeInsets.symmetric(
                          horizontal: _isExpanded ? 12 : 8,
                        ),
                        child: Row(
                          mainAxisAlignment: _isExpanded
                              ? MainAxisAlignment.spaceBetween
                              : MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (_isExpanded)
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text(
                                    'Menu',
                                    style: Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      letterSpacing: 0.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: _toggleSidebar,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    _isExpanded ? Icons.chevron_left_rounded : Icons.menu_rounded,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Sidebar content (with SafeArea for bottom)
                    Expanded(
                      child: SafeArea(
                        top: false,
                        bottom: true,
                        child: Column(
                          children: [
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                            ),
                            // Menu items (scrollable)
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: _isExpanded ? 0 : 2,
                                ),
                                itemCount: widget.items.length,
                                itemBuilder: (context, index) {
                                  final item = widget.items[index];
                                  final isActive = widget.currentRoute == item.route;
                                  return _SidebarMenuItem(
                                    item: item,
                                    isExpanded: _isExpanded,
                                    isActive: isActive,
                                    animation: _expandAnimation,
                                  );
                                },
                              ),
                            ),
                            // Fixed Logout button at bottom
                            if (widget.logoutItem != null)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: _SidebarMenuItem(
                                  item: widget.logoutItem!,
                                  isExpanded: _isExpanded,
                                  isActive: false,
                                  animation: _expandAnimation,
                                  isLogout: true,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        // Main content area with app bar
        Expanded(
          child: Column(
            children: [
              // App Bar (meets sidebar at right angle, always visible)
              AnnotatedRegion<SystemUiOverlayStyle>(
                value: Theme.of(context).brightness == Brightness.light
                    ? SystemUiOverlayStyle.dark
                    : SystemUiOverlayStyle.light,
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  height: kToolbarHeight + ((_isTablet(context) || _isDesktop(context)) ? 16 : MediaQuery.of(context).padding.top),
                  padding: EdgeInsets.only(top: (_isTablet(context) || _isDesktop(context)) ? 16 : MediaQuery.of(context).padding.top),
                  child: Container(
                    height: kToolbarHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (widget.title != null)
                          Expanded(
                            child: DefaultTextStyle(
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                  ) ??
                                  TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                              child: widget.title!,
                            ),
                          ),
                        if (widget.actions != null) ...[
                          const SizedBox(width: 8),
                          ...widget.actions!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Main content (with SafeArea for bottom)
              Expanded(
                child: SafeArea(
                  top: false,
                  bottom: true,
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminInfoHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        
        String getUserName() {
          if (user == null) return 'Admin';
          final firstName = user['firstName'] as String? ?? '';
          final lastName = user['lastName'] as String? ?? '';
          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            return '${firstName.trim()} ${lastName.trim()}'.trim();
          }
          return user['email'] as String? ?? 'Admin';
        }

        String getUserInitials() {
          final userName = getUserName();
          if (userName.isEmpty || userName == 'Admin') return 'A';
          final parts = userName.trim().split(' ');
          if (parts.length >= 2) {
            return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
          }
          return userName[0].toUpperCase();
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white : Colors.black,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CachedProfileImage(
                          imageUrl: null,
                          fallbackInitials: getUserInitials(),
                          radius: 32,
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getUserName(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (user?['email'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                user!['email'] as String? ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : Colors.black.withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (user?['role'] != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.black.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isDark ? Colors.white : Colors.black,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  user!['role'] as String? ?? 'ADMIN',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SidebarMenuItem extends StatelessWidget {
  final SidebarItem item;
  final bool isExpanded;
  final bool isActive;
  final Animation<double> animation;
  final bool isLogout;

  const _SidebarMenuItem({
    required this.item,
    required this.isExpanded,
    required this.isActive,
    required this.animation,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final logoutColor = isLogout 
            ? colorScheme.error
            : (isActive ? colorScheme.primary : colorScheme.onSurfaceVariant);

        final isDark = theme.brightness == Brightness.dark;
        
        return Tooltip(
          message: isExpanded ? '' : item.title,
          preferBelow: false,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(12),
              hoverColor: isLogout 
                  ? colorScheme.error.withValues(alpha: isDark ? 0.15 : 0.08)
                  : (isActive 
                      ? colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1)
                      : colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.05)),
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: isExpanded ? 8 : 6, 
                  vertical: isLogout ? 6 : 2,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isExpanded ? 12 : 0,
                  vertical: isExpanded ? 12 : 10,
                ),
                decoration: BoxDecoration(
                  color: isActive && !isLogout
                      ? colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isActive && !isLogout
                      ? Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.5),
                          width: 1,
                        )
                      : null,
                  boxShadow: isActive && !isLogout
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: isExpanded 
                      ? MainAxisAlignment.start 
                      : MainAxisAlignment.center,
                  children: [
                    Container(
                      width: isExpanded ? 32 : 36,
                      height: isExpanded ? 32 : 36,
                      decoration: BoxDecoration(
                        color: isActive && !isLogout
                            ? colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.15)
                            : (isLogout
                                ? colorScheme.error.withValues(alpha: isDark ? 0.2 : 0.1)
                                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(8),
                        border: isActive && !isLogout
                            ? Border.all(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Icon(
                        item.icon,
                        color: logoutColor,
                        size: isExpanded ? 20 : 22,
                      ),
                    ),
                    if (isExpanded) ...[
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          item.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: logoutColor,
                            fontWeight: isActive || isLogout
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontSize: 14,
                            letterSpacing: 0.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MobileDrawerMenuItem extends StatelessWidget {
  final SidebarItem item;
  final bool isActive;
  final VoidCallback onTap;
  final bool isLogout;

  const _MobileDrawerMenuItem({
    required this.item,
    required this.isActive,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final logoutColor = isLogout 
        ? colorScheme.error
        : (isActive ? colorScheme.primary : colorScheme.onSurfaceVariant);
    final isDark = theme.brightness == Brightness.dark;
    
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive && !isLogout
              ? colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.15)
              : (isLogout
                  ? colorScheme.error.withValues(alpha: isDark ? 0.2 : 0.1)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
          border: isActive && !isLogout
              ? Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: Icon(
          item.icon,
          color: logoutColor,
          size: 22,
        ),
      ),
      title: Text(
        item.title,
        style: theme.textTheme.bodyLarge?.copyWith(
              color: logoutColor,
          fontWeight: isActive || isLogout
              ? FontWeight.w600
              : FontWeight.w500,
          letterSpacing: 0.1,
            ),
      ),
      selected: isActive && !isLogout,
      selectedTileColor: colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: onTap,
    );
  }
}

class SidebarItem {
  final String title;
  final IconData icon;
  final String route;
  final VoidCallback onTap;

  SidebarItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.onTap,
  });
}
