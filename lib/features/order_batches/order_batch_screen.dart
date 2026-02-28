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
    final f = _service.listBatches();
    setState(() => _future = f);
    await f;
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

    final batch = await _service.createBatch(
      title: titleCtrl.text.trim(),
      vendorName: vendorCtrl.text.trim().isEmpty ? null : vendorCtrl.text.trim(),
    );

    if (!mounted) return;
    await _reload();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderBatchDetailScreen(batchId: batch.id)),
    );
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
      body: FutureBuilder<List<OrderBatch>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Failed to load batches', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                ],
              ),
            );
          }

          final batches = snap.data ?? [];
          if (batches.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Icon(Icons.layers_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                   Text('No batches yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600])),
                   const SizedBox(height: 8),
                   const Text('Tap "New Batch" to create one'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
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
                      );
                    },
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
            ),
          );

        },
      ),
    );
  }
}
