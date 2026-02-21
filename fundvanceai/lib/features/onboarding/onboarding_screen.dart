import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fundvanceai/features/auth/screens/login_screen.dart';
import 'package:fundvanceai/features/auth/screens/signup_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding page data
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color iconColor;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.iconColor,
  });
}

const _pages = [
  _OnboardingPage(
    title: 'FundVance AI',
    subtitle: 'Your AI Financial Assistant',
    description:
        'Take control of your finances with smart insights, '
        'automated tracking, and personalised recommendations — '
        'all powered by AI.',
    icon: Icons.auto_graph_rounded,
    iconColor: Color(0xFF4ECDC4),
  ),
  _OnboardingPage(
    title: 'Track Every Dollar',
    subtitle: 'Know exactly where your money goes',
    description:
        'Log expenses in seconds, scan receipts with your camera, '
        'and let AI categorise everything for you. '
        'Set category budgets and get alerts before you overspend.',
    icon: Icons.receipt_long_rounded,
    iconColor: Color(0xFF45B7D1),
  ),
  _OnboardingPage(
    title: 'Plan & Grow',
    subtitle: 'Goals, debt payoff & budgets — all in one place',
    description:
        'Set savings goals with progress rings, tackle debt using '
        'snowball or avalanche strategies, and auto-detect '
        'recurring subscriptions you might be wasting.',
    icon: Icons.savings_rounded,
    iconColor: Color(0xFF66BB6A),
  ),
  _OnboardingPage(
    title: "You're Ready!",
    subtitle: 'Start your financial journey today',
    description:
        'Create a free account and add your first expense or savings goal. '
        'Your data stays private and secure — always.',
    icon: Icons.rocket_launch_rounded,
    iconColor: Color(0xFFFFB347),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const String prefKey = 'onboarding_complete';

  /// Mark onboarding as done in SharedPreferences.
  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, true);
  }

  /// Returns true when onboarding has already been seen.
  static Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefKey) ?? false;
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _goToSignUp() async {
    await OnboardingScreen.markComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  Future<void> _goToSignIn() async {
    await OnboardingScreen.markComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _skip() async {
    await OnboardingScreen.markComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip ────────────────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: AnimatedOpacity(
                opacity: isLast ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: isLast ? null : _skip,
                  child: const Text('Skip'),
                ),
              ),
            ),

            // ── Pages ───────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _PageContent(page: _pages[i]),
              ),
            ),

            // ── Dots ────────────────────────────────────────────────────
            _DotsIndicator(count: _pages.length, current: _currentPage),
            const SizedBox(height: 24),

            // ── Actions ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isLast
                    ? _LastPageActions(
                        key: const ValueKey('last'),
                        onSignUp: _goToSignUp,
                        onSignIn: _goToSignIn,
                      )
                    : _NextButton(
                        key: const ValueKey('next'),
                        onTap: _next,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;
  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon blob
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: page.iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 72,
              color: page.iconColor,
            ),
          ),
          const SizedBox(height: 36),

          // Title
          Text(
            page.title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            page.subtitle,
            style: textTheme.titleMedium?.copyWith(
              color: page.iconColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int current;
  const _DotsIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? primary : primary.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _NextButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NextButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onTap,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Next'),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _LastPageActions extends StatelessWidget {
  final VoidCallback onSignUp;
  final VoidCallback onSignIn;
  const _LastPageActions(
      {super.key, required this.onSignUp, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: onSignUp,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Create Free Account'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: onSignIn,
            child: const Text('I already have an account'),
          ),
        ),
      ],
    );
  }
}
