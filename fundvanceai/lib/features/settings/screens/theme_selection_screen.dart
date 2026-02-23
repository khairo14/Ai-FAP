import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fundvanceai/core/theme/app_themes.dart';
import 'package:fundvanceai/features/settings/theme_provider.dart';
import 'package:fundvanceai/features/premium/premium_provider.dart';
import 'package:fundvanceai/features/premium/screens/paywall_screen.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        backgroundColor: colorScheme.surface,
      ),
      body: Consumer2<ThemeProvider, PremiumProvider>(
        builder: (context, themeProvider, premiumProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Choose a theme',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Free: Light, Dark, Cream  ·  Pro: Midnight, Forest, Rose',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: AppThemes.allThemes.length,
                itemBuilder: (context, i) {
                  final meta = AppThemes.allThemes[i];
                  final isSelected = themeProvider.themeId == meta.id;
                  final isLocked = meta.isPremium && !premiumProvider.isPremium;

                  return _ThemeCard(
                    meta: meta,
                    isSelected: isSelected,
                    isLocked: isLocked,
                    onTap: () => _onTap(
                      context,
                      meta,
                      isLocked,
                      themeProvider,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              if (!premiumProvider.isPremium)
                _ProBanner(
                  onUpgrade: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _onTap(
    BuildContext context,
    ThemeMeta meta,
    bool isLocked,
    ThemeProvider themeProvider,
  ) {
    if (isLocked) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return;
    }
    themeProvider.setTheme(meta.id);
  }
}

// ── Theme Card ────────────────────────────────────────────────────────────────

class _ThemeCard extends StatelessWidget {
  final ThemeMeta meta;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.meta,
    required this.isSelected,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Swatch row
                  Row(
                    children: [
                      _Swatch(color: meta.swatchColors[1], size: 36),
                      const SizedBox(width: 6),
                      Column(
                        children: [
                          _Swatch(color: meta.swatchColors[0], size: 15),
                          const SizedBox(height: 6),
                          _Swatch(color: meta.swatchColors[2], size: 15),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    meta.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  _Badge(isPremium: meta.isPremium),
                ],
              ),
            ),
            // Selected checkmark
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: colorScheme.primary,
                  child: const Icon(Icons.check, size: 13, color: Colors.white),
                ),
              ),
            // Lock overlay
            if (isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child:
                        Icon(Icons.lock_rounded, size: 28, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final double size;
  const _Swatch({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: Colors.black.withValues(alpha: 0.08), width: 0.5),
        ),
      );
}

class _Badge extends StatelessWidget {
  final bool isPremium;
  const _Badge({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPremium
            ? const Color(0xFFC9A84C).withValues(alpha: 0.15)
            : colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isPremium ? '✦ Pro' : 'Free',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isPremium ? const Color(0xFFB8860B) : colorScheme.primary,
        ),
      ),
    );
  }
}

class _ProBanner extends StatelessWidget {
  final VoidCallback onUpgrade;
  const _ProBanner({required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFC9A84C).withValues(alpha: 0.15),
            const Color(0xFF1B2A4A).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFC9A84C).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: Color(0xFFC9A84C), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Unlock 3 Premium Themes',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  'Midnight, Forest & Rose — upgrade to Pro',
                  style: TextStyle(
                      fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onUpgrade,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC9A84C),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}
