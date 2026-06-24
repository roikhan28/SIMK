import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/rbac.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/formatters.dart';
import '../../widgets/common/page_header.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Ingredient> _ingredients = [];
  bool _loading = true;
  bool _showLowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await context.read<AuthProvider>().dataService.getIngredients();
    if (mounted) setState(() { _ingredients = data; _loading = false; });
  }

  List<Ingredient> get _filtered {
    if (!_showLowStockOnly) return _ingredients;
    return _ingredients.where((i) => i.isLowStock).toList();
  }

  int get _lowStockCount => _ingredients.where((i) => i.isLowStock).length;

  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthProvider, UserRole?>((a) => a.user?.role);
    if (role == null) return const SizedBox.shrink();

    final canUpdate = Rbac.canUpdate(role, AppModule.inventory);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Inventori',
            subtitle: 'Monitoring stok bahan baku real-time',
            action: canUpdate
                ? ElevatedButton.icon(
                    onPressed: () => _showRestockDialog(context),
                    icon: const Icon(Icons.add_box_outlined, size: 20),
                    label: const Text('Restock'),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          if (_lowStockCount > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
                  const SizedBox(width: 12),
                  Expanded(child: Text('$_lowStockCount bahan mencapai stok minimum')),
                  FilterChip(
                    label: const Text('Tampilkan saja'),
                    selected: _showLowStockOnly,
                    onSelected: (v) => setState(() => _showLowStockOnly = v),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final ing = _filtered[i];
                        final stockPercent = (ing.stock / (ing.minStock * 2)).clamp(0.0, 1.0);

                        return ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: ing.isLowStock
                                  ? AppTheme.warning.withValues(alpha: 0.15)
                                  : AppTheme.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.inventory_2,
                              color: ing.isLowStock ? AppTheme.warning : AppTheme.success,
                            ),
                          ),
                          title: Text(ing.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Min: ${ing.minStock} ${ing.unit} • Harga: ${formatCurrency(ing.price)}/${ing.unit}'),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: stockPercent,
                                  backgroundColor: Colors.grey.shade200,
                                  color: ing.isLowStock ? AppTheme.warning : AppTheme.primary,
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${ing.stock} ${ing.unit}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: ing.isLowStock ? AppTheme.warning : AppTheme.textPrimary,
                                ),
                              ),
                              if (ing.isLowStock)
                                const Text('Stok rendah', style: TextStyle(fontSize: 11, color: AppTheme.warning)),
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

  void _showRestockDialog(BuildContext context) {
    Ingredient? selected = _ingredients.isNotEmpty ? _ingredients.first : null;
    final quantityController = TextEditingController();
    final notesController = TextEditingController();
    var saving = false;
    final messenger = ScaffoldMessenger.of(context);
    final dataService = context.read<AuthProvider>().dataService;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Restock Bahan'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Ingredient>(
                    key: ValueKey(selected?.id),
                    initialValue: selected,
                    decoration: const InputDecoration(labelText: 'Pilih Bahan'),
                    items: _ingredients
                        .map((i) => DropdownMenuItem(
                              value: i,
                              child: Text('${i.name} (${i.stock} ${i.unit})'),
                            ))
                        .toList(),
                    onChanged: saving
                        ? null
                        : (value) => setDialogState(() => selected = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: quantityController,
                    enabled: !saving,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Jumlah tambahan',
                      suffixText: selected?.unit,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    enabled: !saving,
                    decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
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
                onPressed: saving || selected == null
                    ? null
                    : () async {
                        final quantity = double.tryParse(quantityController.text.replaceAll(',', '.'));
                        if (quantity == null || quantity <= 0) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Masukkan jumlah restock yang valid')),
                          );
                          return;
                        }

                        setDialogState(() => saving = true);
                        try {
                          final updated = await dataService.restockIngredient(
                                selected!.id,
                                quantity,
                                notes: notesController.text.trim(),
                              );
                          if (!mounted) return;
                          setState(() {
                            final index = _ingredients.indexWhere((i) => i.id == updated.id);
                            if (index >= 0) _ingredients[index] = updated;
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Stok ${updated.name} diperbarui ke ${updated.stock} ${updated.unit}'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        } catch (e) {
                          setDialogState(() => saving = false);
                          messenger.showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }
}
