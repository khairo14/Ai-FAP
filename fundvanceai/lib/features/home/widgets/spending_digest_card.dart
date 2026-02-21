import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fundvanceai/shared/services/spending_digest_service.dart';
import 'package:fundvanceai/features/analytics/screens/smart_insights_screen.dart';

/// A home-screen widget that shows an AI-generated monthly spending digest.
/// Loads lazily and collapses when there is no data.
class SpendingDigestCard extends StatefulWidget {
  const SpendingDigestCard({super.key});

  @override
  State<SpendingDigestCard> createState() => _SpendingDigestCardState();
}

class _SpendingDigestCardState extends State<SpendingDigestCard> {
  final _service = SpendingDigestService();
  SpendingDigest? _digest;
  bool _loading = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _service.generateMonthlyDigest();
      if (!mounted) return;
      setState(() {
        _digest = d;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_digest == null || _digest!.isEmpty) return const SizedBox.shrink();

    final digest = _digest!;
    final theme = Theme.of(context);
    final monthName = DateFormat('MMMM yyyy').format(digest.month);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.auto_awesome,
                        size: 18, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Spending Digest',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          monthName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Always-visible first line ─────────────────────────────
              if (digest.lines.isNotEmpty)
                _DigestLineRow(line: digest.lines.first),

              // ── Expanded lines ────────────────────────────────────────
              if (_expanded) ...[
                const SizedBox(height: 4),
                ...digest.lines.skip(1).map((l) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _DigestLineRow(line: l),
                    )),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SmartInsightsScreen()),
                    ),
                    icon: const Icon(Icons.lightbulb_outline, size: 16),
                    label: const Text('Full Insights'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DigestLineRow extends StatelessWidget {
  final DigestLine line;

  const _DigestLineRow({required this.line});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(line.emoji,
            style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            line.text,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.4,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }
}
