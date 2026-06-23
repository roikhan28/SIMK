import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/rbac.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../router/route_branches.dart';

const double _kRailWidth = 72;
const double _kExpandedWidth = 220;

void _goToModule(StatefulNavigationShell shell, AppModule module) {
  shell.goBranch(RouteBranches.indexFor(module), initialLocation: false);
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, User?>((auth) => auth.user);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final modules = Rbac.accessibleModules(user.role);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    if (!isWide) {
      return _MobileShell(
        modules: modules,
        user: user,
        navigationShell: navigationShell,
      );
    }

    return _DesktopShell(
      modules: modules,
      user: user,
      navigationShell: navigationShell,
    );
  }
}

class _DesktopShell extends StatefulWidget {
  const _DesktopShell({
    required this.modules,
    required this.user,
    required this.navigationShell,
  });

  final List<AppModule> modules;
  final User user;
  final StatefulNavigationShell navigationShell;

  @override
  State<_DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<_DesktopShell> {
  bool _expanded = true;

  void _collapse() => setState(() => _expanded = false);

  void _toggle() => setState(() => _expanded = !_expanded);

  bool _isSelected(AppModule module) {
    return RouteBranches.indexFor(module) == widget.navigationShell.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = _expanded ? _kExpandedWidth : _kRailWidth;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(left: _kRailWidth),
              child: RepaintBoundary(child: widget.navigationShell),
            ),
          ),
          if (_expanded)
            Positioned(
              left: _kExpandedWidth,
              top: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _collapse,
              ),
            ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: sidebarWidth,
            child: Material(
              elevation: _expanded ? 4 : 0,
              color: AppTheme.surface,
              clipBehavior: Clip.hardEdge,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: Color(0xFFE8E4DE))),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 72,
                      width: sidebarWidth,
                      child: _expanded
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  _logo(),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'SIMK',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Center(child: _logo()),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: widget.modules.length,
                        itemBuilder: (context, index) {
                          final module = widget.modules[index];
                          return _SidebarTile(
                            expanded: _expanded,
                            icon: module.icon,
                            label: module.label,
                            selected: _isSelected(module),
                            onTap: () {
                              _goToModule(widget.navigationShell, module);
                              if (_expanded) _collapse();
                            },
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    _SidebarFooter(
                      expanded: _expanded,
                      user: widget.user,
                      onToggle: _toggle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logo() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.restaurant_menu, color: Colors.white),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({
    required this.expanded,
    required this.user,
    required this.onToggle,
  });

  final bool expanded;
  final User user;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.role.label,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: expanded ? null : _kRailWidth,
            child: IconButton(
              icon: Icon(expanded ? Icons.chevron_left : Icons.chevron_right),
              onPressed: onToggle,
              tooltip: expanded ? 'Ciutkan' : 'Perluas',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.expanded,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final bool expanded;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primary : AppTheme.textSecondary;
    final bg = selected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: expanded ? 8 : 4, vertical: 2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 48,
            width: expanded ? null : _kRailWidth - 8,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: selected ? AppTheme.primary : AppTheme.textPrimary,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(child: Icon(icon, color: color, size: 22)),
          ),
        ),
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.modules,
    required this.user,
    required this.navigationShell,
  });

  final List<AppModule> modules;
  final User user;
  final StatefulNavigationShell navigationShell;

  int get _navBarIndex {
    final current = navigationShell.currentIndex;
    for (var i = 0; i < modules.length; i++) {
      if (RouteBranches.indexFor(modules[i]) == current) return i;
    }
    return 0;
  }

  AppModule get _currentModule => modules[_navBarIndex.clamp(0, modules.length - 1)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentModule.label),
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 12, color: AppTheme.primary),
              ),
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                await context.read<AuthProvider>().logout();
              } else {
                final idx = RouteBranches.indexForPath(value);
                if (idx != null) {
                  navigationShell.goBranch(idx, initialLocation: false);
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(user.role.label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              ...modules.map((m) => PopupMenuItem(
                    value: m.route,
                    child: Row(
                      children: [
                        Icon(m.icon, size: 20),
                        const SizedBox(width: 12),
                        Flexible(child: Text(m.label, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  )),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Keluar'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: modules.length > 5
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: AppTheme.primary),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(user.role.label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  ...modules.map((m) {
                    final selected = RouteBranches.indexFor(m) == navigationShell.currentIndex;
                    return ListTile(
                      leading: Icon(m.icon),
                      title: Text(m.label),
                      selected: selected,
                      onTap: () {
                        Navigator.pop(context);
                        _goToModule(navigationShell, m);
                      },
                    );
                  }),
                ],
              ),
            )
          : null,
      body: navigationShell,
      bottomNavigationBar: modules.length <= 5
          ? NavigationBar(
              selectedIndex: _navBarIndex,
              onDestinationSelected: (i) => _goToModule(navigationShell, modules[i]),
              destinations: modules
                  .map((m) => NavigationDestination(icon: Icon(m.icon), label: m.label))
                  .toList(),
            )
          : null,
    );
  }
}
