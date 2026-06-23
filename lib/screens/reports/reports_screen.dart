import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/formatters.dart';
import '../../widgets/common/page_header.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedType = 'sales';
  String _selectedPeriod = 'bulan_ini';
  ReportSummary? _report;
  bool _loading = false;

  static const _reportTypes = {
    'sales': 'Laporan Penjualan',
    'orders': 'Laporan Pesanan',
    'inventory': 'Laporan Inventori',
    'ingredients': 'Penggunaan Bahan',
    'revenue': 'Analisis Pendapatan',
  };

  static const _periods = {
    'hari_ini': 'Hari Ini',
    'minggu_ini': 'Minggu Ini',
    'bulan_ini': 'Bulan Ini',
    'tahun_ini': 'Tahun Ini',
  };

  Future<void> _generate() async {
    setState(() => _loading = true);
    final report = await context.read<AuthProvider>().dataService.getReport(_selectedType, _selectedPeriod);
    if (mounted) setState(() { _report = report; _loading = false; });
  }

  Future<void> _exportReport(BuildContext context) async {
    if (_report == null) return;

    final buffer = StringBuffer('${_report!.title}\n');
    buffer.writeln('Periode: ${_periods[_selectedPeriod]}');
    buffer.writeln();

    final headers = _report!.rows.isNotEmpty ? _report!.rows.first.keys.toList() : <String>[];
    if (headers.isNotEmpty) {
      buffer.writeln(headers.join(','));
      for (final row in _report!.rows) {
        buffer.writeln(headers.map((h) => _csvCell(row[h])).join(','));
      }
    }

    if (_report!.total > 0) {
      buffer.writeln();
      buffer.writeln('Total,${_report!.total}');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan disalin ke clipboard (format CSV)')),
      );
    }
  }

  String _csvCell(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.contains(',') || text.contains('"') || text.contains('\n')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Laporan',
            subtitle: 'Generate dan export laporan operasional & keuangan',
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Jenis Laporan'),
                      initialValue: _selectedType,
                      items: _reportTypes.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedType = v!),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Periode'),
                      initialValue: _selectedPeriod,
                      items: _periods.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedPeriod = v!),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _generate,
                    icon: _loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.assessment, size: 20),
                    label: const Text('Generate'),
                  ),
                  if (_report != null)
                    OutlinedButton.icon(
                      onPressed: () => _exportReport(context),
                      icon: const Icon(Icons.download, size: 20),
                      label: const Text('Export'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _report == null
                ? const Card(
                    child: Center(
                      child: Text(
                        'Pilih jenis laporan dan periode, lalu klik Generate',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  )
                : Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _report!.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                    Text(
                                      'Periode: ${_periods[_selectedPeriod]}',
                                      style: const TextStyle(color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              if (_report!.total > 0)
                                Text(
                                  _selectedType == 'orders'
                                      ? 'Total: ${_report!.total.toInt()} pesanan'
                                      : formatCurrency(_report!.total),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: _report!.rows.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final row = _report!.rows[i];
                              return ListTile(
                                title: Text(_rowTitle(row)),
                                subtitle: Text(_rowSubtitle(row)),
                                trailing: _rowTrailing(row) != null
                                    ? Text(
                                        _rowTrailing(row)!,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      )
                                    : null,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _rowTitle(Map<String, dynamic> row) {
    return row['menu'] ?? row['status'] ?? row['bahan'] ?? row['bulan'] ?? '-';
  }

  String _rowSubtitle(Map<String, dynamic> row) {
    if (row.containsKey('qty')) return 'Qty: ${row['qty']}';
    if (row.containsKey('count')) return 'Jumlah: ${row['count']}';
    if (row.containsKey('stok')) return 'Stok: ${row['stok']} ${row['unit'] ?? ''}';
    if (row.containsKey('used')) return 'Terpakai: ${row['used']} ${row['unit']}';
    if (row.containsKey('status')) return 'Status: ${row['status']}';
    return '';
  }

  String? _rowTrailing(Map<String, dynamic> row) {
    if (row.containsKey('revenue')) return formatCurrency((row['revenue'] as num).toDouble());
    if (row.containsKey('cost')) return formatCurrency((row['cost'] as num).toDouble());
    if (row.containsKey('pendapatan')) return formatCurrency((row['pendapatan'] as num).toDouble());
    return null;
  }
}
