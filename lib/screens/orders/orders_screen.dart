import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/rbac.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/formatters.dart';
import '../../widgets/common/page_header.dart';
import '../../widgets/common/status_badge.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  OrderStatus? _filter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await context.read<AuthProvider>().dataService.getOrders();
    if (mounted) setState(() { _orders = data; _loading = false; });
  }

  List<Order> get _filtered {
    if (_filter == null) return _orders;
    return _orders.where((o) => o.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthProvider, UserRole?>((a) => a.user?.role);
    if (role == null) return const SizedBox.shrink();

    final canCreate = Rbac.canCreate(role, AppModule.orders);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Pesanan',
            subtitle: 'Kelola dan lacak status pesanan katering',
            action: canCreate
                ? ElevatedButton.icon(
                    onPressed: () => context.go('/orders/new'),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Input Pesanan'),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Semua'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                ...OrderStatus.values.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s.label),
                        selected: _filter == s,
                        onSelected: (_) => setState(() => _filter = s),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final order = _filtered[i];
                        return ListTile(
                          onTap: () => _showDetail(context, order),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.receipt_long, color: AppTheme.primary),
                          ),
                          title: Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${order.customerName} • ${formatDate(order.orderDate)} • ${order.items.length} menu',
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatCurrency(order.totalAmount),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              StatusBadge.order(order.status),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: controller,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  StatusBadge.order(order.status),
                ],
              ),
              const SizedBox(height: 8),
              Text('Pelanggan: ${order.customerName}'),
              Text('Tanggal: ${formatDateTime(order.orderDate)}'),
              Text('Pembayaran: ${order.paymentStatus}'),
              const Divider(height: 32),
              Text('Item Pesanan', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text('${item.recipeName} x${item.portions}')),
                        Text(formatCurrency(item.subtotal)),
                      ],
                    ),
                  )),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    formatCurrency(order.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
