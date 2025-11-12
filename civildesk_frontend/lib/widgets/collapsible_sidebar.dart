import 'package:flutter/material.dart';

class CollapsibleSidebar extends StatefulWidget {
  final Widget child;
  final List<SidebarItem> items;
  final String currentRoute;
  final Widget? title;
  final List<Widget>? actions;

  const CollapsibleSidebar({
    super.key,
    required this.child,
    required this.items,
    required this.currentRoute,
    this.title,
    this.actions,
  });

  @override
  State<CollapsibleSidebar> createState() => _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends State<CollapsibleSidebar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

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
    // Start collapsed (default state)
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sidebar (full height)
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Container(
              width: _isExpanded ? 250 : 70,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Toggle button (at top, aligned with app bar)
                  Container(
                    height: kToolbarHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.black.withValues(alpha: 0.1),
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
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              'Menu',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                            ),
                          ),
                        IconButton(
                          icon: Icon(
                            _isExpanded ? Icons.chevron_left : Icons.menu,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: _toggleSidebar,
                          tooltip: _isExpanded ? 'Collapse' : 'Expand',
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Menu items
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
                ],
              ),
            );
          },
        ),
        // Main content area with app bar
        Expanded(
          child: Column(
            children: [
              // App Bar (meets sidebar at right angle)
              Container(
                height: kToolbarHeight,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    if (widget.title != null)
                      Expanded(
                        child: DefaultTextStyle(
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ) ?? const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                          child: widget.title!,
                        ),
                      ),
                    if (widget.actions != null) ...widget.actions!,
                  ],
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

  const _SidebarMenuItem({
    required this.item,
    required this.isExpanded,
    required this.isActive,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return InkWell(
          onTap: item.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).iconTheme.color,
                  size: 24,
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isActive
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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

