import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/app_prefs.dart';
import '../settings/api_base_url_screen.dart';
import 'colleague_model.dart';
import 'colleagues_service.dart';
import 'colleague_form_sheet.dart';
import '../ledger/colleague_ledger_screen.dart';
import '../notifications/notifications_screen.dart';

// New Enum for Figma Filters
enum ColleagueFilter { all, active, inactive }

class ColleaguesScreen extends StatefulWidget {
  const ColleaguesScreen({super.key});

  @override
  State<ColleaguesScreen> createState() => _ColleaguesScreenState();
}

class _ColleaguesScreenState extends State<ColleaguesScreen> {
  late final ColleaguesService _service;
  late Future<List<Colleague>> _future;

  // Default filter set to Active per Figma design
  ColleagueFilter _currentFilter = ColleagueFilter.active;

  @override
  void initState() {
    super.initState();
    final prefs = AppPrefs();
    _service = ColleaguesService(ApiClient(prefs));
    // Initial fetch based on the default active filter
    _future = _service.fetchColleagues(includeInactive: false);
  }

  Future<void> _refresh() async {
    // Logic to determine what the API should return based on filter
    // If 'active' is selected, we fetch with includeInactive: false
    // If 'inactive' or 'all' is selected, we fetch with includeInactive: true
    bool includeInactive = _currentFilter != ColleagueFilter.active;

    setState(() {
      _future = _service.fetchColleagues(includeInactive: includeInactive);
    });
    await _future;
  }

  // Helper to filter the list locally for the view
  List<Colleague> _applyLocalFilter(List<Colleague> data) {
    if (_currentFilter == ColleagueFilter.active) {
      return data.where((c) => c.isActive).toList();
    } else if (_currentFilter == ColleagueFilter.inactive) {
      return data.where((c) => !c.isActive).toList();
    }
    return data;
  }

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
      await _service.deactivateColleague(colleague.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${colleague.name} deactivated')));
        _refresh();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Office Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApiBaseUrlScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final payload = await showModalBottomSheet<Map<String, dynamic>>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const ColleagueFormSheet()
          );
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

          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Failed to load data'),
                  TextButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          // Data processing
          final rawItems = snap.data ?? [];
          final items = _applyLocalFilter(rawItems);
          final totalDebt = rawItems.fold(0.0, (sum, item) => sum + item.balance);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Dashboard Card
                SliverToBoxAdapter(child: _buildDashboard(theme, totalDebt)),

                // 2. Figma Filter Chips Row
                SliverToBoxAdapter(child: _buildFilterRow()),

                // 3. The List of People
                if (items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No colleagues found')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, i) => _ColleagueCard(
                          colleague: items[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ColleagueLedgerScreen(colleagueId: items[i].id)),
                          ).then((_) => _refresh()),
                          onLongPress: () => _confirmDeactivate(items[i]),
                        ),
                        childCount: items.length,
                      ),
                    ),
                  ),
                // Extra space at bottom so FAB doesn't hide last item
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboard(ThemeData theme, double total) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  'Total Office Balance',
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500
                  )
              ),
              const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 12),
          Text(
              'Rs. ${total.toStringAsFixed(2)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900
              )
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _filterChip('All', ColleagueFilter.all),
          const SizedBox(width: 8),
          _filterChip('Active', ColleagueFilter.active),
          const SizedBox(width: 8),
          _filterChip('Inactive', ColleagueFilter.inactive),
        ],
      ),
    );
  }

  Widget _filterChip(String label, ColleagueFilter filter) {
    final isSelected = _currentFilter == filter;
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _currentFilter = filter);
          _refresh();
        }
      },
      showCheckmark: false,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      backgroundColor: Colors.transparent,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : const Color(0xFF64748B),
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                      initials,
                      style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18
                      )
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
                          fontSize: 16,
                          decoration: colleague.isActive ? null : TextDecoration.lineThrough,
                          color: colleague.isActive ? null : theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                          colleague.isActive ? 'Active Member' : 'Inactive',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${colleague.balance.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: colleague.isActive
                            ? (colleague.balance > 0 ? Colors.redAccent : Colors.green)
                            : theme.colorScheme.outline,
                      ),
                    ),
                    const Text(
                        'BALANCE',
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
  }
}