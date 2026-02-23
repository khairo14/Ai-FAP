import 'package:flutter/material.dart';
import '../../../shared/models/tax_preset.dart';
import '../../../shared/services/tax_settings_service.dart';
import '../../income/income_provider.dart';
import 'package:provider/provider.dart';

/// Tax Settings screen — browse presets & manage user default tax rates
class TaxSettingsScreen extends StatefulWidget {
  const TaxSettingsScreen({super.key});

  @override
  State<TaxSettingsScreen> createState() => _TaxSettingsScreenState();
}

class _TaxSettingsScreenState extends State<TaxSettingsScreen>
    with SingleTickerProviderStateMixin {
  final _service = TaxSettingsService();
  late TabController _tabs;

  List<TaxPreset> _presets = [];
  List<UserDefaultTaxRate> _myDefaults = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
    // Ensure income categories are loaded for the save-as-default dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncomeProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getPresets(),
        _service.getUserDefaults(),
      ]);
      if (mounted) {
        setState(() {
          _presets = results[0] as List<TaxPreset>;
          _myDefaults = results[1] as List<UserDefaultTaxRate>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Settings'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.bookmark_outline), text: 'My Defaults'),
            Tab(icon: Icon(Icons.public), text: 'Presets'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _buildMyDefaults(theme),
                    _buildPresets(theme),
                  ],
                ),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );

  // ─── My Defaults tab ───────────────────────────────────────────────────────

  Widget _buildMyDefaults(ThemeData theme) {
    if (_myDefaults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 72,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            Text('No saved tax rates yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Go to the Presets tab and save one\nfor an income category.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _myDefaults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final rate = _myDefaults[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.percent,
                  color: theme.colorScheme.primary, size: 20),
            ),
            title: Text(rate.taxName ?? rate.taxType,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rate: ${rate.rateLabel}'),
                if (rate.categoryName != null)
                  Text('Category: ${rate.categoryName}',
                      style: theme.textTheme.bodySmall),
                if (rate.categoryName == null)
                  Text('Applies to all categories',
                      style: theme.textTheme.bodySmall),
              ],
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete',
              onPressed: () => _deleteDefault(rate),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteDefault(UserDefaultTaxRate rate) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete default rate?'),
        content: Text(
            'Remove "${rate.taxName ?? rate.taxType}" from your saved defaults?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.deleteDefault(rate.id);
      setState(() => _myDefaults.removeWhere((r) => r.id == rate.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default tax rate removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── Presets tab ───────────────────────────────────────────────────────────

  Widget _buildPresets(ThemeData theme) {
    // Group presets by country
    final grouped = <String, List<TaxPreset>>{};
    for (final p in _presets) {
      grouped.putIfAbsent(p.countryCode, () => []).add(p);
    }

    if (grouped.isEmpty) {
      return Center(
          child:
              Text('No presets available', style: theme.textTheme.titleMedium));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in grouped.entries) ...[
          // Country header
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              entry.value.first.countryLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...entry.value.map((preset) => _buildPresetCard(preset, theme)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildPresetCard(TaxPreset preset, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: preset.isMandatory
              ? Colors.red.withValues(alpha: 0.15)
              : theme.colorScheme.primaryContainer,
          child: Icon(
            preset.isMandatory ? Icons.gavel : Icons.percent,
            size: 20,
            color: preset.isMandatory ? Colors.red : theme.colorScheme.primary,
          ),
        ),
        title: Text(preset.taxName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${preset.rateLabel}  •  ${preset.taxType}'),
            if (preset.taxAuthority != null)
              Text(preset.taxAuthority!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        isThreeLine: preset.taxAuthority != null,
        trailing: TextButton.icon(
          icon: const Icon(Icons.bookmark_add_outlined, size: 18),
          label: const Text('Save'),
          onPressed: () => _showSaveDialog(preset),
        ),
      ),
    );
  }

  Future<void> _showSaveDialog(TaxPreset preset) async {
    final incomeProvider = context.read<IncomeProvider>();
    String? selectedCategoryId;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cats = incomeProvider.categories;
          return AlertDialog(
            title: Text('Save "${preset.taxName}"'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Which income category should this apply to?',
                    style: Theme.of(ctx).textTheme.bodyMedium),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Income Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  hint: const Text('All categories'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All categories'),
                    ),
                    ...cats.map(
                      (cat) => DropdownMenuItem<String?>(
                        value: cat.id,
                        child: Text(cat.name),
                      ),
                    ),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedCategoryId = v),
                ),
                const SizedBox(height: 8),
                Text(
                  preset.rateLabel,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        color: Theme.of(ctx).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    final saved = await _service.savePresetAsDefault(
                      preset: preset,
                      categoryId: selectedCategoryId,
                    );
                    if (mounted) {
                      setState(() => _myDefaults.insert(0, saved));
                      _tabs.animateTo(0); // switch to My Defaults tab
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('"${preset.taxName}" saved as default')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
