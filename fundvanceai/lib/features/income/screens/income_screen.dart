import 'package:flutter/material.dart';

/// Income screen placeholder for enhanced financial features
/// Will be fully implemented in Step 4 of the implementation roadmap
class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income Tracking'),
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
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.money,
              size: 64,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Income Tracking',
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
              color: Colors.green,
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
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                _buildFeatureItem(
                  icon: Icons.category,
                  title: 'Income Categories',
                  description: 'Salary, Freelance, Business, Investment',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  icon: Icons.calculate,
                  title: 'Tax Calculation',
                  description: 'Automatic tax calculation with flexible rates',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  icon: Icons.analytics,
                  title: 'Income Analytics',
                  description: 'Track income trends and patterns',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'This feature is part of Step 4 in our implementation roadmap.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
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
          color: Colors.green,
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