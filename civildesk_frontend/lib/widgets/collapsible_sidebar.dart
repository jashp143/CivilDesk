import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          backgroundColor: Theme.of(context).colorScheme.background,
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 48,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Admin Panel',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
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
                            ).colorScheme.outline.withOpacity(0.2),
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
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    width: _isExpanded ? 250 : 70,
                    decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        right: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(2, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Toggle button (at top, aligned with app bar - right angle connection)
                        Container(
                          height: kToolbarHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                           color: Theme.of(context).colorScheme.surface,
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                          ),
                      child: Row(
                        mainAxisAlignment: _isExpanded
                            ? MainAxisAlignment.spaceBetween
                            : MainAxisAlignment.center,
                        children: [
                          if (_isExpanded)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                'Menu',
                                   style: Theme.of(context).textTheme.titleMedium
                                       ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                         color: Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                            ),
                          IconButton(
                            icon: Icon(
                              _isExpanded ? Icons.chevron_left : Icons.menu,
                                 color: Theme.of(context).colorScheme.onSurface,
                            ),
                            onPressed: _toggleSidebar,
                            tooltip: _isExpanded ? 'Collapse' : 'Expand',
                          ),
                        ],
                      ),
                    ),
                      Divider(
                        height: 1,
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.2),
                      ),
                    // Menu items (scrollable)
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
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
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.2),
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
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      height: kToolbarHeight + 8,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.12),
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
              ),
              // Main content
              Expanded(child: widget.child),
            ],
          ),
        ),
      ],
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
        
        return InkWell(
          onTap: item.onTap,
          hoverColor: isLogout 
              ? colorScheme.error.withOpacity(isDark ? 0.2 : 0.1)
              : colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: 8, 
              vertical: isLogout ? 8 : 4,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isActive && !isLogout
                  ? colorScheme.primary.withOpacity(isDark ? 0.25 : 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive && !isLogout
                  ? Border.all(color: colorScheme.primary, width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                Icon(item.icon, color: logoutColor, size: 24),
                if (isExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: logoutColor,
                        fontWeight: isActive || isLogout
                            ? FontWeight.w600
                            : FontWeight.normal,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
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
      leading: Icon(item.icon, color: logoutColor),
      title: Text(
        item.title,
        style: theme.textTheme.bodyLarge?.copyWith(
              color: logoutColor,
          fontWeight: isActive || isLogout
              ? FontWeight.w600
              : FontWeight.normal,
            ),
      ),
      selected: isActive && !isLogout,
      selectedTileColor: colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
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
