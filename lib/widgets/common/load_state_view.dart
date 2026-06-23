import 'package:flutter/material.dart';

/// Shows loading spinner, error with retry, or the loaded content.
class LoadStateView extends StatelessWidget {
  const LoadStateView({
    super.key,
    required this.loading,
    required this.child,
    this.error,
    this.onRetry,
  });

  final bool loading;
  final String? error;
  final VoidCallback? onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'Gagal memuat data',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return child;
  }
}
