import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/app_prefs.dart';
import 'order_batch_detail_screen.dart';
import 'order_batch_model.dart';
import 'order_batch_service.dart';

class OrderBatchesScreen extends StatefulWidget {
  const OrderBatchesScreen({super.key});

  @override
  State<OrderBatchesScreen> createState() => _OrderBatchesScreenState();
}

class _OrderBatchesScreenState extends State<OrderBatchesScreen> {
  late final OrderBatchService _service;
  late Future<List<OrderBatch>> _future;

  @override
  void initState() {
    super.initState();
    _service = OrderBatchService(ApiClient(AppPrefs()));
    _future = _service.listBatches();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.listBatches();
    });
    await _future;
  }

  Future<void> _create() async {
    final titleCtrl = TextEditingController();
    final vendorCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Order Batch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: vendorCtrl, decoration: const InputDecoration(labelText: 'Vendor (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final batch = await _service.createBatch(
        title: titleCtrl.text.trim(),
        vendorName: vendorCtrl.text.trim().isEmpty ? null : vendorCtrl.text.trim(),
      );

      // Fix for "Async Gaps" error: check if mounted before using context
      if (!mounted) return;

      await _reload();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderBatchDetailScreen(batchId: batch.id)),
      ).then((_) {
        if (mounted) _reload();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _confirmDelete(OrderBatch batch) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Batch?'),
        content: Text('Are you sure you want to delete "${batch.title ?? 'Batch #${batch.id}'}"? This will also remove associated debts.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _service.deleteBatch(batch.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch archived.')));
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: const Text('Order Batches')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Batch'),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<OrderBatch>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) return _buildErrorState();

            final batches = snap.data ?? [];
            if (batches.isEmpty) return _buildEmptyState();

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: batches.length,
              itemBuilder: (context, i) {
                final b = batches[i];
                final isFinalized = b.status.toLowerCase() == 'finalized';
                final displayTitle = (b.title ?? '').isEmpty ? 'Batch #${b.id}' : b.title!;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OrderBatchDetailScreen(batchId: b.id)),
                        ).then((_) {
                          if (mounted) _reload();
                        });
                      },
                      onLongPress: () => _confirmDelete(b),
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    // Use .withValues instead of .withOpacity
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.layers_rounded, size: 20, color: theme.colorScheme.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    displayTitle,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                _buildStatusBadge(b.status, isFinalized, theme),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildInfoItem(Icons.store_rounded, b.vendorName ?? 'No Vendor', theme),
                                _buildInfoItem(Icons.shopping_cart_rounded, '${b.itemsCount} Items', theme),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isFinalized, ThemeData theme) {
    final color = isFinalized ? Colors.green : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.layers_clear_rounded, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('No active batches', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600])),
              const SizedBox(height: 8),
              const Text('Create a batch to start tracking orders'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Failed to load batches'),
          TextButton(onPressed: _reload, child: const Text('Retry')),
        ],
      ),
    );
  }
}