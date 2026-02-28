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
    // Initial load
    _future = _service.listBatches();
  }

  Future<void> _reload() async {
    // We create a new future and call setState so the FutureBuilder rebuilds immediately
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
      builder: (_) => AlertDialog(
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

      if (!mounted) return;

      // Refresh the current list
      await _reload();

      // Navigate to detail
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderBatchDetailScreen(batchId: batch.id)),
      ).then((_) => _reload()); // Refresh again when returning from detail
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _confirmDelete(OrderBatch batch) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Batch?'),
        content: Text('Are you sure you want to delete "${batch.title ?? 'Batch #${batch.id}'}"? This will also remove the associated colleague debts from the ledger.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batch and associated debts archived.')),
      );
      // Immediately refresh the list to hide the soft-deleted batch
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Batches')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
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

            if (snap.hasError) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Failed to load batches'),
                      const SizedBox(height: 16),
                      FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                    ],
                  ),
                ),
              );
            }

            final batches = snap.data ?? [];
            if (batches.isEmpty) {
              return ListView(
                // Ensure list is scrollable so RefreshIndicator works even when empty
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.layers_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No batches yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        const Text('Tap "New Batch" to create one or pull to refresh'),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: batches.length,
              itemBuilder: (context, i) {
                final b = batches[i];
                final title = (b.title ?? '').trim();
                final vendor = (b.vendorName ?? '-').trim();
                final displayTitle = title.isEmpty ? 'Batch #${b.id}' : title;

                return Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderBatchDetailScreen(batchId: b.id)),
                      ).then((_) => _reload()); // Refresh when returning from detail
                    },
                    onLongPress: () => _confirmDelete(b),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.layers, size: 20, color: Theme.of(context).colorScheme.onSecondaryContainer),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  displayTitle,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  b.status.toUpperCase(),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.store, size: 16, color: Theme.of(context).colorScheme.outline),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  vendor,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.list_alt, size: 16, color: Theme.of(context).colorScheme.outline),
                              const SizedBox(width: 4),
                              Text(
                                '${b.itemsCount} Items',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
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
}