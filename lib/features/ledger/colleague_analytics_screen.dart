import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/app_prefs.dart';
import 'ledger_service.dart';

enum AnalyticsMode { month, day }

class ColleagueAnalyticsScreen extends StatefulWidget {
  final int colleagueId;
  final String colleagueName;

  const ColleagueAnalyticsScreen({
    super.key,
    required this.colleagueId,
    required this.colleagueName,
  });

  @override
  State<ColleagueAnalyticsScreen> createState() => _ColleagueAnalyticsScreenState();
}

class _ColleagueAnalyticsScreenState extends State<ColleagueAnalyticsScreen> {
  DateTime _selectedDate = DateTime.now();
  AnalyticsMode _mode = AnalyticsMode.month;
  bool _isLoading = true;
  Map<String, double> _consumptionData = {};
  late final LedgerService _ledgerService;

  @override
  void initState() {
    super.initState();
    _ledgerService = LedgerService(ApiClient(AppPrefs()));
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await _ledgerService.getAnalytics(
        colleagueId: widget.colleagueId,
        year: _selectedDate.year,
        month: _selectedDate.month,
        // Only pass day if we are in 'day' mode
        day: _mode == AnalyticsMode.day ? _selectedDate.day : null,
      );

      if (mounted) {
        setState(() {
          _consumptionData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching analytics: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSpent = _consumptionData.values.fold(0.0, (sum, v) => sum + v);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('${widget.colleagueName}\'s Spending'),
      ),
      body: Column(
        children: [
          _buildModeToggle(theme),
          _buildDatePicker(theme),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _consumptionData.isEmpty
                ? _buildEmptyState(theme)
                : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildPieChart(theme, totalSpent),
                    const SizedBox(height: 40),
                    _buildLegend(theme),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SegmentedButton<AnalyticsMode>(
        segments: const [
          ButtonSegment(
              value: AnalyticsMode.month,
              label: Text('Monthly'),
              icon: Icon(Icons.calendar_month_rounded)
          ),
          ButtonSegment(
              value: AnalyticsMode.day,
              label: Text('Daily'),
              icon: Icon(Icons.today_rounded)
          ),
        ],
        selected: {_mode},
        onSelectionChanged: (newSelection) {
          setState(() {
            _mode = newSelection.first;
            _fetchData();
          });
        },
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          selectedForegroundColor: theme.colorScheme.primary,
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
    );
  }

  Widget _buildDatePicker(ThemeData theme) {
    String label = _mode == AnalyticsMode.day
        ? "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}"
        : "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          _mode == AnalyticsMode.day ? "Selected Day" : "Selected Month",
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        trailing: TextButton.icon(
          onPressed: () => _selectDate(context),
          icon: const Icon(Icons.edit_calendar_rounded, size: 20),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(ThemeData theme, double total) {
    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 75,
              startDegreeOffset: -90,
              sections: _generateSections(theme),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _mode == AnalyticsMode.day ? "Daily Total" : "Monthly Total",
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              Text(
                "Rs. ${total.toInt()}",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateSections(ThemeData theme) {
    final List<Color> sectionColors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFFEF4444),
      const Color(0xFF06B6D4),
    ];

    int i = 0;
    return _consumptionData.entries.map((entry) {
      final color = sectionColors[i % sectionColors.length];
      i++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '',
        radius: 25,
      );
    }).toList();
  }

  Widget _buildLegend(ThemeData theme) {
    final List<Color> sectionColors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFFEF4444),
      const Color(0xFF06B6D4),
    ];

    int i = 0;
    return Column(
      children: _consumptionData.entries.map((entry) {
        final color = sectionColors[i % sectionColors.length];
        i++;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                "Rs. ${entry.value.toInt()}",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pie_chart_outline_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _mode == AnalyticsMode.day
                ? "No consumption data for this day"
                : "No consumption data for this month",
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      helpText: _mode == AnalyticsMode.day ? 'Select Day' : 'Select Month',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _fetchData();
    }
  }
}