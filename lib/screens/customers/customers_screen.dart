import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/rbac.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/page_header.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Customer> _customers = [];
  List<Customer> _filtered = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await context.read<AuthProvider>().dataService.getCustomers();
    if (mounted) {
      setState(() {
        _customers = data;
        _filtered = data;
        _loading = false;
      });
    }
  }

  void _filter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _customers.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.phone.contains(q) ||
            c.email.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthProvider, UserRole?>((a) => a.user?.role);
    if (role == null) return const SizedBox.shrink();

    final canCreate = Rbac.canCreate(role, AppModule.customers);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Pelanggan',
            subtitle: 'Kelola data pelanggan dan riwayat pesanan',
            action: canCreate
                ? ElevatedButton.icon(
                    onPressed: () => _showForm(context),
                    icon: const Icon(Icons.person_add, size: 20),
                    label: const Text('Tambah Pelanggan'),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Cari nama, telepon, atau email...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const EmptyState(icon: Icons.people_outline, message: 'Tidak ada pelanggan ditemukan')
                    : Card(
                        child: ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final c = _filtered[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.secondary.withValues(alpha: 0.2),
                                child: const Icon(Icons.business, color: AppTheme.secondary, size: 20),
                              ),
                              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${c.phone}${c.email.isNotEmpty ? ' • ${c.email}' : ''}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text('${c.orderCount} pesanan', style: const TextStyle(fontSize: 11)),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  if (Rbac.canUpdate(role, AppModule.customers))
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      onPressed: () => _showForm(context, customer: c),
                                    ),
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

  void _showForm(BuildContext context, {Customer? customer}) {
    final isEdit = customer != null;
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final emailController = TextEditingController(text: customer?.email ?? '');
    final addressController = TextEditingController(text: customer?.address ?? '');
    var saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Pelanggan' : 'Tambah Pelanggan'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    enabled: !saving,
                    decoration: const InputDecoration(labelText: 'Nama'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    enabled: !saving,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Telepon'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    enabled: !saving,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email (opsional)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    enabled: !saving,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Alamat (opsional)'),
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
                onPressed: saving
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        final phone = phoneController.text.trim();
                        if (name.isEmpty || phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nama dan telepon wajib diisi')),
                          );
                          return;
                        }

                        setDialogState(() => saving = true);
                        try {
                          final service = context.read<AuthProvider>().dataService;
                          final saved = isEdit
                              ? await service.updateCustomer(
                                  customer!.id,
                                  name: name,
                                  phone: phone,
                                  email: emailController.text.trim(),
                                  address: addressController.text.trim(),
                                )
                              : await service.createCustomer(
                                  name: name,
                                  phone: phone,
                                  email: emailController.text.trim(),
                                  address: addressController.text.trim(),
                                );

                          if (!mounted) return;
                          setState(() {
                            if (isEdit) {
                              final index = _customers.indexWhere((c) => c.id == saved.id);
                              if (index >= 0) _customers[index] = saved;
                            } else {
                              _customers.add(saved);
                            }
                            _filter();
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEdit ? 'Pelanggan diperbarui' : 'Pelanggan ditambahkan'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          }
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
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }
}
