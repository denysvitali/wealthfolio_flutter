import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wealthfolio_flutter/core/models/account.dart';
import 'package:wealthfolio_flutter/core/models/activity.dart';
import 'package:wealthfolio_flutter/core/services/app_controller.dart';
import 'package:wealthfolio_flutter/ui/app_colors.dart';
import 'package:wealthfolio_flutter/ui/design_tokens.dart';
import 'package:wealthfolio_flutter/ui/shared_widgets.dart';

class _SymbolSuggestion {
  const _SymbolSuggestion({
    required this.symbol,
    required this.name,
    this.assetId,
    this.assetType,
  });

  final String symbol;
  final String name;
  final String? assetId;
  final String? assetType;

  factory _SymbolSuggestion.fromMap(Map<String, dynamic> map) {
    return _SymbolSuggestion(
      symbol: (map['symbol'] ?? map['ticker'] ?? '').toString().toUpperCase(),
      name: (map['name'] ?? map['description'] ?? '').toString(),
      assetId: (map['asset_id'] ?? map['assetId'] ?? map['id'])?.toString(),
      assetType: (map['asset_type'] ?? map['assetType'] ?? map['type'])?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity types definition
// ---------------------------------------------------------------------------

class _TypeOption {
  const _TypeOption({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;
}

const List<_TypeOption> _kTypeOptions = [
  _TypeOption(value: 'BUY', label: 'Buy', icon: Icons.arrow_upward_rounded),
  _TypeOption(
    value: 'SELL',
    label: 'Sell',
    icon: Icons.arrow_downward_rounded,
  ),
  _TypeOption(
    value: 'DIVIDEND',
    label: 'Dividend',
    icon: Icons.payments_outlined,
  ),
  _TypeOption(
    value: 'INTEREST',
    label: 'Interest',
    icon: Icons.percent_rounded,
  ),
  _TypeOption(
    value: 'DEPOSIT',
    label: 'Deposit',
    icon: Icons.add_circle_outline,
  ),
  _TypeOption(
    value: 'WITHDRAWAL',
    label: 'Withdrawal',
    icon: Icons.remove_circle_outline,
  ),
  _TypeOption(
    value: 'TRANSFER_IN',
    label: 'Transfer In',
    icon: Icons.login_rounded,
  ),
  _TypeOption(
    value: 'TRANSFER_OUT',
    label: 'Transfer Out',
    icon: Icons.logout_rounded,
  ),
  _TypeOption(
    value: 'FEE',
    label: 'Fee',
    icon: Icons.receipt_outlined,
  ),
  _TypeOption(
    value: 'TAX',
    label: 'Tax',
    icon: Icons.gavel_outlined,
  ),
];

// ---------------------------------------------------------------------------
// ActivityFormScreen
// ---------------------------------------------------------------------------

/// Full create / edit form for an [Activity].
/// Pops with `true` when the activity is saved or deleted, `false` on cancel.
class ActivityFormScreen extends StatefulWidget {
  const ActivityFormScreen({
    super.key,
    required this.controller,
    this.activity,
  });

  final AppController controller;

  /// When non-null, the form is in edit mode for this activity.
  final Activity? activity;

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Form field controllers ────────────────────────────────────────────────
  late String _activityType;
  late TextEditingController _assetIdController;
  late DateTime _activityDate;
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;
  late TextEditingController _currencyController;
  late TextEditingController _feeController;
  late TextEditingController _commentController;
  late bool _isDraft;
  String? _selectedAccountId;
  Timer? _symbolSearchDebounce;
  List<_SymbolSuggestion> _symbolSuggestions = const <_SymbolSuggestion>[];
  bool _searchingSymbols = false;

  // ── Async state ───────────────────────────────────────────────────────────
  bool _submitting = false;
  bool _deleting = false;
  String? _errorMessage;

  bool get _isEditing => widget.activity != null;
  bool get _isBusy => _submitting || _deleting;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    _activityType = a?.activityType ?? 'BUY';
    _assetIdController = TextEditingController(text: a?.assetId ?? '');
    _activityDate = a != null ? _parseDateStr(a.activityDate) : DateTime.now();
    _quantityController = TextEditingController(
      text: a != null ? _cleanNumber(a.quantity) : '',
    );
    _unitPriceController = TextEditingController(
      text: a != null ? _cleanNumber(a.unitPrice) : '',
    );
    _currencyController = TextEditingController(
      text: a?.currency ?? widget.controller.baseCurrency,
    );
    _feeController = TextEditingController(
      text: (a != null && a.fee > 0) ? _cleanNumber(a.fee) : '',
    );
    _commentController = TextEditingController(text: a?.comment ?? '');
    _isDraft = a?.isDraft ?? false;
    _selectedAccountId = a?.accountId;

    // Auto-select first active account when creating
    if (_selectedAccountId == null) {
      final active = widget.controller.accounts.where((ac) => ac.isActive);
      if (active.isNotEmpty) {
        final first = active.first;
        _selectedAccountId = first.id;
        if (a == null) {
          _currencyController.text = first.currency;
        }
      }
    }
  }

  @override
  void dispose() {
    _symbolSearchDebounce?.cancel();
    _assetIdController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _currencyController.dispose();
    _feeController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  DateTime _parseDateStr(String s) {
    try {
      return DateTime.parse(s.length > 10 ? s.substring(0, 10) : s);
    } on FormatException {
      return DateTime.now();
    }
  }

  String _dateToApiStr(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  String _formatDateDisplay(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  /// Remove trailing zeros: 1.0 → "1", 1.50 → "1.5", 1.0500 → "1.05"
  String _cleanNumber(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v
        .toStringAsFixed(8)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  double _parseField(String text, {double fallback = 0}) =>
      double.tryParse(text.trim()) ?? fallback;

  bool get _activityNeedsAsset {
    switch (_activityType) {
      case 'DEPOSIT':
      case 'WITHDRAWAL':
      case 'TRANSFER_IN':
      case 'TRANSFER_OUT':
      case 'FEE':
      case 'TAX':
        return false;
      default:
        return true;
    }
  }

  void _onAssetQueryChanged(String value) {
    _symbolSearchDebounce?.cancel();
    final query = value.trim();
    if (!_activityNeedsAsset || query.length < 2) {
      setState(() {
        _symbolSuggestions = const <_SymbolSuggestion>[];
        _searchingSymbols = false;
      });
      return;
    }
    setState(() => _searchingSymbols = true);
    _symbolSearchDebounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final results = await widget.controller.searchSymbols(query);
        if (!mounted || _assetIdController.text.trim() != query) return;
        final suggestions = results
            .map(_SymbolSuggestion.fromMap)
            .where((item) => item.symbol.isNotEmpty)
            .take(8)
            .toList(growable: false);
        setState(() {
          _symbolSuggestions = suggestions;
          _searchingSymbols = false;
        });
      } on Exception {
        if (!mounted) return;
        setState(() {
          _symbolSuggestions = const <_SymbolSuggestion>[];
          _searchingSymbols = false;
        });
      }
    });
  }

  // -------------------------------------------------------------------------
  // Date picker
  // -------------------------------------------------------------------------

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _activityDate,
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _activityDate = picked);
    }
  }

  // -------------------------------------------------------------------------
  // Account selector
  // -------------------------------------------------------------------------

  void _onAccountChanged(String? id) {
    if (id == null) return;
    setState(() {
      _selectedAccountId = id;
      // Sync currency to account currency
      final account = widget.controller.accounts.firstWhere(
        (a) => a.id == id,
        orElse: () => widget.controller.accounts.first,
      );
      _currencyController.text = account.currency;
    });
  }

  // -------------------------------------------------------------------------
  // Submit
  // -------------------------------------------------------------------------

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      setState(() => _errorMessage = 'Please select an account.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final symbolText = _assetIdController.text.trim().toUpperCase();
      final currency = _currencyController.text.trim().toUpperCase();
      final data = <String, dynamic>{
        if (_isEditing) 'id': widget.activity!.id,
        'account_id': _selectedAccountId,
        if (_activityNeedsAsset)
          'symbol': <String, dynamic>{
            'symbol': symbolText,
            'quoteCcy': currency,
          },
        'activity_type': _activityType,
        'activity_date': _dateToApiStr(_activityDate),
        'quantity': _parseField(_quantityController.text),
        'unit_price': _parseField(_unitPriceController.text),
        'currency': currency,
        'fee': _parseField(_feeController.text),
        'is_draft': _isDraft,
        'comment': _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      };

      if (_isEditing) {
        await widget.controller.updateActivity(data);
      } else {
        await widget.controller.createActivity(data);
      }

      if (mounted) Navigator.pop(context, true);
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _submitting = false;
        });
      }
    }
  }

  // -------------------------------------------------------------------------
  // Delete
  // -------------------------------------------------------------------------

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text(
          'Are you sure you want to delete this activity? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _delete();
    }
  }

  Future<void> _delete() async {
    setState(() {
      _deleting = true;
      _errorMessage = null;
    });

    try {
      await widget.controller.deleteActivity(widget.activity!.id);
      if (mounted) Navigator.pop(context, true);
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _deleting = false;
        });
      }
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final activeAccounts = widget.controller.accounts
        .where((a) => a.isActive)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Activity' : 'New Activity'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isBusy ? null : () => Navigator.pop(context, false),
          tooltip: 'Close',
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: _deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.error,
                      ),
                    )
                  : const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _isBusy ? null : _confirmDelete,
              tooltip: 'Delete activity',
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            100,
          ),
          children: [
            // Error banner
            if (_errorMessage != null) ...[
              _ErrorBanner(message: _errorMessage!),
              const SizedBox(height: AppSpacing.xl),
            ],

            // ── Activity type ──────────────────────────────────────────
            _FormSection(
              label: 'Activity Type',
              child: _ActivityTypeSelector(
                selected: _activityType,
                onChanged: (v) => setState(() {
                  _activityType = v;
                  if (!_activityNeedsAsset) {
                    _symbolSuggestions = const <_SymbolSuggestion>[];
                  }
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Account ────────────────────────────────────────────────
            _FormSection(
              label: 'Account',
              child: activeAccounts.isEmpty
                  ? const _NoAccountsNotice()
                  : _AccountDropdown(
                      accounts: activeAccounts,
                      selectedId: _selectedAccountId,
                      onChanged: _onAccountChanged,
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Asset symbol ───────────────────────────────────────────
            if (_activityNeedsAsset) ...[
              _FormSection(
                label: 'Asset Symbol',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _assetIdController,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: _onAssetQueryChanged,
                      decoration: InputDecoration(
                        hintText: 'e.g. AAPL, BTC, EUR',
                        prefixIcon: const Icon(Icons.search, size: AppIconSize.md),
                        suffixIcon: _searchingSymbols
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Asset symbol is required.';
                        }
                        return null;
                      },
                    ),
                    if (_symbolSuggestions.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _SymbolSuggestionList(
                        suggestions: _symbolSuggestions,
                        onSelected: (suggestion) {
                          setState(() {
                            _assetIdController.text = suggestion.symbol;
                            _symbolSuggestions = const <_SymbolSuggestion>[];
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // ── Date ───────────────────────────────────────────────────
            _FormSection(
              label: 'Date',
              child: _DatePickerField(
                displayText: _formatDateDisplay(_activityDate),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Quantity + Unit Price ──────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FormSection(
                    label: 'Quantity',
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]'),
                        ),
                      ],
                      decoration: const InputDecoration(hintText: '0'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final n = double.tryParse(v);
                        if (n == null || n < 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _FormSection(
                    label: 'Unit Price',
                    child: TextFormField(
                      controller: _unitPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]'),
                        ),
                      ],
                      decoration: const InputDecoration(hintText: '0.00'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final n = double.tryParse(v);
                        if (n == null || n < 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Currency + Fee ─────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _FormSection(
                    label: 'Currency',
                    child: TextFormField(
                      controller: _currencyController,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                        LengthLimitingTextInputFormatter(3),
                      ],
                      decoration: const InputDecoration(hintText: 'USD'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length != 3) return '3-letter code';
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  flex: 3,
                  child: _FormSection(
                    label: 'Fee (optional)',
                    child: TextFormField(
                      controller: _feeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]'),
                        ),
                      ],
                      decoration: const InputDecoration(hintText: '0.00'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v);
                        if (n == null || n < 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Comment ────────────────────────────────────────────────
            _FormSection(
              label: 'Comment (optional)',
              child: TextFormField(
                controller: _commentController,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Add a note...',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Draft toggle ───────────────────────────────────────────
            _DraftToggle(
              value: _isDraft,
              onChanged: (v) => setState(() => _isDraft = v),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // ── Submit button ──────────────────────────────────────────
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _isBusy ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Add Activity'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SymbolSuggestionList extends StatelessWidget {
  const _SymbolSuggestionList({
    required this.suggestions,
    required this.onSelected,
  });

  final List<_SymbolSuggestion> suggestions;
  final ValueChanged<_SymbolSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.base,
        border: Border.all(color: AppColors.outline(theme)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < suggestions.length; i++) ...[
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.blue.withValues(alpha: 0.10),
                child: Text(
                  suggestions[i].symbol.length > 2
                      ? suggestions[i].symbol.substring(0, 2)
                      : suggestions[i].symbol,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                ),
              ),
              title: Text(
                suggestions[i].symbol,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                [
                  if (suggestions[i].name.isNotEmpty) suggestions[i].name,
                  if ((suggestions[i].assetType ?? '').isNotEmpty)
                    suggestions[i].assetType!,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => onSelected(suggestions[i]),
            ),
            if (i != suggestions.length - 1)
              Divider(height: 1, color: AppColors.outline(theme)),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity type chip selector
// ---------------------------------------------------------------------------

class _ActivityTypeSelector extends StatelessWidget {
  const _ActivityTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  Color _colorFor(String type, ThemeData theme) {
    return switch (type) {
      'BUY' => AppColors.gain,
      'SELL' => AppColors.loss,
      'DIVIDEND' || 'INTEREST' => AppColors.blue,
      'DEPOSIT' || 'TRANSFER_IN' => AppColors.cyan,
      'WITHDRAWAL' || 'TRANSFER_OUT' => AppColors.orange,
      'FEE' || 'TAX' => AppColors.red,
      _ => AppColors.mutedText(theme),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: _kTypeOptions.map((opt) {
        final isSelected = selected == opt.value;
        final color = _colorFor(opt.value, theme);
        return ChoiceChip(
          avatar: Icon(
            opt.icon,
            size: AppIconSize.sm,
            color: isSelected ? color : AppColors.mutedText(theme),
          ),
          label: Text(
            opt.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? color : AppColors.mutedText(theme),
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onChanged(opt.value),
          selectedColor: color.withValues(alpha: 0.12),
          backgroundColor: AppColors.inputFill(theme),
          side: BorderSide(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : AppColors.outline(theme),
          ),
          showCheckmark: false,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Account dropdown
// ---------------------------------------------------------------------------

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.accounts,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Guard: ensure selectedId is actually in the list
    final validId = accounts.any((a) => a.id == selectedId) ? selectedId : null;

    return DropdownButtonFormField<String>(
      initialValue: validId,
      isExpanded: true,
      decoration: const InputDecoration(),
      hint: Text(
        'Select account',
        style: TextStyle(color: AppColors.mutedText(theme), fontSize: 14),
      ),
      items: accounts.map((account) {
        return DropdownMenuItem<String>(
          value: account.id,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  account.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                account.currency,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedText(theme),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (v) =>
          v == null ? 'Please select an account.' : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Date picker field
// ---------------------------------------------------------------------------

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.displayText, required this.onTap});

  final String displayText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.base,
      child: InputDecorator(
        decoration: const InputDecoration(),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: AppIconSize.sm,
              color: AppColors.mutedText(theme),
            ),
            const SizedBox(width: AppSpacing.lg),
            Text(
              displayText,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Draft toggle
// ---------------------------------------------------------------------------

class _DraftToggle extends StatelessWidget {
  const _DraftToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Save as Draft',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Draft activities are excluded from portfolio calculations.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText(theme),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.yellow,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form section label wrapper
// ---------------------------------------------------------------------------

class _FormSection extends StatelessWidget {
  const _FormSection({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.mutedText(theme),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// No accounts notice
// ---------------------------------------------------------------------------

class _NoAccountsNotice extends StatelessWidget {
  const _NoAccountsNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: AppRadius.base,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_outlined,
            size: AppIconSize.md,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              'No active accounts found. Create an account first.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.mutedText(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error banner
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: AppRadius.base,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: AppIconSize.md,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
