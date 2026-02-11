import 'package:flutter/material.dart';

/// Settings screen placeholder for enhanced application features
/// Will be expanded as more settings are needed
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
              color: Colors.indigo.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.settings,
              size: 64,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Advanced Settings',
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
              color: Colors.indigo,
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
                  icon: Icons.notifications,
                  title: 'Notifications',
                  description: 'Budget alerts and reminders',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  icon: Icons.backup,
                  title: 'Data Backup',
                  description: 'Cloud backup and sync settings',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  icon: Icons.security,
                  title: 'Security',
                  description: 'Privacy and security preferences',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  icon: Icons.palette,
                  title: 'Appearance',
                  description: 'Themes and display preferences',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'For now, currency settings are available in the main app.',
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
          color: Colors.indigo,
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