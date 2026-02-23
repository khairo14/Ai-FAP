import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fundvanceai/features/premium/premium_provider.dart';
import 'package:fundvanceai/features/premium/screens/paywall_screen.dart';

/// Wraps a widget tree and shows a "Pro feature" lock screen when the user
/// is not on a premium plan. The locked view displays the feature name /
/// description and a CTA that opens the [PaywallScreen].
///
/// Usage:
/// ```dart
/// PremiumGate(
///   featureIcon: Icons.smart_toy_outlined,
///   featureName: 'AI Smart Insights',
///   featureDescription: 'Personalised spending analysis powered by AI',
///   child: MyFeatureBody(),
/// )
/// ```
class PremiumGate extends StatelessWidget {
  const PremiumGate({
    super.key,
    required this.child,
    required this.featureName,
    required this.featureDescription,
    required this.featureIcon,
  });

  final Widget child;
  final String featureName;
  final String featureDescription;
  final IconData featureIcon;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PremiumProvider>();

    // Still initialising — let the child render (avoids flash).
    if (provider.isLoading && !provider.isLoaded) return child;

    if (provider.isPremium) return child;

    return _LockedView(
      featureIcon: featureIcon,
      featureName: featureName,
      featureDescription: featureDescription,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Locked state UI
// ─────────────────────────────────────────────────────────────────────────────

class _LockedView extends StatelessWidget {
  const _LockedView({
    required this.featureIcon,
    required this.featureName,
    required this.featureDescription,
  });

  final IconData featureIcon;
  final String featureName;
  final String featureDescription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon stack: feature icon + lock badge
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.15),
                        colorScheme.tertiary.withValues(alpha: 0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(featureIcon,
                      size: 40, color: colorScheme.primary.withValues(alpha: 0.6)),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 2),
                    ),
                    child:
                        const Icon(Icons.lock_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Pro badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB347).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                    color: const Color(0xFFFFB347).withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium_rounded,
                      size: 13, color: Color(0xFFFFB347)),
                  SizedBox(width: 4),
                  Text(
                    'Pro Feature',
                    style: TextStyle(
                      color: Color(0xFFFFB347),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Text(
              featureName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              featureDescription,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                ),
                icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                label: const Text(
                  'Upgrade to Pro',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe later',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline premium badge tap-to-upgrade — useful for gating a single button
/// (e.g., the PDF export icon) without replacing the whole screen.
///
/// Wraps [child] in a tap handler that opens the paywall when not premium.
/// When premium, the original [onTap] is called normally.
class PremiumActionGate extends StatelessWidget {
  const PremiumActionGate({
    super.key,
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PremiumProvider>().isPremium;

    return GestureDetector(
      onTap: isPremium
          ? onTap
          : () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              ),
      child: Stack(
        children: [
          child,
          if (!isPremium)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFB347),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded,
                    size: 10, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
