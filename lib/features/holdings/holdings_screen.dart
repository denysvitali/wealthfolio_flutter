import 'package:flutter/material.dart';
import 'package:wealthfolio_flutter/core/models/holding.dart';
import 'package:wealthfolio_flutter/core/services/app_controller.dart';
import 'package:wealthfolio_flutter/core/utils/currency_format.dart';
import 'package:wealthfolio_flutter/features/holdings/holding_detail_screen.dart';
import 'package:wealthfolio_flutter/ui/app_colors.dart';
import 'package:wealthfolio_flutter/ui/design_tokens.dart';
import 'package:wealthfolio_flutter/ui/shared_widgets.dart';

// ---------------------------------------------------------------------------
// Sort options
// ---------------------------------------------------------------------------

enum _SortBy { value, gain, dayChange, name }

extension _SortByLabel on _SortBy {
  String get label => switch (this) {
        _SortBy.value => 'By Value',
        _SortBy.gain => 'By Gain',
        _SortBy.dayChange => 'By Day Change',
        _SortBy.name => 'By Name',
      };
}

// ---------------------------------------------------------------------------
// HoldingsScreen
// ---------------------------------------------------------------------------

class HoldingsScreen extends StatefulWidget {
  const HoldingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<HoldingsScreen> createState() => _HoldingsScreenState();
}

class _HoldingsScreenState extends State<HoldingsScreen> {
  bool _searchOpen = false;
  String _query = '';
  _SortBy _sortBy = _SortBy.value;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _query = '';
        _searchController.clear();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocus.requestFocus();
        });
      }
    });
  }

  List<Holding> _applyFiltersAndSort(List<Holding> source) {
    var filtered = source;

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      filtered = filtered
          .where((h) =>
              h.symbol.toLowerCase().contains(q) ||
              h.name.toLowerCase().contains(q))
          .toList();
    }

    filtered = List<Holding>.from(filtered);
    switch (_sortBy) {
      case _SortBy.value:
        filtered.sort(
            (a, b) => b.marketValueConverted.compareTo(a.marketValueConverted));
      case _SortBy.gain:
        filtered.sort((a, b) => b.unrealizedGain.compareTo(a.unrealizedGain));
      case _SortBy.dayChange:
        filtered.sort((a, b) => b.dayChange.compareTo(a.dayChange));
      case _SortBy.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final isLoading = widget.controller.loadingHoldings;
        final hasError = widget.controller.errorMessage != null &&
            widget.controller.holdings.isEmpty;

        // First-load skeleton
        if (isLoading && widget.controller.holdings.isEmpty) {
          return _HoldingsSkeleton(
            onSearchTap: _toggleSearch,
            searchOpen: _searchOpen,
          );
        }

        if (hasError) {
          return Scaffold(
            appBar: _buildAppBar(context),
            body: ErrorRetryWidget(
              message: widget.controller.errorMessage!,
              onRetry: () =>
                  widget.controller.refreshHoldings(showSpinner: false),
            ),
          );
        }

        final displayed =
            _applyFiltersAndSort(widget.controller.holdings);

        return Scaffold(
          appBar: _buildAppBar(context),
          body: Column(
            children: [
              if (_searchOpen) _SearchBar(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: (v) => setState(() => _query = v),
                onClose: _toggleSearch,
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      widget.controller.refreshHoldings(showSpinner: false),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Summary card
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl,
                            AppSpacing.xl,
                            AppSpacing.xl,
                            AppSpacing.md,
                          ),
                          child: _SummaryCard(
                            holdings: widget.controller.holdings,
                            currency: widget.controller.baseCurrency,
                          ),
                        ),
                      ),

                      // Sort + count row
                      SliverToBoxAdapter(
                        child: _SortRow(
                          sortBy: _sortBy,
                          count: displayed.length,
                          onSortChanged: (v) => setState(() => _sortBy = v),
                        ),
                      ),

                      // Empty / list
                      if (displayed.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: kPagePadding,
                            child: _query.isNotEmpty
                                ? EmptyStateCard(
                                    icon: Icons.search_off_outlined,
                                    title: 'No results for "$_query"',
                                    subtitle:
                                        'Try a different symbol or name.',
                                  )
                                : const EmptyStateCard(
                                    icon: Icons.pie_chart_outline,
                                    title: 'No holdings yet',
                                    subtitle:
                                        'Import activities or add holdings to get started.',
                                  ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl,
                            0,
                            AppSpacing.xl,
                            AppSpacing.huge,
                          ),
                          sliver: SliverList.separated(
                            itemCount: displayed.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) => _HoldingCard(
                              holding: displayed[index],
                              currency: widget.controller.baseCurrency,
                              controller: widget.controller,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Holdings'),
      actions: [
        IconButton(
          tooltip: _searchOpen ? 'Close search' : 'Search holdings',
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _searchOpen ? Icons.close : Icons.search,
              key: ValueKey(_searchOpen),
            ),
          ),
          onPressed: _toggleSearch,
        ),
        const SizedBox(width: AppSpacing.md),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Search by symbol or name…',
          hintStyle:
              TextStyle(color: AppColors.mutedText(theme), fontSize: 15),
          prefixIcon: Icon(Icons.search,
              size: AppIconSize.md, color: AppColors.mutedText(theme)),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: AppIconSize.md),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sort row
// ---------------------------------------------------------------------------

class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.sortBy,
    required this.count,
    required this.onSortChanged,
  });

  final _SortBy sortBy;
  final int count;
  final ValueChanged<_SortBy> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Text(
            '$count holding${count == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.mutedText(theme),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          PopupMenuButton<_SortBy>(
            initialValue: sortBy,
            onSelected: onSortChanged,
            itemBuilder: (_) => _SortBy.values
                .map(
                  (s) => PopupMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        if (s == sortBy) ...[
                          const Icon(Icons.check, size: 16),
                          const SizedBox(width: AppSpacing.md),
                        ] else
                          const SizedBox(width: 24),
                        Text(s.label),
                      ],
                    ),
                  ),
                )
                .toList(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sortBy.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.unfold_more,
                  size: AppIconSize.sm,
                  color: AppColors.mutedText(theme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary card at the top
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.holdings,
    required this.currency,
  });

  final List<Holding> holdings;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    double totalMarketValue = 0;
    double totalBookValue = 0;
    for (final h in holdings) {
      totalMarketValue += h.marketValueConverted;
      totalBookValue += h.bookValueConverted;
    }
    final totalGain = totalMarketValue - totalBookValue;
    final totalGainPercent =
        totalBookValue > 0 ? (totalGain / totalBookValue) * 100 : 0.0;

    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Holdings Value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedText(theme),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            formatCurrency(totalMarketValue, currency: currency),
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _SummaryMetric(
                label: 'Total Gain',
                child: GainLossText(
                  value: totalGain,
                  formatted: formatCurrency(totalGain,
                      currency: currency, compact: true),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              _SummaryMetric(
                label: 'Gain %',
                child: GainLossText(
                  value: totalGainPercent,
                  formatted: formatPercent(totalGainPercent),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              _SummaryMetric(
                label: 'Positions',
                child: Text(
                  '${holdings.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.mutedText(theme),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        child,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Individual holding card
// ---------------------------------------------------------------------------

class _HoldingCard extends StatelessWidget {
  const _HoldingCard({
    required this.holding,
    required this.currency,
    required this.controller,
  });

  final Holding holding;
  final String currency;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final typeColor = _holdingTypeColor(holding.holdingType);
    final avatarLetter =
        holding.symbol.isNotEmpty ? holding.symbol[0].toUpperCase() : '?';

    return SectionCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: AppRadius.base,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => HoldingDetailScreen(
                holding: holding,
                controller: controller,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              // Avatar circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    avatarLetter,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: typeColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),

              // Symbol + name + badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      holding.symbol,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      holding.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText(theme),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _HoldingTypeBadge(type: holding.holdingType),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),

              // Market value + gain
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(
                      holding.marketValueConverted,
                      currency: currency,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  GainLossText(
                    value: holding.unrealizedGain,
                    formatted: formatCurrency(
                      holding.unrealizedGain,
                      currency: currency,
                      compact: true,
                    ),
                    fontSize: 12,
                  ),
                  const SizedBox(height: 1),
                  GainLossText(
                    value: holding.unrealizedGainPercent,
                    formatted: formatPercent(holding.unrealizedGainPercent),
                    fontSize: 12,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _holdingTypeColor(String type) {
    return switch (type.toUpperCase()) {
      'EQUITY' => AppColors.blueLight,
      'ETF' => AppColors.cyanLight,
      'CRYPTO' => AppColors.orangeLight,
      'FIXED_INCOME' || 'BOND' => AppColors.yellowLight,
      'REAL_ESTATE' => AppColors.purpleLight,
      'CASH' => AppColors.greenLight,
      'ALTERNATIVE' => AppColors.magentaLight,
      _ => AppColors.tx2,
    };
  }
}

// ---------------------------------------------------------------------------
// Holding type badge
// ---------------------------------------------------------------------------

class _HoldingTypeBadge extends StatelessWidget {
  const _HoldingTypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bgColor, fgColor) = _badgeColors(type, theme);
    final label = _formatType(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fgColor,
        ),
      ),
    );
  }

  String _formatType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  (Color, Color) _badgeColors(String type, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return switch (type.toUpperCase()) {
      'EQUITY' => (
          AppColors.blueLight.withValues(alpha: isDark ? 0.20 : 0.12),
          AppColors.blueLight,
        ),
      'ETF' => (
          AppColors.cyanLight.withValues(alpha: isDark ? 0.20 : 0.12),
          AppColors.cyanLight,
        ),
      'CRYPTO' => (
          AppColors.orangeLight.withValues(alpha: isDark ? 0.20 : 0.12),
          AppColors.orangeLight,
        ),
      'FIXED_INCOME' || 'BOND' => (
          AppColors.yellowLight.withValues(alpha: isDark ? 0.20 : 0.12),
          AppColors.yellow,
        ),
      'REAL_ESTATE' => (
          AppColors.purpleLight.withValues(alpha: isDark ? 0.20 : 0.12),
          AppColors.purpleLight,
        ),
      'CASH' => (
          AppColors.greenLight.withValues(alpha: isDark ? 0.20 : 0.12),
          AppColors.green,
        ),
      'ALTERNATIVE' => (
          AppColors.magentaLight.withValues(alpha: isDark ? 0.20 : 0.12),
          AppColors.magentaLight,
        ),
      _ => (
          AppColors.outline(theme).withValues(alpha: 0.5),
          AppColors.mutedText(theme),
        ),
    };
  }
}

// ---------------------------------------------------------------------------
// Skeleton / loading state
// ---------------------------------------------------------------------------

class _HoldingsSkeleton extends StatelessWidget {
  const _HoldingsSkeleton({
    required this.onSearchTap,
    required this.searchOpen,
  });

  final VoidCallback onSearchTap;
  final bool searchOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shimmer = AppColors.skeleton(theme);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Holdings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: onSearchTap,
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: Padding(
        padding: kPagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card skeleton
            _SkeletonBox(
              width: double.infinity,
              height: 130,
              color: shimmer,
              radius: AppRadius.base,
            ),
            const SizedBox(height: AppSpacing.xl),
            // Sort row skeleton
            Row(
              children: [
                _SkeletonBox(width: 80, height: 14, color: shimmer),
                const Spacer(),
                _SkeletonBox(width: 100, height: 14, color: shimmer),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            // Holding cards skeleton
            for (var i = 0; i < 6; i++) ...[
              _SkeletonBox(
                width: double.infinity,
                height: 80,
                color: shimmer,
                radius: AppRadius.base,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
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
