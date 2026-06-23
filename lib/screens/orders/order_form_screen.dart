import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/formatters.dart';
import '../../widgets/common/page_header.dart';

class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderItemDraft {
  _OrderItemDraft({required this.recipe, required this.portions});

  final Recipe recipe;
  int portions;
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  List<Customer> _customers = [];
  List<Recipe> _recipes = [];
  Customer? _selectedCustomer;
  final List<_OrderItemDraft> _items = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = context.read<AuthProvider>().dataService;
    final customers = await service.getCustomers();
    final recipes = await service.getRecipes();
    if (mounted) {
      setState(() {
        _customers = customers;
        _recipes = recipes;
        _loading = false;
      });
    }
  }

  double get _total => _items.fold(0, (sum, i) => sum + i.recipe.price * i.portions);

  Future<void> _save() async {
    if (_selectedCustomer == null) {
      _showError('Pelanggan wajib dipilih');
      return;
    }
    if (_items.isEmpty) {
      _showError('Minimal satu menu harus dipilih');
      return;
    }
    if (_items.any((i) => i.portions <= 0)) {
      _showError('Porsi harus lebih besar dari nol');
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().dataService.createOrder(
            customerId: _selectedCustomer!.id,
            items: _items
                .map((i) => {
                      'recipe_id': i.recipe.id,
                      'portions': i.portions,
                    })
                .toList(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil disimpan'),
          backgroundColor: AppTheme.success,
        ),
      );
      context.go('/orders');
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showError(e.toString());
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (ctx) {
        Recipe? selected;
        final portionsController = TextEditingController(text: '1');
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Tambah Menu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Recipe>(
                  decoration: const InputDecoration(labelText: 'Menu'),
                  items: _recipes
                      .map((r) => DropdownMenuItem(value: r, child: Text('${r.name} (${formatCurrency(r.price)})')))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selected = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: portionsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Porsi'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () {
                  if (selected == null) return;
                  final portions = int.tryParse(portionsController.text) ?? 0;
                  if (portions <= 0) return;
                  setState(() => _items.add(_OrderItemDraft(recipe: selected!, portions: portions)));
                  Navigator.pop(ctx);
                },
                child: const Text('Tambah'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: 'Input Pesanan',
                  subtitle: 'Pilih pelanggan → menu → porsi → simpan',
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () => context.go('/orders'),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Simpan Pesanan'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 800;
                      final formCard = Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pelanggan', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<Customer>(
                                decoration: const InputDecoration(hintText: 'Pilih pelanggan'),
                                initialValue: _selectedCustomer,
                                items: _customers
                                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedCustomer = v),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Menu Pesanan', style: TextStyle(fontWeight: FontWeight.w600)),
                                  TextButton.icon(
                                    onPressed: _addItem,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Tambah Menu'),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: _items.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'Belum ada menu ditambahkan',
                                          style: TextStyle(color: AppTheme.textSecondary),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: _items.length,
                                        separatorBuilder: (_, _) => const Divider(),
                                        itemBuilder: (context, i) {
                                          final item = _items[i];
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.recipe.name,
                                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                                ),
                                                Text(
                                                  '${formatCurrency(item.recipe.price)} / porsi',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.remove_circle_outline),
                                                      onPressed: () {
                                                        if (item.portions > 1) {
                                                          setState(() => item.portions--);
                                                        }
                                                      },
                                                    ),
                                                    Text(
                                                      '${item.portions}',
                                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.add_circle_outline),
                                                      onPressed: () => setState(() => item.portions++),
                                                    ),
                                                    const Spacer(),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                                                      onPressed: () => setState(() => _items.removeAt(i)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );

                      final summaryCard = Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ringkasan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              const Divider(),
                              Expanded(
                                child: ListView(
                                  children: _items
                                      .map(
                                        (i) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${i.recipe.name} x${i.portions}',
                                                  style: const TextStyle(fontSize: 13),
                                                ),
                                              ),
                                              Text(
                                                formatCurrency(i.recipe.price * i.portions),
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  Text(
                                    formatCurrency(_total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 18, color: AppTheme.primary),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Sistem akan memvalidasi stok bahan dan membuat jadwal produksi saat disimpan.',
                                        style: TextStyle(fontSize: 12, color: AppTheme.primary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                      if (stacked) {
                        return Column(
                          children: [
                            Expanded(flex: 3, child: formCard),
                            const SizedBox(height: 16),
                            Expanded(flex: 2, child: summaryCard),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 2, child: formCard),
                          const SizedBox(width: 16),
                          Expanded(child: summaryCard),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
