import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/app_prefs.dart';
import 'ledger_service.dart';
import 'add_payment_sheet.dart';
import 'colleague_ledger_model.dart';

class ColleagueLedgerScreen extends StatefulWidget {
  const ColleagueLedgerScreen({super.key, required this.colleagueId});
  final int colleagueId;

  @override
  State<ColleagueLedgerScreen> createState() => _ColleagueLedgerScreenState();
}

class _ColleagueLedgerScreenState extends State<ColleagueLedgerScreen> {
  late final LedgerService _service;
  late Future<ColleagueLedgerResponse> _future;

  @override
  void initState() {
    super.initState();
    _service = LedgerService(ApiClient(AppPrefs()));
    _future = _service.getColleagueLedger(widget.colleagueId);
  }

  Future<void> _reload() async {
    final f = _service.getColleagueLedger(widget.colleagueId);
    setState(() => _future = f);
    await f;
  }

  Future<void> _addPayment() async {
    final payload = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddPaymentSheet(),
    );
    if (payload == null) return;

    await _service.manualCredit(
      colleagueId: widget.colleagueId,
      amount: (payload['amount'] as num).toDouble(),
      note: (payload['note'] as String?)?.trim(),
    );

    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ledger')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPayment,
        icon: const Icon(Icons.add),
        label: const Text('Add Payment'),
      ),
      body: FutureBuilder<ColleagueLedgerResponse>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Failed to load ledger', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                  ],
                ),
              ),
            );
          }

          final data = snap.data!;
          final c = data.colleague;
          final outstanding = data.outstanding;
          final isPositive = outstanding >= 0;

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // Summary Card
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text('Outstanding Balance', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                        const SizedBox(height: 8),
                        Text(
                          outstanding.toStringAsFixed(2),
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPositive ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(c.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                      ],
                    ),
                  ),
                ),

                Text('Transactions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                if (data.ledger.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('No transactions yet', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.secondary))),
                  ),

                ...data.ledger.map((e) {
                  final isDebit = e.entryType == 'debit';
                  final sign = isDebit ? '-' : '+';
                  final color = isDebit ? Colors.red : Colors.green[700];
                  final icon = isDebit ? Icons.arrow_outward : Icons.arrow_downward;

                  return Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color?.withOpacity(0.1),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      title: Text(e.source, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        e.createdAt.toString().split('.')[0], // Simple date formatting
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Text(
                        '$sign${e.amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
