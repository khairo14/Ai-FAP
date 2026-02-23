import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Base shimmer wrapper that adapts its highlight/base colours to
/// the active [ThemeData] (works in both light and dark modes).
class _ShimmerWrapper extends StatelessWidget {
  const _ShimmerWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: child,
    );
  }
}

/// A shimmering placeholder box, used as a building block for all skeletons.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List tile skeleton (expenses, income, notifications …)
// ---------------------------------------------------------------------------

/// One shimmering list tile, matching the typical leading-icon + text layout.
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Leading circle icon
            const ShimmerBox(width: 44, height: 44, borderRadius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                      width: MediaQuery.of(context).size.width * 0.45,
                      height: 14),
                  const SizedBox(height: 6),
                  ShimmerBox(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: 11),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShimmerBox(width: 64, height: 14),
                SizedBox(height: 6),
                ShimmerBox(width: 40, height: 11),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A full list of [ShimmerListTile]s, optionally preceded by a date header.
class ShimmerListView extends StatelessWidget {
  const ShimmerListView({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (_, i) => const ShimmerListTile(),
    );
  }
}

// ---------------------------------------------------------------------------
// Card skeleton (budgets, goals, debts …)
// ---------------------------------------------------------------------------

/// A shimmering card with an optional progress-bar row underneath the title.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key, this.showProgressBar = false});

  final bool showProgressBar;

  @override
  Widget build(BuildContext context) {
    final w =
        MediaQuery.of(context).size.width - 32; // full-width minus padding
    return _ShimmerWrapper(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ShimmerBox(width: 40, height: 40, borderRadius: 12),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: w * 0.4, height: 14),
                    const SizedBox(height: 6),
                    ShimmerBox(width: w * 0.25, height: 11),
                  ],
                ),
                const Spacer(),
                const ShimmerBox(width: 72, height: 22, borderRadius: 8),
              ],
            ),
            if (showProgressBar) ...[
              const SizedBox(height: 14),
              ShimmerBox(width: w, height: 8, borderRadius: 4),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(width: w * 0.25, height: 10),
                  ShimmerBox(width: w * 0.2, height: 10),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Several [ShimmerCard] placeholders in a scrollable column.
class ShimmerCardList extends StatelessWidget {
  const ShimmerCardList({
    super.key,
    this.itemCount = 5,
    this.showProgressBar = false,
  });

  final int itemCount;
  final bool showProgressBar;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (_, __) => ShimmerCard(showProgressBar: showProgressBar),
    );
  }
}

// ---------------------------------------------------------------------------
// Home dashboard skeleton
// ---------------------------------------------------------------------------

/// Full shimmer placeholder for the Home screen while [HomeProvider] loads.
class ShimmerHomeDashboard extends StatelessWidget {
  const ShimmerHomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width - 32;
    return _ShimmerWrapper(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card placeholder
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const ShimmerBox(width: 48, height: 48, borderRadius: 12),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(width: w * 0.35, height: 16),
                          const SizedBox(height: 6),
                          ShimmerBox(width: w * 0.5, height: 22),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ShimmerBox(width: w * 0.6, height: 36, borderRadius: 12),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Financial health card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: w * 0.4, height: 16),
                  const SizedBox(height: 12),
                  ShimmerBox(
                      width: double.infinity, height: 10, borderRadius: 5),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick actions row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                3,
                (_) => const Column(
                  children: [
                    ShimmerBox(width: 56, height: 56, borderRadius: 16),
                    SizedBox(height: 6),
                    ShimmerBox(width: 56, height: 11),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Overview cards row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ShimmerBox(
                            width: 24, height: 24, borderRadius: 6),
                        const SizedBox(height: 8),
                        const ShimmerBox(width: 50, height: 11),
                        const SizedBox(height: 6),
                        ShimmerBox(width: w * 0.25, height: 22),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ShimmerBox(
                            width: 24, height: 24, borderRadius: 6),
                        const SizedBox(height: 8),
                        const ShimmerBox(width: 50, height: 11),
                        const SizedBox(height: 6),
                        ShimmerBox(width: w * 0.25, height: 22),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent transactions header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: w * 0.4, height: 16),
                ShimmerBox(width: 60, height: 11),
              ],
            ),
            const SizedBox(height: 12),

            // Recent transactions list
            ...List.generate(5, (_) => const ShimmerListTile()),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Convenience full-screen wrappers
// ---------------------------------------------------------------------------

/// Drop-in replacement for `Center(child: CircularProgressIndicator())`
/// on list screens that show a vertically scrollable list.
class ShimmerListScreen extends StatelessWidget {
  const ShimmerListScreen({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: ShimmerListView(itemCount: itemCount),
    );
  }
}

/// Drop-in replacement for card-based screens (budgets, goals, debts).
class ShimmerCardScreen extends StatelessWidget {
  const ShimmerCardScreen({
    super.key,
    this.itemCount = 5,
    this.showProgressBar = false,
  });

  final int itemCount;
  final bool showProgressBar;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: List.generate(
          itemCount,
          (_) => ShimmerCard(showProgressBar: showProgressBar),
        ),
      ),
    );
  }
}
