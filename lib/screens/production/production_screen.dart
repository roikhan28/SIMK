import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/rbac.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/formatters.dart';
import '../../widgets/common/page_header.dart';
import '../../widgets/common/status_badge.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  List<ProductionSchedule> _schedules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await context.read<AuthProvider>().dataService.getProductions();
    if (mounted) setState(() { _schedules = data; _loading = false; });
  }

  Future<void> _updateStatus(ProductionSchedule schedule, String newStatus) async {
    try {
      final updated = await context.read<AuthProvider>().dataService.updateProductionStatus(
            schedule.id,
            newStatus,
          );
      if (!mounted) return;
      setState(() {
        final index = _schedules.indexWhere((s) => s.id == schedule.id);
        if (index >= 0) _schedules[index] = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status diperbarui ke ${_statusLabel(newStatus)}'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  String _statusLabel(String status) {
    return switch (status) {
      'completed' => 'Selesai',
      'in_progress' => 'Berjalan',
      'scheduled' => 'Terjadwal',
      _ => status,
    };
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthProvider, UserRole?>((a) => a.user?.role);
    if (role == null) return const SizedBox.shrink();

    final canUpdate = Rbac.canUpdate(role, AppModule.production);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Produksi',
            subtitle: 'Jadwal produksi dan update status pesanan',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _schedules.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final s = _schedules[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.recipeName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${s.orderNumber} • ${s.portions} porsi',
                                          style: const TextStyle(color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusBadge.production(s.status),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 16, color: AppTheme.textSecondary),
                                  const SizedBox(width: 6),
                                  Text('Jadwal: ${formatDateTime(s.scheduledDate)}'),
                                  if (s.assignedTo.isNotEmpty) ...[
                                    const SizedBox(width: 16),
                                    const Icon(Icons.person_outline, size: 16, color: AppTheme.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(s.assignedTo),
                                  ],
                                ],
                              ),
                              if (canUpdate) ...[
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if (s.status == 'scheduled')
                                      OutlinedButton(
                                        onPressed: () => _updateStatus(s, 'in_progress'),
                                        child: const Text('Mulai Produksi'),
                                      ),
                                    if (s.status == 'in_progress')
                                      ElevatedButton(
                                        onPressed: () => _updateStatus(s, 'completed'),
                                        child: const Text('Selesai'),
                                      ),
                                    OutlinedButton.icon(
                                      onPressed: () => _showRecipeDetail(context, s),
                                      icon: const Icon(Icons.menu_book_outlined, size: 18),
                                      label: const Text('Lihat Resep'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRecipeDetail(BuildContext context, ProductionSchedule schedule) async {
    final service = context.read<AuthProvider>().dataService;
    RecipeDetail? detail;

    try {
      final recipes = await service.getRecipes();
      final matches = recipes.where((r) => r.name == schedule.recipeName);
      if (matches.isNotEmpty) {
        detail = await service.getRecipeDetail(matches.first.id);
      }
    } catch (_) {}

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Resep: ${schedule.recipeName}'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Porsi produksi: ${schedule.portions}'),
                Text('Pesanan: ${schedule.orderNumber}'),
                if (detail != null) ...[
                  if (detail.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Deskripsi: ${detail.description}'),
                  ],
                  if (detail.ingredients.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Bahan:', style: TextStyle(fontWeight: FontWeight.w600)),
                    ...detail.ingredients.map(
                      (i) => Text('• ${i.ingredientName}: ${i.quantity} ${i.unit}'),
                    ),
                  ],
                  if (detail.steps.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Langkah:', style: TextStyle(fontWeight: FontWeight.w600)),
                    ...detail.steps.map(
                      (s) => Text('${s.stepNumber}. ${s.instruction}'),
                    ),
                  ],
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('Detail bahan dan langkah belum tersedia untuk resep ini.'),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }
}
