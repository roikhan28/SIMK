import 'package:flutter/material.dart';

enum UserRole { admin, kasir, staffProduksi }

enum Permission { read, create, update, delete }

enum AppModule {
  dashboard,
  users,
  customers,
  orders,
  recipes,
  inventory,
  production,
  payments,
  reports,
  settings,
}

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.kasir:
        return 'Kasir';
      case UserRole.staffProduksi:
        return 'Staff Produksi';
    }
  }
}

extension AppModuleLabel on AppModule {
  String get label {
    switch (this) {
      case AppModule.dashboard:
        return 'Dashboard';
      case AppModule.users:
        return 'Pengguna';
      case AppModule.customers:
        return 'Pelanggan';
      case AppModule.orders:
        return 'Pesanan';
      case AppModule.recipes:
        return 'Resep';
      case AppModule.inventory:
        return 'Inventori';
      case AppModule.production:
        return 'Produksi';
      case AppModule.payments:
        return 'Pembayaran';
      case AppModule.reports:
        return 'Laporan';
      case AppModule.settings:
        return 'Pengaturan';
    }
  }

  String get route {
    switch (this) {
      case AppModule.dashboard:
        return '/dashboard';
      case AppModule.users:
        return '/users';
      case AppModule.customers:
        return '/customers';
      case AppModule.orders:
        return '/orders';
      case AppModule.recipes:
        return '/recipes';
      case AppModule.inventory:
        return '/inventory';
      case AppModule.production:
        return '/production';
      case AppModule.payments:
        return '/payments';
      case AppModule.reports:
        return '/reports';
      case AppModule.settings:
        return '/settings';
    }
  }

  IconData get icon {
    switch (this) {
      case AppModule.dashboard:
        return Icons.dashboard_rounded;
      case AppModule.users:
        return Icons.people_rounded;
      case AppModule.customers:
        return Icons.person_outline_rounded;
      case AppModule.orders:
        return Icons.receipt_long_rounded;
      case AppModule.recipes:
        return Icons.menu_book_rounded;
      case AppModule.inventory:
        return Icons.inventory_2_rounded;
      case AppModule.production:
        return Icons.restaurant_rounded;
      case AppModule.payments:
        return Icons.payments_rounded;
      case AppModule.reports:
        return Icons.assessment_rounded;
      case AppModule.settings:
        return Icons.settings_rounded;
    }
  }
}

class Rbac {
  static const Map<UserRole, Map<AppModule, Set<Permission>>> matrix = {
    UserRole.admin: {
      AppModule.dashboard: {Permission.read},
      AppModule.users: {Permission.read, Permission.create, Permission.update, Permission.delete},
      AppModule.customers: {Permission.read},
      AppModule.orders: {Permission.read, Permission.create, Permission.update, Permission.delete},
      AppModule.recipes: {Permission.read, Permission.create, Permission.update, Permission.delete},
      AppModule.inventory: {Permission.read, Permission.create, Permission.update, Permission.delete},
      AppModule.production: {Permission.read, Permission.create, Permission.update, Permission.delete},
      AppModule.payments: {Permission.read},
      AppModule.reports: {Permission.read, Permission.create, Permission.update, Permission.delete},
      AppModule.settings: {Permission.read, Permission.update},
    },
    UserRole.kasir: {
      AppModule.dashboard: {Permission.read},
      AppModule.customers: {Permission.read, Permission.create, Permission.update, Permission.delete},
      AppModule.orders: {Permission.read, Permission.create, Permission.update, Permission.delete},
      AppModule.recipes: {Permission.read},
      AppModule.inventory: {Permission.read},
      AppModule.production: {Permission.read},
      AppModule.payments: {Permission.read, Permission.create, Permission.update, Permission.delete},
      AppModule.settings: {Permission.read},
    },
    UserRole.staffProduksi: {
      AppModule.dashboard: {Permission.read},
      AppModule.orders: {Permission.read},
      AppModule.recipes: {Permission.read},
      AppModule.inventory: {Permission.read},
      AppModule.production: {Permission.read, Permission.update},
      AppModule.settings: {Permission.read},
    },
  };

  static List<AppModule> accessibleModules(UserRole role) {
    return AppModule.values
        .where((m) => matrix[role]?.containsKey(m) ?? false)
        .toList();
  }

  static bool can(UserRole role, AppModule module, Permission permission) {
    return matrix[role]?[module]?.contains(permission) ?? false;
  }

  static bool canRead(UserRole role, AppModule module) =>
      can(role, module, Permission.read);

  static bool canCreate(UserRole role, AppModule module) =>
      can(role, module, Permission.create);

  static bool canUpdate(UserRole role, AppModule module) =>
      can(role, module, Permission.update);

  static bool canDelete(UserRole role, AppModule module) =>
      can(role, module, Permission.delete);
}
