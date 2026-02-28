import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/app_prefs.dart';
import 'add_batch_item_sheet.dart';
import 'order_batch_detail_model.dart';
import 'order_batch_service.dart';

class OrderBatchDetailScreen extends StatefulWidget {
  const OrderBatchDetailScreen({super.key, required this.batchId});
  final int batchId;

  @override
  State<OrderBatchDetailScreen> createState() => _OrderBatchDetailScreenState();
}

class _OrderBatchDetailScreenState extends State<OrderBatchDetailScreen> {
  late final OrderBatchService _batchService;
  OrderBatchDetail? _detail;

  bool _loading = true;
  String _status = 'draft';

  @override
  void initState() {
    super.initState();
    final api = ApiClient(AppPrefs());
    _batchService = OrderBatchService(api);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final detail = await _batchService.getBatch(widget.batchId);

    setState(() {
      _detail = detail;
      _status = detail.batch.status;
      _loading = false;
    });
  }

  Future<void> _addLine() async {
    final payload = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddBatchItemSheet(),
    );

    if (payload == null) return;

    await _batchService.addBatchItem(
      batchId: widget.batchId,
      colleagueId: payload['colleague_id'] as int,
      itemId: payload['item_id'] as int,
      quantity: payload['quantity'] as int,
      unitPrice: (payload['price'] as num).toDouble(),
    );

    await _load();
  }

  Future<void> _finalize() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalize batch?'),
        content: const Text('This will debit colleagues and lock the batch.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalize'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _batchService.finalize(widget.batchId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDraft = _status == 'draft';
    final lines = _detail?.batch.items ?? [];
    final total = _detail?.total ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text('Batch #${widget.batchId}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $_status',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),

            if (isDraft) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addLine,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item to Batch'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _finalize,
                  child: const Text('Finalize Batch'),
                ),
              ),
            ] else
              const Text('Batch finalized.'),

            const SizedBox(height: 16),
            Text('Items',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            Expanded(
              child: lines.isEmpty
                  ? const Center(
                child: Text('No items in this batch yet'),
              )
                  : ListView.separated(
                itemCount: lines.length,
                separatorBuilder: (context, index) =>
                const Divider(height: 1),
                itemBuilder: (context, i) {
                  final x = lines[i];
                  return ListTile(
                    title: Text(
                        '${x.colleagueName} • ${x.itemName}'),
                    subtitle: Text(
                      'Qty ${x.quantity} × ${x.unitPrice.toStringAsFixed(2)}',
                    ),
                    trailing: Text(
                        x.lineTotal.toStringAsFixed(2)),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  total.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
