import 'package:flutter/material.dart';

/// Account management screen placeholder for enhanced financial features
/// Will be fully implemented in Step 3 of the implementation roadmap
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Management'),
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
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance,
              size: 64,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Account Management',
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
              color: Colors.blue,
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
                  icon: Icons.account_balance,
                  title: 'Bank Accounts',
                  description: 'Savings, Checking accounts',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  icon: Icons.phone_android,
                  title: 'Online Banks',
                  description: 'GCash, Wise, PayPal, Maya',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  icon: Icons.wallet,
                  title: 'Wallets & Cash',
                  description: 'Physical cash management',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  icon: Icons.credit_card,
                  title: 'Credit Cards',
                  description: 'Credit card balance tracking',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'This feature is part of Step 3 in our implementation roadmap.',
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
          color: Colors.blue,
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