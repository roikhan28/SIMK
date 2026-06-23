import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/models.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  factory StatusBadge.order(OrderStatus status) {
    final color = switch (status) {
      OrderStatus.draft => AppTheme.textSecondary,
      OrderStatus.confirmed => Colors.blue,
      OrderStatus.inProduction => AppTheme.warning,
      OrderStatus.ready => AppTheme.primary,
      OrderStatus.delivered => AppTheme.success,
      OrderStatus.cancelled => AppTheme.error,
    };
    return StatusBadge(label: status.label, color: color);
  }

  factory StatusBadge.payment(String status) {
    final color = switch (status) {
      'confirmed' || 'paid' => AppTheme.success,
      'pending' => AppTheme.warning,
      _ => AppTheme.textSecondary,
    };
    final label = switch (status) {
      'confirmed' || 'paid' => 'Lunas',
      'pending' => 'Pending',
      _ => status,
    };
    return StatusBadge(label: label, color: color);
  }

  factory StatusBadge.production(String status) {
    final color = switch (status) {
      'completed' => AppTheme.success,
      'in_progress' => AppTheme.warning,
      'scheduled' => Colors.blue,
      _ => AppTheme.textSecondary,
    };
    final label = switch (status) {
      'completed' => 'Selesai',
      'in_progress' => 'Berjalan',
      'scheduled' => 'Terjadwal',
      _ => status,
    };
    return StatusBadge(label: label, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
