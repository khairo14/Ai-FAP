import 'package:flutter/material.dart';

/// Category management screen placeholder for enhanced financial features 
/// Will be fully implemented in Step 6 of the implementation roadmap
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
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
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.category,
              size: 64,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Category Management',
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
              color: Colors.orange,
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
                  icon: Icons.shopping_cart,
                  title: 'Expense Categories',
                  description: 'Food, Transportation, Entertainment, etc.',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  icon: Icons.money,
                  title: 'Income Categories',
                  description: 'Salary, Freelance, Business, Investment',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  icon: Icons.edit,
                  title: 'Custom Categories',
                  description: 'Create, edit, and delete custom categories',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  icon: Icons.color_lens,
                  title: 'Category Colors',
                  description: 'Customize category icons and colors',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'This feature is part of Step 6 in our implementation roadmap.',
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
          color: Colors.orange,
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