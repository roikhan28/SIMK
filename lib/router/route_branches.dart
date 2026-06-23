import '../core/rbac.dart';

/// Fixed branch order for [StatefulShellRoute.indexedStack] — one branch per module.
class RouteBranches {
  RouteBranches._();

  static const branchModules = [
    AppModule.dashboard,
    AppModule.users,
    AppModule.customers,
    AppModule.orders,
    AppModule.recipes,
    AppModule.inventory,
    AppModule.production,
    AppModule.payments,
    AppModule.reports,
    AppModule.settings,
  ];

  static int indexFor(AppModule module) => branchModules.indexOf(module);

  static AppModule? moduleAt(int index) {
    if (index < 0 || index >= branchModules.length) return null;
    return branchModules[index];
  }

  static int? indexForPath(String path) {
    for (var i = 0; i < branchModules.length; i++) {
      final route = branchModules[i].route;
      if (path == route || path.startsWith('$route/')) return i;
    }
    return null;
  }
}
