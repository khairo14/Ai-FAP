import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fundvanceai/shared/services/analytics_service.dart';
import 'package:fundvanceai/shared/services/connectivity_service.dart';
import 'package:fundvanceai/features/auth/auth_provider.dart';
import 'package:fundvanceai/core/constants/currencies.dart';
import 'package:fundvanceai/features/analytics/screens/smart_insights_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final _analyticsService = AnalyticsService();

  bool _isLoading = true;
  String? _errorMessage;

  // Date range (default: current month)
  late DateTime _startDate;
  late DateTime _endDate;

  // Analytics data
  Map<String, double> _categoryBreakdown = {};
  Map<DateTime, double> _dailySpending = {};
  List<Map<String, dynamic>> _budgetComparisons = [];
  Map<String, dynamic> _summaryStats = {};
  Map<String, dynamic> _periodComparison = {};

  bool get _isOffline => !ConnectivityService.instance.isOnline;

  static bool _isNetworkError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('errno = 7') ||
        msg.contains('no address associated') ||
        msg.contains('authretryable') ||
        msg.contains('clientexception');
  }

  @override
  void initState() {
    super.initState();
    _initializeDates();
    _loadAnalytics();
  }

  void _initializeDates() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _loadAnalytics() async {
    if (_isOffline) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _analyticsService.getCategoryBreakdown(
          startDate: _startDate,
          endDate: _endDate,
        ),
        _analyticsService.getDailySpending(
          startDate: _startDate,
          endDate: _endDate,
        ),
        _analyticsService.getBudgetComparison(
          startDate: _startDate,
          endDate: _endDate,
        ),
        _analyticsService.getSummaryStats(
          startDate: _startDate,
          endDate: _endDate,
        ),
        _analyticsService.getPeriodComparison(
          currentStart: _startDate,
          currentEnd: _endDate,
        ),
      ]);

      setState(() {
        _categoryBreakdown = results[0] as Map<String, double>;
        _dailySpending = results[1] as Map<DateTime, double>;
        _budgetComparisons = results[2] as List<Map<String, dynamic>>;
        _summaryStats = results[3] as Map<String, dynamic>;
        _periodComparison = results[4] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = _isNetworkError(e) ? null : e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyCode =
        context.watch<AuthProvider>().userProfile?.currency ?? 'USD';
    final currencyData = Currencies.all.firstWhere(
      (c) => c.code == currencyCode,
      orElse: () =>
          const CurrencyData(code: 'USD', name: 'US Dollar', symbol: '\$'),
    );
    final symbol = currencyData.symbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showDateRangePicker,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading analytics',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAnalytics,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Smart insights banner
                        _SmartInsightsBanner(onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SmartInsightsScreen(),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),

                        // Date range display
                        _buildDateRangeCard(),
                        const SizedBox(height: 16),

                        // Summary stats cards
                        _buildSummaryCards(symbol),
                        const SizedBox(height: 24),

                        // Period comparison
                        if (_periodComparison.isNotEmpty)
                          _buildPeriodComparison(symbol),
                        const SizedBox(height: 24),

                        // Category breakdown pie chart
                        if (_categoryBreakdown.isNotEmpty) ...[
                          Text(
                            'Spending by Category',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildCategoryPieChart(symbol),
                          const SizedBox(height: 24),
                        ],

                        // Daily spending trend
                        if (_dailySpending.isNotEmpty) ...[
                          Text(
                            'Daily Spending Trend',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildDailySpendingChart(symbol),
                          const SizedBox(height: 24),
                        ],

                        // Budget vs Actual
                        if (_budgetComparisons.isNotEmpty) ...[
                          Text(
                            'Budget vs Actual',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildBudgetComparison(symbol),
                        ],

                        // Empty state
                        if (_categoryBreakdown.isEmpty &&
                            _dailySpending.isEmpty &&
                            _budgetComparisons.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.analytics_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No data for this period',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start adding expenses to see your analytics',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDateRangeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${DateFormat('MMM d, y').format(_startDate)} - ${DateFormat('MMM d, y').format(_endDate)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: _showDateRangePicker,
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(String currencySymbol) {
    final total = _summaryStats['total'] as double? ?? 0.0;
    final count = _summaryStats['count'] as int? ?? 0;
    final avgPerDay = _summaryStats['averagePerDay'] as double? ?? 0.0;
    final avgPerTransaction =
        _summaryStats['averagePerTransaction'] as double? ?? 0.0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Spent',
          '$currencySymbol${total.toStringAsFixed(2)}',
          Icons.payments,
          Colors.blue,
        ),
        _buildStatCard(
          'Transactions',
          count.toString(),
          Icons.receipt_long,
          Colors.green,
        ),
        _buildStatCard(
          'Daily Average',
          '$currencySymbol${avgPerDay.toStringAsFixed(2)}',
          Icons.today,
          Colors.orange,
        ),
        _buildStatCard(
          'Avg per Transaction',
          '$currencySymbol${avgPerTransaction.toStringAsFixed(2)}',
          Icons.shopping_cart,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Icon(icon, size: 20, color: color),
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodComparison(String currencySymbol) {
    final changeAmount = _periodComparison['changeAmount'] as double? ?? 0.0;
    final changePercentage =
        _periodComparison['changePercentage'] as double? ?? 0.0;
    final isIncrease = _periodComparison['isIncrease'] as bool? ?? false;

    return Card(
      color: isIncrease ? Colors.red[50] : Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isIncrease ? Icons.trending_up : Icons.trending_down,
              color: isIncrease ? Colors.red : Colors.green,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'vs Previous Period',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isIncrease ? '+' : ''}$currencySymbol${changeAmount.abs().toStringAsFixed(2)} (${changePercentage.abs().toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isIncrease ? Colors.red[700] : Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart(String currencySymbol) {
    final total = _categoryBreakdown.values
        .fold<double>(0.0, (sum, value) => sum + value);

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    int colorIndex = 0;
    final sections = _categoryBreakdown.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: _categoryBreakdown.entries.map((entry) {
            final index = _categoryBreakdown.keys.toList().indexOf(entry.key);
            final color = colors[index % colors.length];

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.key}: $currencySymbol${entry.value.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDailySpendingChart(String currencySymbol) {
    if (_dailySpending.isEmpty) return const SizedBox();

    final sortedEntries = _dailySpending.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final maxY =
        sortedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    final spots = sortedEntries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    currencySymbol + value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (sortedEntries.length / 7).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= sortedEntries.length) {
                    return const SizedBox();
                  }
                  final date = sortedEntries[value.toInt()].key;
                  return Text(
                    DateFormat('d').format(date),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          minY: 0,
          maxY: maxY * 1.1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetComparison(String currencySymbol) {
    return Column(
      children: _budgetComparisons.map((comparison) {
        final category = comparison['category'] as String;
        final budget = comparison['budget'] as double;
        final actual = comparison['actual'] as double;
        final percentage = comparison['percentage'] as double;

        Color progressColor;
        if (percentage < 70) {
          progressColor = Colors.green;
        } else if (percentage < 90) {
          progressColor = Colors.orange;
        } else if (percentage < 100) {
          progressColor = Colors.deepOrange;
        } else {
          progressColor = Colors.red;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$currencySymbol${actual.toStringAsFixed(2)} / $currencySymbol${budget.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}% used',
                      style: TextStyle(
                        fontSize: 12,
                        color: progressColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (percentage > 100)
                      Text(
                        'Over by $currencySymbol${(actual - budget).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Text(
                        '$currencySymbol${(budget - actual).toStringAsFixed(2)} remaining',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (BuildContext context) {
        DateTime tempStartDate = _startDate;
        DateTime tempEndDate = _endDate;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Date Range'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quick presets
                    Text(
                      'Quick Presets',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildPresetChip('This Month', () {
                          final now = DateTime.now();
                          setState(() {
                            tempStartDate = DateTime(now.year, now.month, 1);
                            tempEndDate = DateTime(now.year, now.month + 1, 0);
                          });
                        }),
                        _buildPresetChip('Last Month', () {
                          final now = DateTime.now();
                          setState(() {
                            tempStartDate =
                                DateTime(now.year, now.month - 1, 1);
                            tempEndDate = DateTime(now.year, now.month, 0);
                          });
                        }),
                        _buildPresetChip('Last 7 Days', () {
                          final now = DateTime.now();
                          setState(() {
                            tempStartDate =
                                now.subtract(const Duration(days: 6));
                            tempEndDate = now;
                          });
                        }),
                        _buildPresetChip('Last 30 Days', () {
                          final now = DateTime.now();
                          setState(() {
                            tempStartDate =
                                now.subtract(const Duration(days: 29));
                            tempEndDate = now;
                          });
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Custom date selection
                    ListTile(
                      leading: const Icon(Icons.date_range),
                      title: const Text('Start Date'),
                      subtitle:
                          Text(DateFormat('MMM d, y').format(tempStartDate)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: tempStartDate,
                          firstDate: DateTime(2020),
                          lastDate: tempEndDate,
                        );
                        if (date != null) {
                          setState(() {
                            tempStartDate = date;
                          });
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.date_range),
                      title: const Text('End Date'),
                      subtitle:
                          Text(DateFormat('MMM d, y').format(tempEndDate)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: tempEndDate,
                          firstDate: tempStartDate,
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            tempEndDate = date;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context,
                        DateTimeRange(start: tempStartDate, end: tempEndDate));
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAnalytics();
    }
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      onPressed: onTap,
      backgroundColor: Colors.grey[100],
    );
  }
}

// ─── Smart Insights Banner ────────────────────────────────────────────────────

class _SmartInsightsBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _SmartInsightsBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.tertiary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.lightbulb_outline,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Smart Insights',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'AI-powered budget alerts, anomaly detection & recurring expenses',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}
