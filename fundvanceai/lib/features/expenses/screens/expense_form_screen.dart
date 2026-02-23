import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fundvanceai/features/auth/auth_provider.dart';
import 'package:fundvanceai/features/expenses/expense_provider.dart';
import 'package:fundvanceai/features/accounts/account_provider.dart';
import 'package:fundvanceai/shared/models/expense.dart';
import 'package:fundvanceai/core/constants/currencies.dart';
import 'package:fundvanceai/core/utils/icon_helper.dart';
import 'package:fundvanceai/shared/services/receipt_service.dart';
import 'package:fundvanceai/shared/services/personalization_service.dart';
import 'package:fundvanceai/shared/services/auto_categorization_service.dart';
import 'receipt_review_screen.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense;
  final String? initialAccountId;
  final String? initialMerchant;
  final String? initialCategoryId;
  final double? initialAmount;

  const ExpenseFormScreen({
    super.key,
    this.expense,
    this.initialAccountId,
    this.initialMerchant,
    this.initialCategoryId,
    this.initialAmount,
  });

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagController = TextEditingController();
  final _merchantFocusNode = FocusNode();

  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  String? _selectedAccountId;
  String? _selectedCurrency;
  String? _selectedPaymentMethod;
  bool _isRecurring = false;
  String? _recurringFrequency;
  List<String> _tags = [];
  bool _showMerchantSuggestions = false;
  bool _isLoading = false;
  bool _isScanningReceipt = false;

  final _receiptService = ReceiptService();
  final _personalizationService = PersonalizationService();

  // Tracks the category ID that was auto-applied (keyword or personalization)
  String? _autoAppliedCategoryId;
  // True when personalization DB override was applied (vs keyword match)
  bool _personalizationApplied = false;
  // True when user explicitly chose a category from the dropdown
  bool _userPickedCategory = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final expenseProvider = context.read<ExpenseProvider>();
      final accountProvider = context.read<AccountProvider>();
      final authProvider = context.read<AuthProvider>();

      if (expenseProvider.categories.isEmpty) {
        expenseProvider.loadCategories();
      }
      if (accountProvider.accounts.isEmpty) {
        accountProvider.loadAccounts();
      }

      // Load recent expenses for merchant suggestions
      if (expenseProvider.expenses.isEmpty) {
        expenseProvider.loadExpenses();
      }

      // Pre-warm personalization cache
      _personalizationService.preload();

      // Set initial currency
      if (_selectedAccountId != null && accountProvider.accounts.isNotEmpty) {
        final account = accountProvider.accounts.firstWhere(
          (a) => a.id == _selectedAccountId,
          orElse: () => accountProvider.accounts.first,
        );
        setState(() => _selectedCurrency = account.currency);
      } else {
        setState(() => _selectedCurrency = authProvider.userCurrency);
      }
    });

    // Show/hide merchant suggestions on focus change.
    // On unfocus, delay hiding by 250 ms so chip star-taps can complete
    // before the suggestions section disappears.
    _merchantFocusNode.addListener(() {
      if (_merchantFocusNode.hasFocus) {
        setState(() => _showMerchantSuggestions = true);
      } else {
        _onMerchantUnfocused();
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) setState(() => _showMerchantSuggestions = false);
        });
      }
    });

    if (widget.expense != null) {
      _amountController.text = widget.expense!.amount.toStringAsFixed(2);
      _merchantController.text = widget.expense!.merchant ?? '';
      _descriptionController.text = widget.expense!.description ?? '';
      _notesController.text = widget.expense!.notes ?? '';
      _tags = List<String>.from(widget.expense!.tags);
      _selectedDate = widget.expense!.date;
      _selectedCategoryId = widget.expense!.categoryId;
      _selectedAccountId = widget.expense!.accountId;
      _selectedPaymentMethod = widget.expense!.paymentMethod;
      _isRecurring = widget.expense!.isRecurring;
      _recurringFrequency = widget.expense!.recurringFrequency;
    } else {
      // For new expenses, pre-select account if passed (e.g. from account details screen)
      if (widget.initialAccountId != null) {
        _selectedAccountId = widget.initialAccountId;
      }
      // Pre-fill from quick-add shortcut
      if (widget.initialMerchant != null) {
        _merchantController.text = widget.initialMerchant!;
      }
      if (widget.initialCategoryId != null) {
        _selectedCategoryId = widget.initialCategoryId;
      }
      if (widget.initialAmount != null) {
        _amountController.text = widget.initialAmount!.toStringAsFixed(2);
      }
      // For new expenses, wait for account selection to set payment method
      _selectedPaymentMethod = null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    _merchantFocusNode.dispose();
    _receiptService.dispose();
    super.dispose();
  }

  // ── Receipt scanning ──────────────────────────────────────────────────────

  Future<void> _scanReceipt() async {
    // Show source picker
    final source = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 20),
                  const SizedBox(width: 8),
                  Text('Scan Receipt',
                      style: Theme.of(ctx).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      color: Colors.blue,
                      onTap: () => Navigator.pop(ctx, 'camera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      color: Colors.purple,
                      onTap: () => Navigator.pop(ctx, 'gallery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    setState(() => _isScanningReceipt = true);

    try {
      final result = source == 'camera'
          ? await _receiptService.scanFromCamera()
          : await _receiptService.scanFromGallery();

      if (!mounted) return;
      setState(() => _isScanningReceipt = false);

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not extract text from image.'),
        ));
        return;
      }

      // Open review screen
      final categories = context.read<ExpenseProvider>().categories;
      final confirmed = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => ReceiptReviewScreen(
            result: result,
            categories: categories,
          ),
          fullscreenDialog: true,
        ),
      );

      if (confirmed != null && mounted) {
        _applyReceiptData(confirmed);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanningReceipt = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
      }
    }
  }

  /// Called when the merchant field loses focus.
  /// Tries to auto-apply a category if none is selected:
  /// 1. Personalized override from DB (highest priority)
  /// 2. Keyword-based suggestion from AutoCategorizationService
  Future<void> _onMerchantUnfocused() async {
    final merchant = _merchantController.text.trim();
    if (merchant.isEmpty) return;
    if (_selectedCategoryId != null) return; // already has a category

    // 1. Try personalized override
    final overrideCatId = await _personalizationService.getOverride(merchant);
    if (overrideCatId != null && mounted) {
      setState(() {
        _selectedCategoryId = overrideCatId;
        _autoAppliedCategoryId = overrideCatId;
        _personalizationApplied = true;
      });
      return;
    }

    // 2. Keyword-based fallback
    final catName = AutoCategorizationService.suggestFromMerchant(merchant);
    if (catName != null && mounted) {
      final expenseProvider = context.read<ExpenseProvider>();
      final matches = expenseProvider.categories.where(
        (c) => c.name.toLowerCase() == catName.toLowerCase(),
      );
      if (matches.isNotEmpty) {
        final catId = matches.first.id;
        setState(() {
          _selectedCategoryId = catId;
          _autoAppliedCategoryId = catId;
          _personalizationApplied = false;
        });
      }
    }
  }

  void _applyReceiptData(Map<String, dynamic> data) {
    setState(() {
      if (data['amount'] != null) {
        _amountController.text = (data['amount'] as double).toStringAsFixed(2);
      }
      if (data['date'] != null) {
        _selectedDate = data['date'] as DateTime;
      }
      if (data['merchant'] != null && (data['merchant'] as String).isNotEmpty) {
        _merchantController.text = data['merchant'] as String;
      }
      if (data['categoryId'] != null) {
        _selectedCategoryId = data['categoryId'] as String;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Receipt data applied — review and save'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    ));
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    // Save category override if user explicitly chose a different category
    if (_userPickedCategory &&
        _merchantController.text.trim().isNotEmpty &&
        _selectedCategoryId != null) {
      await _personalizationService.saveOverride(
        _merchantController.text.trim(),
        _selectedCategoryId!,
      );
    }

    setState(() => _isLoading = true);
    if (!mounted) return;

    final provider = context.read<ExpenseProvider>();
    final amount = double.parse(_amountController.text);

    bool success;
    if (widget.expense != null) {
      success = await provider.updateExpense(
        id: widget.expense!.id,
        amount: amount,
        date: _selectedDate,
        categoryId: _selectedCategoryId,
        accountId: _selectedAccountId,
        paymentMethod: _selectedPaymentMethod,
        merchant:
            _merchantController.text.isEmpty ? null : _merchantController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        tags: _tags,
        isRecurring: _isRecurring,
        recurringFrequency: _isRecurring ? _recurringFrequency : null,
      );
    } else {
      success = await provider.addExpense(
        amount: amount,
        date: _selectedDate,
        categoryId: _selectedCategoryId,
        accountId: _selectedAccountId,
        paymentMethod: _selectedPaymentMethod,
        merchant:
            _merchantController.text.isEmpty ? null : _merchantController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        tags: _tags,
        isRecurring: _isRecurring,
        recurringFrequency: _isRecurring ? _recurringFrequency : null,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _addTag(String raw) {
    // Normalise: lowercase, strip leading #, trim whitespace
    final tag = raw.trim().toLowerCase().replaceFirst(RegExp(r'^#'), '');
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() => _tags.add(tag));
  }

  Widget _buildTagsField() {
    final theme = Theme.of(context);
    final teal = theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input row
        Row(
          children: [
            Icon(Icons.label_outline, color: teal, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _tagController,
                decoration: const InputDecoration(
                  labelText: 'Add tags (Optional)',
                  hintText: 'e.g. work, trip-bali',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (v) {
                  for (final part in v.split(RegExp(r'[,\s]+'))) {
                    _addTag(part);
                  }
                  _tagController.clear();
                },
              ),
            ),
            TextButton(
              onPressed: () {
                for (final part
                    in _tagController.text.split(RegExp(r'[,\s]+'))) {
                  _addTag(part);
                }
                _tagController.clear();
              },
              child: const Text('Add'),
            ),
          ],
        ),
        // Chips
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _tags
                .map(
                  (tag) => Chip(
                    label: Text('#$tag',
                        style: TextStyle(fontSize: 12, color: teal)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                    backgroundColor: teal.withValues(alpha: 0.08),
                    side: BorderSide(color: teal.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'Cash':
        return Icons.money;
      case 'Credit Card':
        return Icons.credit_card;
      case 'Debit Card':
        return Icons.payment;
      case 'Bank Transfer':
        return Icons.account_balance;
      case 'E-Wallet':
        return Icons.account_balance_wallet;
      case 'Online Banking':
        return Icons.computer;
      default:
        return Icons.payments;
    }
  }

  String _getPaymentMethodFromAccountType(String? accountTypeCategory) {
    if (accountTypeCategory == null) return 'Cash';

    // Use the account type category field for more reliable mapping
    switch (accountTypeCategory.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'credit':
        return 'Credit Card';
      case 'bank':
        return 'Debit Card'; // Traditional bank accounts with debit cards
      case 'online_bank':
      case 'crypto':
      case 'investment':
        return 'Online Banking'; // Online-only transactions
      case 'e_wallet':
        return 'E-Wallet';
      default:
        return 'Cash';
    }
  }

  void _onAccountChanged(String? accountId, List<dynamic> accounts) {
    setState(() {
      _selectedAccountId = accountId;

      // Auto-select payment method and currency based on selected account
      if (accountId != null) {
        final account = accounts.firstWhere((a) => a.id == accountId);
        _selectedPaymentMethod =
            _getPaymentMethodFromAccountType(account.accountTypeCategory);
        _selectedCurrency =
            account.currency; // Update currency to match account
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.expense != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
        actions: [
          // Scan receipt button — only for new expenses
          if (!isEditing)
            _isScanningReceipt
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.document_scanner_outlined),
                    tooltip: 'Scan Receipt',
                    onPressed: _scanReceipt,
                  ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final expenseProvider = context.read<ExpenseProvider>();
                final navigator = Navigator.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Expense?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  final success =
                      await expenseProvider.deleteExpense(widget.expense!.id);
                  if (success && mounted) {
                    navigator.pop(true);
                  }
                }
              },
            ),
        ],
      ),
      body: Consumer2<ExpenseProvider, AccountProvider>(
        builder: (context, expenseProvider, accountProvider, child) {
          if (expenseProvider.categories.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final authProvider = context.read<AuthProvider>();
          // Use selected account's currency, fallback to user's default currency
          final currencySymbol = Currencies.getSymbol(
              _selectedCurrency ?? authProvider.userCurrency);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Details Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Expense Name (Merchant)
                        TextFormField(
                          controller: _merchantController,
                          focusNode: _merchantFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Expense Name',
                            hintText:
                                'e.g., McDonald\'s, Uber, Electricity Bill',
                            prefixIcon:
                                Icon(Icons.store, color: Colors.teal[400]),
                            helperText: 'What was this expense for?',
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        // Merchant suggestion chips (favourites always
                        // visible; recent only when field is focused)
                        Consumer<ExpenseProvider>(
                          builder: (ctx, provider, _) {
                            final favourites = provider.favouriteMerchants;
                            final recent = _showMerchantSuggestions
                                ? provider.recentMerchants
                                    .where((m) => !favourites.contains(m))
                                    .toList()
                                : <String>[];
                            if (favourites.isEmpty && recent.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            void selectMerchant(String merchant) {
                              _merchantController.text = merchant;
                              final catId =
                                  provider.getCategoryForMerchant(merchant);
                              if (catId != null) {
                                setState(() => _selectedCategoryId = catId);
                              }
                              _merchantFocusNode.unfocus();
                            }

                            return SizedBox(
                                width: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ── Favourites (always shown) ────────────
                                      if (favourites.isNotEmpty) ...[
                                        Text(
                                          'Favourites',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.amber[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children:
                                                favourites.map((merchant) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 4),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    ActionChip(
                                                      label: Text(merchant,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      12)),
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      backgroundColor:
                                                          Colors.amber[50],
                                                      side: BorderSide(
                                                          color: Colors
                                                              .amber[300]!,
                                                          width: 1),
                                                      tooltip: 'Tap to fill',
                                                      onPressed: () =>
                                                          selectMerchant(
                                                              merchant),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                          Icons.star_rounded,
                                                          size: 16,
                                                          color: Colors
                                                              .amber[600]),
                                                      tooltip: 'Unpin',
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(
                                                              minWidth: 24,
                                                              minHeight: 24),
                                                      onPressed: () => provider
                                                          .toggleFavourite(
                                                              merchant),
                                                    ),
                                                    const SizedBox(width: 4),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                      // ── Divider ─────────────────────────────
                                      if (favourites.isNotEmpty &&
                                          recent.isNotEmpty)
                                        const Divider(
                                            height: 16, thickness: 0.5),
                                      // ── Recent (only when field focused) ────
                                      if (recent.isNotEmpty) ...[
                                        Text(
                                          'Recent',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: recent.map((merchant) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 4),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    ActionChip(
                                                      label: Text(merchant,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      12)),
                                                      avatar: const Icon(
                                                          Icons.history,
                                                          size: 14),
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      tooltip: 'Tap to fill',
                                                      onPressed: () =>
                                                          selectMerchant(
                                                              merchant),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                          Icons
                                                              .star_border_rounded,
                                                          size: 16,
                                                          color: Colors
                                                              .amber[600]),
                                                      tooltip:
                                                          'Pin to Favourites',
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(
                                                              minWidth: 24,
                                                              minHeight: 24),
                                                      onPressed: () => provider
                                                          .toggleFavourite(
                                                              merchant),
                                                    ),
                                                    const SizedBox(width: 4),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ));
                          },
                        ),
                        const SizedBox(height: 16),

                        // Amount
                        TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            prefixIcon:
                                Icon(Icons.payments, color: Colors.purple[400]),
                            prefixText: '$currencySymbol ',
                            hintText: '0.00',
                          ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            if (double.parse(value) <= 0) return 'Must be > 0';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Category
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategoryId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            prefixIcon:
                                Icon(Icons.category, color: Colors.amber[700]),
                          ),
                          items: expenseProvider.categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat.id,
                              child: Row(
                                children: [
                                  if (cat.icon != null)
                                    Icon(
                                      IconHelper.getIconData(cat.icon),
                                      size: 20,
                                      color: cat.color != null
                                          ? IconHelper.hexToColor(cat.color!)
                                          : null,
                                    ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                      child: Text(cat.name,
                                          overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedCategoryId = v;
                              // If user explicitly picked a different category
                              // than what was auto-applied, mark it
                              if (v != _autoAppliedCategoryId) {
                                _userPickedCategory = true;
                                _personalizationApplied = false;
                              }
                            });
                          },
                          validator: (v) =>
                              v == null ? 'Please select a category' : null,
                        ),
                        // Personalization indicator
                        if (_personalizationApplied &&
                            _selectedCategoryId == _autoAppliedCategoryId)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 12),
                            child: Row(
                              children: [
                                Icon(Icons.psychology,
                                    size: 12, color: Colors.teal[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Personalized suggestion',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.teal[600]),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Date
                        InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date',
                              prefixIcon: Icon(Icons.calendar_today,
                                  color: Colors.blue[400]),
                            ),
                            child: Text(DateFormat('MMM dd, yyyy')
                                .format(_selectedDate)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Account (Required)
                        DropdownButtonFormField<String>(
                          initialValue: _selectedAccountId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Account',
                            prefixIcon: Icon(Icons.account_balance_wallet,
                                color: Colors.green[400]),
                          ),
                          items: accountProvider.accounts.map((acc) {
                            return DropdownMenuItem(
                              value: acc.id,
                              child: Text(
                                  '${acc.name} (${Currencies.getSymbol(acc.currency)}${acc.currentBalance.toStringAsFixed(2)})'),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              _onAccountChanged(v, accountProvider.accounts),
                          validator: (v) =>
                              v == null ? 'Please select an account' : null,
                        ),
                        const SizedBox(height: 16),

                        // Payment Method (Auto-selected but editable)
                        DropdownButtonFormField<String>(
                          initialValue: _selectedPaymentMethod,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Payment Method',
                            prefixIcon: Icon(
                              _selectedPaymentMethod != null
                                  ? _getPaymentMethodIcon(
                                      _selectedPaymentMethod!)
                                  : Icons.payment,
                              color: Colors.orange,
                            ),
                            helperText: 'Auto-selected, can be changed',
                            helperMaxLines: 1,
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Cash', child: Text('Cash')),
                            DropdownMenuItem(
                                value: 'Credit Card',
                                child: Text('Credit Card')),
                            DropdownMenuItem(
                                value: 'Debit Card', child: Text('Debit Card')),
                            DropdownMenuItem(
                                value: 'Bank Transfer',
                                child: Text('Bank Transfer')),
                            DropdownMenuItem(
                                value: 'E-Wallet', child: Text('E-Wallet')),
                            DropdownMenuItem(
                                value: 'Online Banking',
                                child: Text('Online Banking')),
                            DropdownMenuItem(
                                value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedPaymentMethod = v),
                          validator: (v) =>
                              v == null ? 'Please select payment method' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Additional Details
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            prefixIcon:
                                Icon(Icons.description, color: Colors.purple),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'Notes (Optional)',
                            prefixIcon:
                                Icon(Icons.sticky_note_2, color: Colors.amber),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        // ── Tags ──────────────────────────────────────────
                        _buildTagsField(),
                        const SizedBox(height: 12),
                        // Recurring toggle
                        SwitchListTile(
                          title: const Text('Recurring Expense'),
                          subtitle:
                              const Text('This expense repeats on a schedule'),
                          value: _isRecurring,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) => setState(() {
                            _isRecurring = v;
                            if (!v) _recurringFrequency = null;
                          }),
                        ),
                        // Recurring frequency — only shown when recurring is on
                        if (_isRecurring)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: DropdownButtonFormField<String>(
                              initialValue: _recurringFrequency,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Frequency',
                                prefixIcon:
                                    Icon(Icons.repeat, color: Colors.blue[400]),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'daily', child: Text('Daily')),
                                DropdownMenuItem(
                                    value: 'weekly', child: Text('Weekly')),
                                DropdownMenuItem(
                                    value: 'bi-weekly',
                                    child: Text('Bi-weekly')),
                                DropdownMenuItem(
                                    value: 'monthly', child: Text('Monthly')),
                                DropdownMenuItem(
                                    value: 'yearly', child: Text('Yearly')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _recurringFrequency = v),
                              validator: (v) {
                                if (_isRecurring && v == null) {
                                  return 'Select a frequency';
                                }
                                return null;
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                FilledButton(
                  onPressed: _isLoading ? null : _saveExpense,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(isEditing ? 'Update Expense' : 'Add Expense'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Small tile used in the scan-source bottom sheet
class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
