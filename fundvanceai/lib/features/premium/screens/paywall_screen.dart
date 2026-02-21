import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:fundvanceai/features/premium/premium_provider.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Package? _selected;

  static const _features = [
    (Icons.picture_as_pdf_outlined, 'PDF Report Export',
        'Download branded financial reports'),
    (Icons.flag_outlined, 'Unlimited Goals',
        'Create as many savings goals as you need'),
    (Icons.credit_card_off_outlined, 'Debt Payoff Planner',
        'Snowball & avalanche payoff simulations'),
    (Icons.repeat_outlined, 'Subscription Tracker',
        'Auto-detect recurring charges'),
    (Icons.smart_toy_outlined, 'AI Smart Insights',
        'Personalised tips powered by AI'),
    (Icons.bar_chart_outlined, 'Advanced Reports',
        'Weekly & monthly detailed breakdowns'),
    (Icons.notifications_active_outlined, 'Budget Alerts',
        'Instant OS notifications when limits are hit'),
    (Icons.support_agent_outlined, 'Priority Support',
        'Get help faster when you need it'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PremiumProvider>();
      if (!provider.isLoaded) provider.initialize();
    });
  }

  Future<void> _purchase() async {
    if (_selected == null) return;
    final provider = context.read<PremiumProvider>();
    final result = await provider.purchase(_selected!);

    if (!mounted) return;
    if (result.success) {
      _showSuccess();
    } else if (!result.cancelled && result.error != null) {
      _showError(result.error!);
    }
  }

  Future<void> _restore() async {
    final provider = context.read<PremiumProvider>();
    final result = await provider.restore();
    if (!mounted) return;
    if (result.success) {
      _showSuccess();
    } else if (result.error != null) {
      _showError(result.error!);
    }
  }

  void _showSuccess() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Welcome to FundVance Pro!'),
        backgroundColor: Color(0xFF66BB6A),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _restore,
            child: const Text('Restore'),
          ),
        ],
      ),
      body: Consumer<PremiumProvider>(
        builder: (context, provider, _) {
          // ── Already premium ──────────────────────────────────────────
          if (provider.isPremium) {
            return _AlreadyPremiumView(
                onClose: () => Navigator.of(context).pop());
          }

          // ── Loading ──────────────────────────────────────────────────
          if (provider.isLoading && !provider.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── Error loading offerings ──────────────────────────────────
          if (!provider.isLoaded) {
            return _ErrorView(
              onRetry: () => provider.initialize(),
            );
          }

          // Set default selection to annual (best value)
          _selected ??=
              provider.annualPackage ?? provider.monthlyPackage;

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            children: [
              // ── Hero ─────────────────────────────────────────────────
              const SizedBox(height: 8),
              _HeroSection(colorScheme: colorScheme),
              const SizedBox(height: 32),

              // ── Features ─────────────────────────────────────────────
              Text('Everything in Pro',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: 12),
              ..._features.map((f) => _FeatureRow(
                    icon: f.$1,
                    title: f.$2,
                    subtitle: f.$3,
                    color: colorScheme.primary,
                  )),
              const SizedBox(height: 28),

              // ── Plan selector ─────────────────────────────────────────
              Text('Choose your plan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: 12),

              if (provider.annualPackage != null)
                _PlanCard(
                  package: provider.annualPackage!,
                  isSelected: _selected == provider.annualPackage,
                  isBestValue: true,
                  trialDays: 14,
                  onTap: () =>
                      setState(() => _selected = provider.annualPackage),
                ),
              const SizedBox(height: 10),
              if (provider.monthlyPackage != null)
                _PlanCard(
                  package: provider.monthlyPackage!,
                  isSelected: _selected == provider.monthlyPackage,
                  trialDays: 14,
                  onTap: () =>
                      setState(() => _selected = provider.monthlyPackage),
                ),
              const SizedBox(height: 28),

              // ── CTA ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: provider.isLoading || _selected == null
                      ? null
                      : _purchase,
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Start 14-Day Free Trial',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'No charge for 14 days. Cancel anytime.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Payment will be charged to your App Store / Google Play account '
                'at confirmation of purchase. Subscription auto-renews unless '
                'cancelled at least 24 hours before the end of the period.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 10,
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
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final ColorScheme colorScheme;
  const _HeroSection({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.workspace_premium_rounded,
              size: 44, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          'FundVance Pro',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Unlock the full power of your AI financial assistant',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: color, size: 18),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Package package;
  final bool isSelected;
  final bool isBestValue;
  final int trialDays;
  final VoidCallback onTap;

  const _PlanCard({
    required this.package,
    required this.isSelected,
    this.isBestValue = false,
    required this.trialDays,
    required this.onTap,
  });

  String _perMonthPrice() {
    final product = package.storeProduct;
    if (package.packageType == PackageType.annual) {
      // Show per-month equivalent
      final perMonth = product.price / 12;
      final symbol = product.currencyCode == 'USD' ? '\$' : '';
      return '${symbol}${perMonth.toStringAsFixed(2)}/mo';
    }
    return product.priceString;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final product = package.storeProduct;
    final isAnnual = package.packageType == PackageType.annual;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : colorScheme.surface,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Radio
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: 2),
                      color: isSelected ? colorScheme.primary : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.circle, size: 10, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  // Labels
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAnnual ? 'Annual' : 'Monthly',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          isAnnual
                              ? '${product.priceString}/year · $trialDays-day free trial'
                              : '${product.priceString}/month · $trialDays-day free trial',
                          style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  // Per-month price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _perMonthPrice(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          fontSize: 14,
                        ),
                      ),
                      if (isAnnual)
                        Text(
                          'billed annually',
                          style: TextStyle(
                              fontSize: 10, color: colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Best value badge
            if (isBestValue)
              Positioned(
                top: 0,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(6)),
                  ),
                  child: Text(
                    'BEST VALUE',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlreadyPremiumView extends StatelessWidget {
  final VoidCallback onClose;
  const _AlreadyPremiumView({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded,
                size: 80, color: colorScheme.primary),
            const SizedBox(height: 20),
            Text('You\'re on Pro!',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'All premium features are unlocked. Thank you for supporting FundVance AI!',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            FilledButton(onPressed: onClose, child: const Text('Continue')),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 56, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Could not load plans',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Check your connection and try again.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
