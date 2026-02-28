import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/app_prefs.dart';
import 'item_form_sheet.dart';
import 'item_model.dart';
import 'items_service.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  late final ItemsService _service;
  late Future<List<Item>> _future;
  bool _includeInactive = false;

  @override
  void initState() {
    super.initState();
    _service = ItemsService(ApiClient(AppPrefs()));
    _future = _service.fetchItems(includeInactive: _includeInactive);
  }

  Future<void> _reload() async {
    // Update the future and trigger a rebuild
    setState(() {
      _future = _service.fetchItems(includeInactive: _includeInactive);
    });
    // Wait for the data to actually arrive (important for RefreshIndicator)
    await _future;
  }

  Future<void> _openCreate() async {
    final payload = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ItemFormSheet(),
    );
    if (payload == null) return;

    await _service.createItem(
      name: payload['name'] as String,
      default_price: payload['cost'] as double,
    );
    await _reload();
  }

  Future<void> _openEdit(Item item) async {
    final payload = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ItemFormSheet(initial: item),
    );
    if (payload == null) return;

    await _service.updateItem(
      id: item.id,
      name: payload['name'] as String,
      default_price: payload['cost'] as double,
    );
    await _reload();
  }

  Future<void> _deactivate(Item item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deactivate item?'),
        content: Text('Deactivate "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Deactivate')),
        ],
      ),
    );

    if (ok != true) return;

    await _service.deactivateItem(item.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'toggle_inactive') {
                setState(() {
                  _includeInactive = !_includeInactive;
                  _reload();
                });
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
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('New Item'),
      ),
      body: FutureBuilder<List<Item>>(
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
                  Text('Failed to load items', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Retry')),
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
                   Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                   Text('No items yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final it = items[i];
                return Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _openEdit(it),
                    onLongPress: it.isActive ? () => _deactivate(it) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.onPrimaryContainer),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (!it.isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text('Inactive', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.red)),
                                      ),
                                    Text('ID: ${it.id}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            it.default_price.toStringAsFixed(2),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
