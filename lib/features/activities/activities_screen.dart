import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wealthfolio_flutter/core/models/account.dart';
import 'package:wealthfolio_flutter/core/models/activity.dart';
import 'package:wealthfolio_flutter/core/services/app_controller.dart';
import 'package:wealthfolio_flutter/core/utils/currency_format.dart';
import 'package:wealthfolio_flutter/features/activities/activity_form_screen.dart';
import 'package:wealthfolio_flutter/ui/app_colors.dart';
import 'package:wealthfolio_flutter/ui/design_tokens.dart';
import 'package:wealthfolio_flutter/ui/shared_widgets.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const int _kPageSize = 40;

// ---------------------------------------------------------------------------
// Filter model
// ---------------------------------------------------------------------------

class _FilterOption {
  const _FilterOption({required this.label, this.value});
  final String label;
  final String? value; // null = all
}

const List<_FilterOption> _kFilters = [
  _FilterOption(label: 'All', value: null),
  _FilterOption(label: 'Buy', value: 'BUY'),
  _FilterOption(label: 'Sell', value: 'SELL'),
  _FilterOption(label: 'Dividend', value: 'DIVIDEND'),
  _FilterOption(label: 'Interest', value: 'INTEREST'),
  _FilterOption(label: 'Deposit', value: 'DEPOSIT'),
  _FilterOption(label: 'Withdrawal', value: 'WITHDRAWAL'),
  _FilterOption(label: 'Transfer In', value: 'TRANSFER_IN'),
  _FilterOption(label: 'Transfer Out', value: 'TRANSFER_OUT'),
  _FilterOption(label: 'Fee', value: 'FEE'),
  _FilterOption(label: 'Tax', value: 'TAX'),
];

// ---------------------------------------------------------------------------
// ActivitiesScreen
// ---------------------------------------------------------------------------

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  // State
  final List<Activity> _activities = [];
  int _total = 0;
  int _page = 1;
  bool _loadingInitial = false;
  bool _loadingMore = false;
  String? _errorMessage;

  // Filters
  String? _selectedType; // null = all
  String _searchQuery = '';

  // Debounce for search
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool get _hasMore => _activities.length < _total;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Data loading
  // -------------------------------------------------------------------------

  Future<void> _loadInitial() async {
    if (_loadingInitial) return;
    setState(() {
      _loadingInitial = true;
      _errorMessage = null;
      _activities.clear();
      _total = 0;
      _page = 1;
    });

    try {
      final response = await widget.controller.searchActivities(
        page: 1,
        pageSize: _kPageSize,
        activityType: _selectedType,
        assetKeyword: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (mounted) {
        setState(() {
          _activities.addAll(response.activities);
          _total = response.total;
          _page = 1;
          _loadingInitial = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loadingInitial = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final nextPage = _page + 1;
    setState(() => _loadingMore = true);

    try {
      final response = await widget.controller.searchActivities(
        page: nextPage,
        pageSize: _kPageSize,
        activityType: _selectedType,
        assetKeyword: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (mounted) {
        setState(() {
          _activities.addAll(response.activities);
          _total = response.total;
          _page = nextPage;
          _loadingMore = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _onFilterChanged(String? type) {
    if (_selectedType == type) return;
    setState(() => _selectedType = type);
    _loadInitial();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (_searchQuery != value.trim()) {
        setState(() => _searchQuery = value.trim());
        _loadInitial();
      }
    });
  }

  Future<void> _onRefresh() async {
    _searchDebounce?.cancel();
    await _loadInitial();
  }

  // -------------------------------------------------------------------------
  // Navigation to form
  // -------------------------------------------------------------------------

  Future<void> _openCreateForm() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ActivityFormScreen(controller: widget.controller),
        fullscreenDialog: true,
      ),
    );
    if (created == true && mounted) {
      _loadInitial();
    }
  }

  Future<void> _openEditForm(Activity activity) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ActivityFormScreen(
          controller: widget.controller,
          activity: activity,
        ),
        fullscreenDialog: true,
      ),
    );
    if (updated == true && mounted) {
      _loadInitial();
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        actions: [
          if (_loadingInitial)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.xl),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateForm,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search bar
          _SearchBar(
            controller: _searchController,
            onChanged: _onSearchChanged,
          ),

          // Filter chips
          _FilterChipRow(
            filters: _kFilters,
            selectedValue: _selectedType,
            onSelected: _onFilterChanged,
          ),

          const Divider(height: 1),

          // Error banner
          if (_errorMessage != null && _activities.isEmpty)
            Expanded(
              child: ErrorRetryWidget(
                message: _errorMessage!,
                onRetry: _loadInitial,
              ),
            )
          else

          // List
          Expanded(
            child: _ActivityList(
              activities: _activities,
              total: _total,
              loadingInitial: _loadingInitial,
              loadingMore: _loadingMore,
              hasMore: _hasMore,
              scrollController: _scrollController,
              accounts: widget.controller.accounts,
              onRefresh: _onRefresh,
              onLoadMore: _loadMore,
              onTap: _openEditForm,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search by symbol or asset...',
          hintStyle: TextStyle(
            color: AppColors.tertiaryText(theme),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: AppIconSize.md,
            color: AppColors.mutedText(theme),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: AppIconSize.sm,
                    color: AppColors.mutedText(theme),
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          isDense: true,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chip row
// ---------------------------------------------------------------------------

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.filters,
    required this.selectedValue,
    required this.onSelected,
  });

  final List<_FilterOption> filters;
  final String? selectedValue;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = selectedValue == filter.value;
          return ChoiceChip(
            label: Text(
              filter.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? theme.colorScheme.onPrimary
                    : AppColors.mutedText(theme),
              ),
            ),
            selected: selected,
            onSelected: (_) => onSelected(filter.value),
            selectedColor: theme.colorScheme.primary,
            backgroundColor: AppColors.inputFill(theme),
            side: BorderSide(
              color: selected
                  ? theme.colorScheme.primary
                  : AppColors.outline(theme),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 0,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity list body
// ---------------------------------------------------------------------------

class _ActivityList extends StatelessWidget {
  const _ActivityList({
    required this.activities,
    required this.total,
    required this.loadingInitial,
    required this.loadingMore,
    required this.hasMore,
    required this.scrollController,
    required this.accounts,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onTap,
  });

  final List<Activity> activities;
  final int total;
  final bool loadingInitial;
  final bool loadingMore;
  final bool hasMore;
  final ScrollController scrollController;
  final List<Account> accounts;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final void Function(Activity) onTap;

  @override
  Widget build(BuildContext context) {
    if (loadingInitial) {
      return const _ActivitiesSkeleton();
    }

    if (activities.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: kPagePadding,
          children: const [
            SizedBox(height: AppSpacing.xxl),
            EmptyStateCard(
              icon: Icons.receipt_long_outlined,
              title: 'No activities found',
              subtitle:
                  'Add your first activity using the + button, or adjust your filters.',
            ),
          ],
        ),
      );
    }

    // Build account map for label lookup
    final accountMap = {for (final a in accounts) a.id: a};

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.lg,
          bottom: 80, // FAB clearance
        ),
        itemCount: activities.length + (loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == activities.length) {
            // Loading more indicator at the bottom
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final activity = activities[index];
          final account = accountMap[activity.accountId];
          final isFirst = index == 0;
          final isLast = index == activities.length - 1;

          // Group by date — show date header when day changes
          final showDateHeader = isFirst ||
              _dateOf(activities[index - 1].activityDate) !=
                  _dateOf(activity.activityDate);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDateHeader) _DateHeader(dateStr: activity.activityDate),
              _ActivityTile(
                activity: activity,
                accountName: account?.name,
                isFirst: isFirst || showDateHeader,
                isLast: isLast ||
                    (index < activities.length - 1 &&
                        _dateOf(activities[index + 1].activityDate) !=
                            _dateOf(activity.activityDate)),
                onTap: () => onTap(activity),
              ),
            ],
          );
        },
      ),
    );
  }

  String _dateOf(String dateStr) {
    // Take only the YYYY-MM-DD portion for grouping
    if (dateStr.length >= 10) return dateStr.substring(0, 10);
    return dateStr;
  }
}

// ---------------------------------------------------------------------------
// Date header
// ---------------------------------------------------------------------------

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.dateStr});

  final String dateStr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xl,
        bottom: AppSpacing.md,
      ),
      child: Text(
        _formatDateHeader(dateStr),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedText(theme),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _formatDateHeader(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length < 3) return dateStr;
      final dt = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } on Exception {
      return dateStr;
    }
  }
}

// ---------------------------------------------------------------------------
// Activity tile
// ---------------------------------------------------------------------------

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.activity,
    required this.accountName,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final Activity activity;
  final String? accountName;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final typeInfo = _activityTypeInfo(activity.activityType);
    final totalValue = activity.quantity * activity.unitPrice;
    final isDebit = _isDebit(activity.activityType);

    final borderRadius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(10) : Radius.zero,
      bottom: isLast ? const Radius.circular(10) : Radius.zero,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: borderRadius,
        border: Border(
          left: BorderSide(color: AppColors.outline(theme)),
          right: BorderSide(color: AppColors.outline(theme)),
          top: isFirst
              ? BorderSide(color: AppColors.outline(theme))
              : BorderSide.none,
          bottom: BorderSide(color: AppColors.outline(theme)),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              // Type icon
              _ActivityIcon(
                icon: typeInfo.icon,
                color: typeInfo.color,
              ),
              const SizedBox(width: AppSpacing.lg),

              // Center: symbol + type + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            activity.assetId,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (activity.isDraft) ...[
                          const SizedBox(width: AppSpacing.md),
                          _DraftBadge(theme: theme),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      typeInfo.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: typeInfo.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (accountName != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        accountName!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.tertiaryText(theme),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),

              // Right: value + qty / fee
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isDebit ? '-' : '+'}${formatCurrency(totalValue, currency: activity.currency)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDebit ? AppColors.loss : AppColors.gain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _quantityLabel(activity),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedText(theme),
                    ),
                  ),
                  if (activity.fee > 0) ...[
                    const SizedBox(height: 1),
                    Text(
                      'Fee: ${formatCurrency(activity.fee, currency: activity.currency)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.tertiaryText(theme),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _quantityLabel(Activity a) {
    if (a.quantity == 0) return '';
    final qty = formatNumber(a.quantity, decimals: a.quantity % 1 == 0 ? 0 : 4);
    if (a.unitPrice > 0) {
      return '$qty @ ${formatCurrency(a.unitPrice, currency: a.currency)}';
    }
    return qty;
  }

  bool _isDebit(String type) {
    return switch (type.toUpperCase()) {
      'BUY' || 'FEE' || 'TAX' || 'WITHDRAWAL' || 'TRANSFER_OUT' ||
      'CONVERSION_OUT' => true,
      _ => false,
    };
  }

  _ActivityTypeInfo _activityTypeInfo(String type) {
    return switch (type.toUpperCase()) {
      'BUY' => const _ActivityTypeInfo(
        label: 'Buy',
        icon: Icons.arrow_upward_rounded,
        color: AppColors.gain,
      ),
      'SELL' => const _ActivityTypeInfo(
        label: 'Sell',
        icon: Icons.arrow_downward_rounded,
        color: AppColors.loss,
      ),
      'DIVIDEND' => const _ActivityTypeInfo(
        label: 'Dividend',
        icon: Icons.payments_outlined,
        color: AppColors.blue,
      ),
      'INTEREST' => const _ActivityTypeInfo(
        label: 'Interest',
        icon: Icons.percent_rounded,
        color: AppColors.cyan,
      ),
      'DEPOSIT' => const _ActivityTypeInfo(
        label: 'Deposit',
        icon: Icons.add_circle_outline,
        color: AppColors.green,
      ),
      'WITHDRAWAL' => const _ActivityTypeInfo(
        label: 'Withdrawal',
        icon: Icons.remove_circle_outline,
        color: AppColors.orange,
      ),
      'TRANSFER_IN' => const _ActivityTypeInfo(
        label: 'Transfer In',
        icon: Icons.login_rounded,
        color: AppColors.cyan,
      ),
      'TRANSFER_OUT' => const _ActivityTypeInfo(
        label: 'Transfer Out',
        icon: Icons.logout_rounded,
        color: AppColors.orange,
      ),
      'CONVERSION_IN' => const _ActivityTypeInfo(
        label: 'Conversion In',
        icon: Icons.currency_exchange,
        color: AppColors.purple,
      ),
      'CONVERSION_OUT' => const _ActivityTypeInfo(
        label: 'Conversion Out',
        icon: Icons.currency_exchange,
        color: AppColors.magenta,
      ),
      'FEE' => const _ActivityTypeInfo(
        label: 'Fee',
        icon: Icons.receipt_outlined,
        color: AppColors.red,
      ),
      'TAX' => const _ActivityTypeInfo(
        label: 'Tax',
        icon: Icons.gavel_outlined,
        color: AppColors.yellow,
      ),
      'SPLIT' => const _ActivityTypeInfo(
        label: 'Split',
        icon: Icons.call_split_rounded,
        color: AppColors.purple,
      ),
      _ => const _ActivityTypeInfo(
        label: 'Activity',
        icon: Icons.swap_horiz_rounded,
        color: AppColors.tx2,
      ),
    };
  }
}

class _ActivityTypeInfo {
  const _ActivityTypeInfo({
    required this.label,
    required this.icon,
    required this.color,
  });
  final String label;
  final IconData icon;
  final Color color;
}

// ---------------------------------------------------------------------------
// Activity icon widget
// ---------------------------------------------------------------------------

class _ActivityIcon extends StatelessWidget {
  const _ActivityIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.sm,
      ),
      child: Icon(icon, size: AppIconSize.md, color: color),
    );
  }
}

// ---------------------------------------------------------------------------
// Draft badge
// ---------------------------------------------------------------------------

class _DraftBadge extends StatelessWidget {
  const _DraftBadge({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.yellow.withValues(alpha: 0.15),
        borderRadius: AppRadius.pill,
        border: Border.all(
          color: AppColors.yellow.withValues(alpha: 0.4),
        ),
      ),
      child: const Text(
        'Draft',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppColors.yellow,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loading state
// ---------------------------------------------------------------------------

class _ActivitiesSkeleton extends StatelessWidget {
  const _ActivitiesSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shimmer = AppColors.skeleton(theme);
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Row(
            children: [
              _SkeletonBox(width: 40, height: 40, color: shimmer, radius: AppRadius.sm),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 100, height: 14, color: shimmer),
                    const SizedBox(height: AppSpacing.sm),
                    _SkeletonBox(width: 60, height: 12, color: shimmer),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _SkeletonBox(width: 80, height: 14, color: shimmer),
                  const SizedBox(height: AppSpacing.sm),
                  _SkeletonBox(width: 50, height: 11, color: shimmer),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.color,
    this.radius,
  });

  final double width;
  final double height;
  final Color color;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius ?? AppRadius.xs,
      ),
    );
  }
}
