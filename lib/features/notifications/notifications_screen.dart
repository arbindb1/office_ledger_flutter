import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/app_prefs.dart';
import '../colleagues/colleagues_service.dart';
import '../colleagues/colleague_model.dart';
import 'notifications_service.dart';
import 'payment_notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsService _service;
  late final ColleaguesService _colService;

  late Future<List<PaymentNotification>> _future;
  List<Colleague> _colleagues = [];

  @override
  void initState() {
    super.initState();
    final api = ApiClient(AppPrefs());
    _service = NotificationsService(api);
    _colService = ColleaguesService(api);
    _future = _load();
  }

  Future<List<PaymentNotification>> _load() async {
    // load colleagues once for dropdown
    _colleagues = await _colService.fetchColleagues(includeInactive: true);
    return _service.fetchUnmatched();
  }

  Future<void> _reload() async {
    final f = _load();
    setState(() => _future = f);
    await f;
  }

  Future<void> _assign(PaymentNotification n) async {
    int? selected = n.assignedColleagueId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Assign to colleague'),
        content: DropdownButtonFormField<int>(
          value: selected,
          items: _colleagues
              .map((c) => DropdownMenuItem(
            value: c.id,
            child: Text('${c.name}${c.isActive ? '' : ' (inactive)'}'),
          ))
              .toList(),
          onChanged: (v) => selected = v,
          decoration: const InputDecoration(labelText: 'Colleague'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Assign')),
        ],
      ),
    );

    if (ok != true || selected == null) return;

    await _service.assign(notificationId: n.id, colleagueId: selected!);
    await _reload();
  }

  Future<void> _apply(PaymentNotification n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apply credit?'),
        content: const Text('This will add a credit entry to the ledger.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apply')),
        ],
      ),
    );

    if (ok != true) return;

    await _service.apply(n.id);
    await _reload();
  }

  Future<void> _ignore(PaymentNotification n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ignore notification?'),
        content: const Text('This will hide it from unmatched list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ignore')),
        ],
      ),
    );

    if (ok != true) return;

    await _service.ignore(n.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unmatched Payments'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<PaymentNotification>>(
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
                    Text('Failed to load notifications', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                  ],
                ),
              ),
            );
          }

          final list = snap.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No unmatched payments', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final n = list[i];
                final assigned = n.assignedColleagueId != null;

                return Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                          child: Icon(Icons.payment, color: Theme.of(context).colorScheme.onTertiaryContainer),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.provider,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                n.amount.toStringAsFixed(2),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.rawMessage,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (assigned) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Assigned to ID: ${n.assignedColleagueId}',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.blue[800]),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (v) async {
                            if (v == 'assign') await _assign(n);
                            if (v == 'apply') await _apply(n);
                            if (v == 'ignore') await _ignore(n);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'assign',
                              child: Row(children: [Icon(Icons.person_add_outlined), SizedBox(width: 12), Text('Assign')]),
                            ),
                            PopupMenuItem(
                              value: 'apply',
                              enabled: assigned,
                              child: Row(children: [Icon(Icons.check_circle_outline), SizedBox(width: 12), Text(assigned ? 'Apply Credit' : 'Apply (Assign First)')]),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'ignore',
                              child: Row(children: [Icon(Icons.visibility_off_outlined), SizedBox(width: 12), Text('Ignore')]),
                            ),
                          ],
                        ),
                      ],
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
