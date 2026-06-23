import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/rbac.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/customers/customers_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/orders/order_form_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/payments/payments_screen.dart';
import '../screens/production/production_screen.dart';
import '../screens/recipes/recipes_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/users/users_screen.dart';
import '../widgets/layout/app_shell.dart';
import 'route_branches.dart';

class AppRouter {
  static GoRouter create(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: auth,
      redirect: (context, state) {
        if (!auth.isInitialized) return null;

        final isLoggedIn = auth.isAuthenticated;
        final location = state.matchedLocation;
        final isLogin = location == '/login';

        if (!isLoggedIn && !isLogin) return '/login';
        if (isLoggedIn && isLogin) return '/dashboard';

        if (isLoggedIn) {
          final user = auth.user;
          if (user != null) {
            final module = _moduleFromPath(location);
            if (module != null && !Rbac.canRead(user.role, module)) {
              return '/dashboard';
            }
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AppShell(navigationShell: navigationShell);
          },
          branches: [
            _branch('/dashboard', const DashboardScreen()),
            _branch('/users', const UsersScreen()),
            _branch('/customers', const CustomersScreen()),
            _branch(
              '/orders',
              const OrdersScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: OrderFormScreen()),
                ),
              ],
            ),
            _branch('/recipes', const RecipesScreen()),
            _branch('/inventory', const InventoryScreen()),
            _branch('/production', const ProductionScreen()),
            _branch('/payments', const PaymentsScreen()),
            _branch('/reports', const ReportsScreen()),
            _branch('/settings', const SettingsScreen()),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Halaman tidak ditemukan: ${state.uri}')),
      ),
    );
  }

  static StatefulShellBranch _branch(
    String path,
    Widget screen, {
    List<RouteBase> routes = const [],
  }) {
    return StatefulShellBranch(
      routes: [
        GoRoute(
          path: path,
          pageBuilder: (context, state) => NoTransitionPage(child: screen),
          routes: routes,
        ),
      ],
    );
  }

  static AppModule? _moduleFromPath(String path) {
    return RouteBranches.moduleAt(RouteBranches.indexForPath(path) ?? -1);
  }
}
