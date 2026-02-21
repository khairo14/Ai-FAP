import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fundvanceai/features/goals/goal_provider.dart';
import 'package:fundvanceai/features/goals/screens/goal_form_screen.dart';
import 'package:fundvanceai/features/goals/screens/goal_detail_screen.dart';
import 'package:fundvanceai/shared/models/goal.dart';

class GoalListScreen extends StatefulWidget {
  const GoalListScreen({super.key});

  @override
  State<GoalListScreen> createState() => _GoalListScreenState();
}

class _GoalListScreenState extends State<GoalListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoalProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<GoalProvider>().loadGoals();
  }

  Future<void> _addGoal() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GoalFormScreen()),
    );
  }

  void _openDetail(Goal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        backgroundColor: colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addGoal,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
      body: Consumer<GoalProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && !provider.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                      onPressed: _refresh,
                      child: const Text('Retry')),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _GoalTab(
                goals: provider.activeGoals,
                onRefresh: _refresh,
                onTap: _openDetail,
                empty: _EmptyState(
                  icon: Icons.flag_outlined,
                  title: 'No active goals',
                  subtitle: 'Tap + to set your first financial goal',
                ),
              ),
              _GoalTab(
                goals: provider.completedGoals,
                onRefresh: _refresh,
                onTap: _openDetail,
                empty: _EmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'No completed goals yet',
                  subtitle: 'Keep working – you\'ll get there!',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _GoalTab extends StatelessWidget {
  final List<Goal> goals;
  final Future<void> Function() onRefresh;
  final void Function(Goal) onTap;
  final Widget empty;

  const _GoalTab({
    required this.goals,
    required this.onRefresh,
    required this.onTap,
    required this.empty,
  });

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) return empty;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: goals.length,
        itemBuilder: (context, i) =>
            _GoalCard(goal: goals[i], onTap: () => onTap(goals[i])),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;

  const _GoalCard({required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = goal.progressPercent.clamp(0.0, 1.0);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    Color ringColor = goal.isCompleted
        ? Colors.green
        : goal.progressPercent >= 0.75
            ? colorScheme.primary
            : goal.progressPercent >= 0.5
                ? Colors.orange
                : colorScheme.secondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Circular progress ring
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      color: ringColor,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                    Icon(goal.goalType.icon, size: 22, color: ringColor),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(goal.title,
                              style: textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        if (goal.isCompleted)
                          const Icon(Icons.check_circle,
                              size: 18, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currency.format(goal.currentAmount)} / ${currency.format(goal.targetAmount)}',
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress,
                      color: ringColor,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant),
                        ),
                        if (goal.targetDate != null && !goal.isCompleted)
                          Text(
                            _dueLabel(goal),
                            style: textTheme.labelSmall?.copyWith(
                                color: goal.daysRemaining != null &&
                                        goal.daysRemaining! < 30
                                    ? colorScheme.error
                                    : colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _dueLabel(Goal goal) {
    final days = goal.daysRemaining;
    if (days == null) return '';
    if (days < 0) return 'Overdue';
    if (days == 0) return 'Due today';
    if (days == 1) return '1 day left';
    if (days < 30) return '$days days left';
    final months = (days / 30).floor();
    return '$months mo left';
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
