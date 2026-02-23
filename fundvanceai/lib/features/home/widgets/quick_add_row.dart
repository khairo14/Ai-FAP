import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../expenses/expense_provider.dart';
import '../../expenses/screens/expense_form_screen.dart';
import '../home_provider.dart';
import '../../../core/utils/icon_helper.dart';

/// Horizontal scrollable row of one-tap shortcuts for the user's most frequent
/// recent expenses. Shown on the home screen below the welcome section.
class QuickAddRow extends StatefulWidget {
  const QuickAddRow({super.key});

  @override
  State<QuickAddRow> createState() => _QuickAddRowState();
}

class _QuickAddRowState extends State<QuickAddRow> {
  @override
  void initState() {
    super.initState();
    // Load expense history on first render if not already loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ep = context.read<ExpenseProvider>();
      if (ep.expenses.isEmpty && !ep.isLoading) {
        ep.loadExpenses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final shortcuts = expenseProvider.frequentExpenseShortcuts;

    // Nothing to show if the user has no history yet.
    if (shortcuts.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Row header ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(
                Icons.bolt,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Quick Add',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(last 30 days)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Chips ────────────────────────────────────────────────────────────
        SizedBox(
          height: 106,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: shortcuts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return _QuickAddChip(shortcut: shortcuts[index]);
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _QuickAddChip extends StatelessWidget {
  final QuickAddShortcut shortcut;

  const _QuickAddChip({required this.shortcut});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Resolve category color
    Color iconBg;
    Color iconFg;
    if (shortcut.categoryColor != null && shortcut.categoryColor!.isNotEmpty) {
      try {
        iconFg = IconHelper.hexToColor(shortcut.categoryColor!);
        iconBg = iconFg.withValues(alpha: 0.12);
      } catch (_) {
        iconFg = colorScheme.primary;
        iconBg = colorScheme.primary.withValues(alpha: 0.12);
      }
    } else {
      iconFg = colorScheme.primary;
      iconBg = colorScheme.primaryContainer;
    }

    final amountText = NumberFormat.compact().format(shortcut.amount);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openForm(context),
        child: Container(
          width: 82,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: IconHelper.getIcon(
                    shortcut.categoryIcon,
                    size: 20,
                    color: iconFg,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Merchant name
              Text(
                shortcut.merchant,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              // Last amount
              Text(
                amountText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    final homeProvider = context.read<HomeProvider>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(
          initialMerchant: shortcut.merchant,
          initialCategoryId: shortcut.categoryId,
          initialAmount: shortcut.amount,
          initialAccountId: shortcut.accountId,
        ),
      ),
    );
    if (result == true && context.mounted) {
      homeProvider.loadDashboardData(showLoading: false);
    }
  }
}
