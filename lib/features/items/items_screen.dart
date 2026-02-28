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
    setState(() {
      _future = _service.fetchItems(includeInactive: _includeInactive);
    });
    await _future;
  }

  Future<void> _openCreate() async {
    final payload = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Required for rounded corners in sheet
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
      backgroundColor: Colors.transparent,
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
        title: const Text('Deactivate Item?'),
        content: Text('Are you sure you want to deactivate "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _service.deactivateItem(item.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
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
                child: ListTile(
                  leading: Icon(
                    _includeInactive ? Icons.check_box : Icons.check_box_outline_blank,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Show Inactive'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add_rounded),
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
                  const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Failed to load inventory', style: theme.textTheme.titleMedium),
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
                  Text('No items found', style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final it = items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    // Inherits rounded corners and borders from app.dart CardThemeData
                    child: InkWell(
                      onTap: () => _openEdit(it),
                      onLongPress: it.isActive ? () => _deactivate(it) : null,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: it.isActive
                                    ? theme.colorScheme.primary.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.inventory_2_rounded,
                                color: it.isActive ? theme.colorScheme.primary : Colors.grey,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      it.name,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: it.isActive ? null : theme.colorScheme.outline,
                                        decoration: it.isActive ? null : TextDecoration.lineThrough,
                                      )
                                  ),
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
                                          child: Text(
                                              'Inactive',
                                              style: theme.textTheme.labelSmall?.copyWith(color: Colors.red, fontWeight: FontWeight.bold)
                                          ),
                                        ),
                                      Text(
                                          'ID: ${it.id}',
                                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)
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
                                  'Rs. ${it.default_price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: it.isActive ? theme.colorScheme.onSurface : theme.colorScheme.outline,
                                  ),
                                ),
                                const Text(
                                    'PRICE',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)
                                ),
                              ],
                            ),
                          ],
                        ),
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