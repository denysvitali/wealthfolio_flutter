import 'package:flutter/material.dart';
import 'package:wealthfolio_flutter/core/models/account.dart';
import 'package:wealthfolio_flutter/core/models/portfolio_allocation.dart';
import 'package:wealthfolio_flutter/core/services/app_controller.dart';
import 'package:wealthfolio_flutter/core/utils/currency_format.dart';
import 'package:wealthfolio_flutter/ui/app_colors.dart';
import 'package:wealthfolio_flutter/ui/design_tokens.dart';
import 'package:wealthfolio_flutter/ui/shared_widgets.dart';

// ---------------------------------------------------------------------------
// Color palette for allocation bars
// ---------------------------------------------------------------------------

const _barColors = [
  AppColors.blue,
  AppColors.green,
  AppColors.purple,
  AppColors.orange,
  AppColors.cyan,
  AppColors.magenta,
  AppColors.yellow,
  AppColors.red,
];

Color _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return _barColors[0];
  final clean = hex.replaceFirst('#', '');
  if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
  if (clean.length == 8) return Color(int.parse(clean, radix: 16));
  return _barColors[0];
}

// ---------------------------------------------------------------------------
// InsightsScreen
// ---------------------------------------------------------------------------

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  List<PortfolioAllocation> _allocations = const <PortfolioAllocation>[];
  bool _loading = true;
  String? _error;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.controller
          .fetchAllocations(accountId: _selectedAccountId);
      if (!mounted) return;
      setState(() {
        _allocations = result;
        _loading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    try {
      final result = await widget.controller
          .fetchAllocations(accountId: _selectedAccountId);
      if (!mounted) return;
      setState(() {
        _allocations = result;
        _error = null;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  void _onAccountChanged(String? accountId) {
    setState(() {
      _selectedAccountId = accountId;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    // Loading skeleton
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Insights')),
        body: const _InsightsSkeleton(),
      );
    }

    // Error state
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Insights')),
        body: ErrorRetryWidget(
          message: _error!,
          onRetry: _loadData,
        ),
      );
    }

    // Empty state
    if (_allocations.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Insights')),
        body: Padding(
          padding: kPagePadding,
          child: EmptyStateCard(
            icon: Icons.pie_chart_outline,
            title: 'No allocation data',
            subtitle:
                'Add holdings or import activities to see portfolio insights.',
          ),
        ),
      );
    }

    // Content
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Account filter dropdown
            SliverToBoxAdapter(
              child: _AccountFilter(
                accounts: widget.controller.accounts,
                selectedAccountId: _selectedAccountId,
                onChanged: _onAccountChanged,
              ),
            ),

            // Donut chart placeholder
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.md,
                ),
                child: _ChartPlaceholder(
                  allocations: _allocations,
                  currency: widget.controller.baseCurrency,
                ),
              ),
            ),

            // Section header
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: Text(
                  'Allocation Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Allocation items
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.huge,
              ),
              sliver: SliverList.separated(
                itemCount: _allocations.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final allocation = _allocations[index];
                  final itemColor = allocation.color != null &&
                          allocation.color!.isNotEmpty
                      ? _parseColor(allocation.color)
                      : _barColors[index % _barColors.length];

                  return _AllocationCard(
                    allocation: allocation,
                    itemColor: itemColor,
                    currency: widget.controller.baseCurrency,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account filter dropdown
// ---------------------------------------------------------------------------

class _AccountFilter extends StatelessWidget {
  const _AccountFilter({
    required this.accounts,
    required this.selectedAccountId,
    required this.onChanged,
  });

  final List<Account> accounts;
  final String? selectedAccountId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        0,
      ),
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.inputFill(theme),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.sm,
            borderSide: BorderSide.none,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: selectedAccountId,
            isDense: true,
            isExpanded: true,
            icon: Icon(
              Icons.unfold_more,
              size: AppIconSize.sm,
              color: AppColors.mutedText(theme),
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Accounts'),
              ),
              for (final account in accounts)
                DropdownMenuItem<String?>(
                  value: account.id,
                  child: Text(account.name),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chart placeholder (donut)
// ---------------------------------------------------------------------------

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({
    required this.allocations,
    required this.currency,
  });

  final List<PortfolioAllocation> allocations;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    double totalValue = 0;
    for (final a in allocations) {
      totalValue += a.value;
    }

    return SectionCard(
      child: Column(
        children: [
          Text(
            'Portfolio Allocation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppColors.outline(theme), width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatCurrency(totalValue, currency: currency),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Chart',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedText(theme),
                    ),
                  ),
                  Text(
                    'coming soon',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.tertiaryText(theme),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Allocation card
// ---------------------------------------------------------------------------

class _AllocationCard extends StatelessWidget {
  const _AllocationCard({
    required this.allocation,
    required this.itemColor,
    required this.currency,
  });

  final PortfolioAllocation allocation;
  final Color itemColor;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: itemColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  allocation.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                formatCurrency(allocation.value, currency: currency),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.xs,
            child: LinearProgressIndicator(
              value: allocation.percentage / 100,
              backgroundColor: itemColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(itemColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatPercent(allocation.percentage / 100),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mutedText(theme),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------

class _InsightsSkeleton extends StatelessWidget {
  const _InsightsSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shimmer = AppColors.skeleton(theme);

    return Padding(
      padding: kPagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account filter skeleton
          _SkeletonBox(
            width: double.infinity,
            height: 44,
            color: shimmer,
            radius: AppRadius.sm,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Chart placeholder skeleton
          _SkeletonBox(
            width: double.infinity,
            height: 260,
            color: shimmer,
            radius: AppRadius.base,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Section header skeleton
          _SkeletonBox(width: 160, height: 18, color: shimmer),
          const SizedBox(height: AppSpacing.lg),

          // Allocation card skeletons
          for (var i = 0; i < 3; i++) ...[
            _SkeletonBox(
              width: double.infinity,
              height: 90,
              color: shimmer,
              radius: AppRadius.base,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton box
// ---------------------------------------------------------------------------

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
