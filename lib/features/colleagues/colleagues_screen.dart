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

  Future<void> _refresh() async {
    final future = _service.fetchColleagues(includeInactive: _includeInactive);
    setState(() => _future = future);
    await future;
  }

  Future<void> _openCreate() async {
    final payload = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const ColleagueFormSheet(),
    );

    if (payload == null) return;

    await _service.createColleague(
      name: payload['name'] as String,
      isActive: payload['is_active'] as bool,
    );

    if (mounted) _refresh();
  }

  Future<void> _deactivate(Colleague c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deactivate colleague?'),
        content: Text('Deactivate "${c.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _service.deactivateColleague(c.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Colleague deactivated')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to deactivate: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Colleagues'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'inventory':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ItemsScreen()));
                  break;
                case 'batches':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderBatchesScreen()));
                  break;
                case 'settings':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ApiBaseUrlScreen()))
                      .then((_) { if (mounted) _refresh(); });
                  break;
                case 'toggle_inactive':
                  setState(() {
                    _includeInactive = !_includeInactive;
                    _refresh();
                  });
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_inactive',
                child: Row(
                  children: [
                     Icon(
                      _includeInactive ? Icons.check_box : Icons.check_box_outline_blank,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    const Text('Show Inactive'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'inventory',
                child: Row(
                  children: [Icon(Icons.inventory_2_outlined), SizedBox(width: 12), Text('Inventory')],
                ),
              ),
              const PopupMenuItem(
                value: 'batches',
                child: Row(
                  children: [Icon(Icons.layers_outlined), SizedBox(width: 12), Text('Order Batches')],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [Icon(Icons.settings_outlined), SizedBox(width: 12), Text('Settings')],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('New Colleague'),
      ),
      body: FutureBuilder<List<Colleague>>(
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
                  Text('Failed to load colleagues', style: Theme.of(context).textTheme.titleMedium),
                  Text('${snap.error}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No colleagues found', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final c = items[i];
                return _ColleagueCard(
                  colleague: c,
                  onTap: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ColleagueLedgerScreen(colleagueId: c.id),
                      ),
                    );
                  },
                  onDeactivate: c.isActive ? () => _deactivate(c) : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ColleagueCard extends StatelessWidget {
  final Colleague colleague;
  final VoidCallback onTap;
  final VoidCallback? onDeactivate;

  const _ColleagueCard({
    required this.colleague,
    required this.onTap,
    this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = colleague.name.isNotEmpty ? colleague.name.trim().substring(0, 1).toUpperCase() : '?';

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer, // M3 surface variant
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onDeactivate,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      colleague.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colleague.isActive 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: colleague.isActive ? Colors.green : Colors.grey,
                              width: 0.5
                            ),
                          ),
                          child: Text(
                            colleague.isActive ? 'Active' : 'Inactive',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colleague.isActive ? Colors.green[700] : Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                         Text(
                          'ID: ${colleague.id}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    colleague.balance.toStringAsFixed(2),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colleague.balance < 0 ? Colors.red : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Balance',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
