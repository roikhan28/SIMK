import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/rbac.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/formatters.dart';
import '../../widgets/common/page_header.dart';
import '../../widgets/common/status_badge.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Payment> _payments = [];
  List<Order> _orders = [];
  List<Order> _pendingOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final service = context.read<AuthProvider>().dataService;
    final payments = await service.getPayments();
    final orders = await service.getOrders();
    if (mounted) {
      setState(() {
        _payments = payments;
        _orders = orders;
        _pendingOrders = orders.where((o) => o.paymentStatus == 'pending').toList();
        _loading = false;
      });
    }
  }

  Order? _findOrderForPayment(Payment payment) {
    for (final order in _orders) {
      if (order.id == payment.orderId) return order;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthProvider, UserRole?>((a) => a.user?.role);
    if (role == null) return const SizedBox.shrink();

    final canCreate = Rbac.canCreate(role, AppModule.payments);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Pembayaran',
            subtitle: 'Input pembayaran dan generate invoice',
            action: canCreate
                ? ElevatedButton.icon(
                    onPressed: _pendingOrders.isEmpty ? null : () => _showPaymentDialog(context),
                    icon: const Icon(Icons.add_card, size: 20),
                    label: const Text('Input Pembayaran'),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Riwayat (${_payments.length})'),
              Tab(text: 'Pending (${_pendingOrders.length})'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _PaymentHistory(
                        payments: _payments,
                        onInvoice: (payment) {
                          final order = _findOrderForPayment(payment);
                          _showInvoice(context, order: order, payment: payment);
                        },
                      ),
                      _PendingOrders(orders: _pendingOrders, canPay: canCreate, onPay: _showPaymentDialog),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPaymentDialog(BuildContext context, {Order? order}) async {
    Order? selectedOrder = order;
    final methodController = TextEditingController(text: 'Transfer Bank');
    var saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Input Pembayaran'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (order == null)
                    DropdownButtonFormField<Order>(
                      value: selectedOrder,
                      decoration: const InputDecoration(labelText: 'Pilih Pesanan'),
                      items: _pendingOrders
                          .map((o) => DropdownMenuItem(
                                value: o,
                                child: Text('${o.orderNumber} • ${formatCurrency(o.totalAmount)}'),
                              ))
                          .toList(),
                      onChanged: saving ? null : (v) => setDialogState(() => selectedOrder = v),
                    )
                  else ...[
                    Text('Pesanan: ${order.orderNumber}'),
                    Text('Total: ${formatCurrency(order.totalAmount)}'),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: methodController,
                    enabled: !saving,
                    decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: saving || selectedOrder == null
                    ? null
                    : () async {
                        setDialogState(() => saving = true);
                        try {
                          final payment = await context.read<AuthProvider>().dataService.createPayment(
                                orderId: selectedOrder!.id,
                                method: methodController.text.trim(),
                              );
                          if (!mounted) return;
                          setState(() {
                            _payments.insert(0, payment);
                            _pendingOrders.removeWhere((o) => o.id == selectedOrder!.id);
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          _showInvoice(context, order: selectedOrder, payment: payment);
                        } catch (e) {
                          setDialogState(() => saving = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Konfirmasi & Invoice'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showInvoice(BuildContext context, {Order? order, Payment? payment}) {
    final buffer = StringBuffer('SIMK - Sistem Informasi Manajemen Katering\n\n');
    if (order != null) {
      buffer
        ..writeln('No. Pesanan: ${order.orderNumber}')
        ..writeln('Pelanggan: ${order.customerName}')
        ..writeln('Tanggal: ${formatDate(order.orderDate)}')
        ..writeln()
        ..writeln('Item:');
      for (final item in order.items) {
        buffer.writeln('- ${item.recipeName} x${item.portions} = ${formatCurrency(item.subtotal)}');
      }
      buffer
        ..writeln()
        ..writeln('Total: ${formatCurrency(order.totalAmount)}');
    } else if (payment != null) {
      buffer
        ..writeln('No. Pesanan: ${payment.orderNumber}')
        ..writeln('Pelanggan: ${payment.customerName}')
        ..writeln('Metode: ${payment.method}')
        ..writeln('Total: ${formatCurrency(payment.amount)}');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Invoice'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SIMK - Sistem Informasi Manajemen Katering', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            if (order != null) ...[
              Text('No. Pesanan: ${order.orderNumber}'),
              Text('Pelanggan: ${order.customerName}'),
              Text('Tanggal: ${formatDate(order.orderDate)}'),
              const SizedBox(height: 12),
              ...order.items.map((i) => Text('${i.recipeName} x${i.portions} — ${formatCurrency(i.subtotal)}')),
              const Divider(),
              Text('Total: ${formatCurrency(order.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ] else if (payment != null) ...[
              Text('No. Pesanan: ${payment.orderNumber}'),
              Text('Pelanggan: ${payment.customerName}'),
              Text('Metode: ${payment.method}'),
              Text('Total: ${formatCurrency(payment.amount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ] else
              const Text('Invoice berhasil digenerate.'),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: buffer.toString()));
              if (ctx.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invoice disalin ke clipboard')),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Salin'),
          ),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }
}

class _PaymentHistory extends StatelessWidget {
  const _PaymentHistory({required this.payments, required this.onInvoice});

  final List<Payment> payments;
  final void Function(Payment payment) onInvoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView.separated(
        itemCount: payments.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final p = payments[i];
          return ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.payments, color: AppTheme.success),
            ),
            title: Text(p.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${p.customerName} • ${p.method} • ${formatDateTime(p.paidAt)}'),
            isThreeLine: true,
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(p.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                StatusBadge.payment(p.status),
              ],
            ),
            onTap: () => onInvoice(p),
          );
        },
      ),
    );
  }
}

class _PendingOrders extends StatelessWidget {
  const _PendingOrders({required this.orders, required this.canPay, required this.onPay});

  final List<Order> orders;
  final bool canPay;
  final void Function(BuildContext, {Order? order}) onPay;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Card(
        child: Center(child: Text('Tidak ada pembayaran pending', style: TextStyle(color: AppTheme.textSecondary))),
      );
    }

    return Card(
      child: ListView.separated(
        itemCount: orders.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final o = orders[i];
          return ListTile(
            title: Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${o.customerName} • ${formatDate(o.orderDate)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(formatCurrency(o.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                if (canPay) ...[
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => onPay(context, order: o),
                    child: const Text('Bayar'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
