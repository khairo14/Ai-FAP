import 'package:flutter/material.dart';

/// Transfer management screen placeholder for enhanced financial features
/// Will be fully implemented in Step 5 of the implementation roadmap
class TransfersScreen extends StatelessWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Transfers'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildComingSoonView(context),
    );
  }

  Widget _buildComingSoonView(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.swap_horiz,
              size: 64,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Account Transfers',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Coming Soon!',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.purple,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                _buildFeatureItem(
                  icon: Icons.account_balance_wallet,
                  title: 'Inter-Account Transfers',
                  description: 'Move money between your accounts',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  icon: Icons.attach_money,
                  title: 'Transfer Fees',
                  description: 'Automatic fee calculation and tracking',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  icon: Icons.language,
                  title: 'Multi-Currency',
                  description: 'Exchange rate conversion support',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  icon: Icons.history,
                  title: 'Transfer History',
                  description: 'Complete transfer tracking and logs',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'This feature is part of Step 5 in our implementation roadmap.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.purple,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}