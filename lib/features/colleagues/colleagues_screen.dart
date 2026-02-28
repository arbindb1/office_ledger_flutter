import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/app_prefs.dart';
import '../settings/api_base_url_screen.dart';
import 'colleague_model.dart';
import 'colleagues_service.dart';
import '../items/items_screen.dart';
import '../order_batches/order_batch_screen.dart';
import 'colleague_form_sheet.dart';
import '../ledger/colleague_ledger_screen.dart';
import '../notifications/notifications_screen.dart';

class ColleaguesScreen extends StatefulWidget {
  const ColleaguesScreen({super.key});

  @override
  State<ColleaguesScreen> createState() => _ColleaguesScreenState();
}

class _ColleaguesScreenState extends State<ColleaguesScreen> {
  late final ColleaguesService _service;
  late Future<List<Colleague>> _future;
  bool _includeInactive = false;

  @override
  void initState() {
    super.initState();
    final prefs = AppPrefs();
    _service = ColleaguesService(ApiClient(prefs));
    _future = _service.fetchColleagues(includeInactive: _includeInactive);
  }

  // Forces a state update and creates a fresh Future to refresh UI
  Future<void> _refresh() async {
    setState(() {
      _future = _service.fetchColleagues(includeInactive: _includeInactive);
    });
    await _future;
  }

  // Safety confirmation before deactivating a colleague
  Future<void> _confirmDeactivate(Colleague colleague) async {
    if (!colleague.isActive) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deactivate Colleague?'),
        content: Text('Deactivate "${colleague.name}"? They will be hidden from new order batches.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _service.updateColleague(
        id: colleague.id,
        name: colleague.name,
        isActive: false,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${colleague.name} deactivated')));
        _refresh();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  double _calculateTotalBalance(List<Colleague> colleagues) {
    return colleagues.fold(0.0, (sum, item) => sum + item.balance);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Office Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'inventory':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ItemsScreen())).then((_) => _refresh());
                  break;
                case 'batches':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderBatchesScreen())).then((_) => _refresh());
                  break;
                case 'settings':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ApiBaseUrlScreen())).then((_) => _refresh());
                  break;
                case 'toggle_inactive':
                  setState(() => _includeInactive = !_includeInactive);
                  _refresh();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_inactive',
                child: ListTile(
                  leading: Icon(_includeInactive ? Icons.check_box : Icons.check_box_outline_blank, color: theme.colorScheme.primary),
                  title: const Text('Show Inactive'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'inventory', child: ListTile(leading: Icon(Icons.inventory_2_outlined), title: Text('Inventory'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'batches', child: ListTile(leading: Icon(Icons.layers_outlined), title: Text('Order Batches'), contentPadding: EdgeInsets.zero)),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'settings', child: ListTile(leading: Icon(Icons.settings_outlined), title: Text('Settings'), contentPadding: EdgeInsets.zero)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final payload = await showModalBottomSheet<Map<String, dynamic>>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => const ColleagueFormSheet());
          if (payload != null) {
            await _service.createColleague(name: payload['name'] as String, isActive: payload['is_active'] as bool);
            _refresh();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Person'),
      ),
      body: FutureBuilder<List<Colleague>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return _buildErrorState(snap.error.toString());

          final items = snap.data ?? [];
          final totalDebt = _calculateTotalBalance(items);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator
              slivers: [
                SliverToBoxAdapter(child: _buildDashboard(theme, totalDebt)),
                if (items.isEmpty)
                  const SliverFillRemaining(child: Center(child: Text('No colleagues found')))
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, i) {
                          final c = items[i];
                          return _ColleagueCard(
                            colleague: c,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ColleagueLedgerScreen(colleagueId: c.id)),
                            ).then((_) => _refresh()),
                            onLongPress: () => _confirmDeactivate(c),
                          );
                        },
                        childCount: items.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboard(ThemeData theme, double total) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Text('Total Office Balance', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.8))),
          const SizedBox(height: 8),
          Text('Rs. ${total.toStringAsFixed(2)}', style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Connection Error'),
          TextButton(onPressed: _refresh, child: const Text('Try Again')),
        ],
      ),
    );
  }
}

class _ColleagueCard extends StatelessWidget {
  final Colleague colleague;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ColleagueCard({required this.colleague, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = colleague.name.isNotEmpty ? colleague.name[0].toUpperCase() : '?';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant)),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Opacity(
                  opacity: colleague.isActive ? 1.0 : 0.5,
                  child: Text(initials, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      colleague.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: colleague.isActive ? null : TextDecoration.lineThrough,
                        color: colleague.isActive ? null : theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(colleague.isActive ? 'Active Member' : 'Inactive', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs. ${colleague.balance.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colleague.isActive
                          ? (colleague.balance > 0 ? Colors.redAccent : Colors.green)
                          : theme.colorScheme.outline,
                    ),
                  ),
                  const Text('Due', style: TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}