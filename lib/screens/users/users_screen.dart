import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/rbac.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/page_header.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<User> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await context.read<AuthProvider>().dataService.getUsers();
    if (mounted) setState(() { _users = users; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthProvider, UserRole?>((a) => a.user?.role);
    if (role == null) return const SizedBox.shrink();

    final canCreate = Rbac.canCreate(role, AppModule.users);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Manajemen Pengguna',
            subtitle: 'Kelola akun dan hak akses pengguna sistem',
            action: canCreate
                ? ElevatedButton.icon(
                    onPressed: () => _showUserDialog(context),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Tambah Pengguna'),
                  )
                : null,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: ListView.separated(
                      itemCount: _users.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final user = _users[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                            child: Text(
                              user.name[0].toUpperCase(),
                              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${user.email} • ${user.role.label}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: user.isActive
                                      ? AppTheme.success.withValues(alpha: 0.12)
                                      : AppTheme.error.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  user.isActive ? 'Aktif' : 'Nonaktif',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: user.isActive ? AppTheme.success : AppTheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (Rbac.canUpdate(role, AppModule.users)) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => _showUserDialog(context, user: user),
                                ),
                              ],
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

  void _showUserDialog(BuildContext context, {User? user}) {
    final isEdit = user != null;
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final passwordController = TextEditingController();
    var selectedRole = user?.role ?? UserRole.kasir;
    var isActive = user?.isActive ?? true;
    var saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Pengguna' : 'Tambah Pengguna'),
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
                    controller: emailController,
                    enabled: !saving,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    enabled: !saving,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: isEdit ? 'Password baru (opsional)' : 'Password',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: UserRole.values
                        .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                        .toList(),
                    onChanged: saving ? null : (v) => setDialogState(() => selectedRole = v!),
                  ),
                  if (isEdit) ...[
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Akun aktif'),
                      value: isActive,
                      onChanged: saving ? null : (v) => setDialogState(() => isActive = v),
                    ),
                  ],
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
                        final email = emailController.text.trim();
                        final password = passwordController.text;

                        if (name.isEmpty || email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nama dan email wajib diisi')),
                          );
                          return;
                        }
                        if (!isEdit && password.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password minimal 6 karakter')),
                          );
                          return;
                        }

                        setDialogState(() => saving = true);
                        try {
                          final dataService = context.read<AuthProvider>().dataService;
                          final saved = isEdit
                              ? await dataService.updateUser(
                                  user!.id,
                                  name: name,
                                  email: email,
                                  role: selectedRole,
                                  isActive: isActive,
                                  password: password.isEmpty ? null : password,
                                )
                              : await dataService.createUser(
                                  name: name,
                                  email: email,
                                  password: password,
                                  role: selectedRole,
                                );

                          if (!mounted) return;
                          setState(() {
                            if (isEdit) {
                              final index = _users.indexWhere((u) => u.id == saved.id);
                              if (index >= 0) _users[index] = saved;
                            } else {
                              _users.add(saved);
                            }
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEdit ? 'Pengguna diperbarui' : 'Pengguna ditambahkan'),
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
