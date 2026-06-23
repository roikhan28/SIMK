import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../core/rbac.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/page_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Pengaturan',
            subtitle: 'Profil akun dan konfigurasi aplikasi',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 24, color: AppTheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text(user.email, style: const TextStyle(color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              Chip(
                                label: Text(user.role.label, style: const TextStyle(fontSize: 12)),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.api),
                        title: const Text('API Base URL'),
                        subtitle: Text(ApiConfig.baseUrl),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          ApiConfig.useMockData ? Icons.science : Icons.cloud_done,
                          color: ApiConfig.useMockData ? AppTheme.warning : AppTheme.success,
                        ),
                        title: const Text('Mode Data'),
                        subtitle: Text(ApiConfig.useMockData ? 'Mock Data (Demo)' : 'Live API'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Versi Aplikasi'),
                        subtitle: const Text('SIMK v1.0.0 (MVP)'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppTheme.error),
                    title: const Text('Keluar', style: TextStyle(color: AppTheme.error)),
                    onTap: () => auth.logout(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
