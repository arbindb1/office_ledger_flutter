import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/app_prefs.dart';
import 'ledger_service.dart';
import 'add_payment_sheet.dart';
import 'colleague_ledger_model.dart';
import 'colleague_analytics_screen.dart'; // Import your new analytics screen

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
    setState(() {
      _future = _service.getColleagueLedger(widget.colleagueId);
    });
    await _future;
  }

  Future<void> _addPayment() async {
    final payload = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Figma rounded style
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
    final theme = Theme.of(context);

    return FutureBuilder<ColleagueLedgerResponse>(
      future: _future,
      builder: (context, snap) {
        // We handle loading/error inside the scaffold so the AppBar is always visible
        String colleagueName = "Ledger";
        if (snap.hasData) colleagueName = snap.data!.colleague.name;

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            title: Text(colleagueName),
            actions: [
              // NEW FEATURE: Analytics Button
              if (snap.hasData)
                IconButton(
                  icon: const Icon(Icons.pie_chart_outline_rounded),
                  tooltip: 'View Consumption Analytics',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ColleagueAnalyticsScreen(
                          colleagueId: widget.colleagueId,
                          colleagueName: colleagueName,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _addPayment,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Payment'),
          ),
          body: _buildBody(snap, theme),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<ColleagueLedgerResponse> snap, ThemeData theme) {
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
            const Text('Failed to load ledger'),
            TextButton(onPressed: _reload, child: const Text('Retry')),
          ],
        ),
      );
    }

    final data = snap.data!;
    final outstanding = data.outstanding;

    return RefreshIndicator(
      onRefresh: _reload,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 1. Figma Summary Card (Balance)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Outstanding Balance',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rs. ${outstanding.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Transaction Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Recent Transactions',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),

          // 3. Transactions List
          if (data.ledger.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No transactions recorded yet.')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, i) {
                    final e = data.ledger[i];
                    final isDebit = e.entryType == 'debit';
                    final color = isDebit ? Colors.redAccent : Colors.green;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isDebit ? Icons.shopping_bag_outlined : Icons.account_balance_wallet_outlined,
                              color: color,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            e.batch_name,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            e.createdAt.toString().split(' ')[0], // Shows YYYY-MM-DD
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: Text(
                            '${isDebit ? "-" : "+"} ${e.amount.toInt()}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: data.ledger.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}