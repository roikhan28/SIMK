import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/screen_load.dart';
import '../../core/rbac.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/formatters.dart';
import '../../widgets/common/load_state_view.dart';
import '../../widgets/common/page_header.dart';
import '../../widgets/common/stat_card.dart';
import 'admin_revenue_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final err = await runScreenLoad(() async {
      final stats = await auth.dataService.getDashboard(
        user.role,
        force: _stats != null,
      );
      if (!mounted || auth.user == null) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    });

    if (err != null && mounted) {
      setState(() {
        _error = err;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, User?>((auth) => auth.user);
    if (user == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _loading = true);
        await _load();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Dashboard',
              subtitle: 'Selamat datang, ${user.name} (${user.role.label})',
            ),
            const SizedBox(height: 24),
            LoadStateView(
              loading: _loading,
              error: _error,
              onRetry: _load,
              child: _stats == null
                  ? const SizedBox.shrink()
                  : switch (user.role) {
                      UserRole.admin => _AdminDashboard(stats: _stats!),
                      UserRole.kasir => _KasirDashboard(stats: _stats!),
                      UserRole.staffProduksi => _ProduksiDashboard(stats: _stats!),
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatCardGrid(
          children: [
            StatCard(
              title: 'Total Pesanan',
              value: '${stats.totalOrders}',
              icon: Icons.receipt_long_rounded,
            ),
            StatCard(
              title: 'Total Pendapatan',
              value: formatCurrency(stats.totalRevenue),
              icon: Icons.attach_money_rounded,
              color: AppTheme.secondary,
            ),
            StatCard(
              title: 'Stok Minimum',
              value: '${stats.lowStockCount}',
              icon: Icons.warning_amber_rounded,
              color: stats.lowStockCount > 0 ? AppTheme.warning : AppTheme.success,
              subtitle: 'Bahan perlu restock',
            ),
            StatCard(
              title: 'Produksi Hari Ini',
              value: '${stats.todayProduction}',
              icon: Icons.restaurant_rounded,
              color: AppTheme.primaryLight,
            ),
          ],
        ),
        const SizedBox(height: 24),
        AdminRevenueChart(values: stats.revenueChart),
      ],
    );
  }
}

class _KasirDashboard extends StatelessWidget {
  const _KasirDashboard({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return StatCardGrid(
      children: [
        StatCard(
          title: 'Pesanan Aktif',
          value: '${stats.activeOrders}',
          icon: Icons.pending_actions_rounded,
          color: Colors.blue,
        ),
        StatCard(
          title: 'Pembayaran Pending',
          value: '${stats.pendingPayments}',
          icon: Icons.payments_rounded,
          color: AppTheme.warning,
        ),
        StatCard(
          title: 'Pesanan Hari Ini',
          value: '${stats.todayOrders}',
          icon: Icons.today_rounded,
          color: AppTheme.primary,
        ),
      ],
    );
  }
}

class _ProduksiDashboard extends StatelessWidget {
  const _ProduksiDashboard({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return StatCardGrid(
      children: [
        StatCard(
          title: 'Jadwal Produksi Hari Ini',
          value: '${stats.todayProduction}',
          icon: Icons.calendar_today_rounded,
          color: AppTheme.primary,
        ),
        StatCard(
          title: 'Pesanan Diproses',
          value: '${stats.processingOrders}',
          icon: Icons.kitchen_rounded,
          color: AppTheme.warning,
        ),
      ],
    );
  }
}
