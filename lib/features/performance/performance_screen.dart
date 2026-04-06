import 'package:flutter/material.dart';
import 'package:wealthfolio_flutter/core/models/holding.dart';
import 'package:wealthfolio_flutter/core/services/app_controller.dart';
import 'package:wealthfolio_flutter/core/utils/currency_format.dart';
import 'package:wealthfolio_flutter/ui/app_colors.dart';
import 'package:wealthfolio_flutter/ui/design_tokens.dart';
import 'package:wealthfolio_flutter/ui/shared_widgets.dart';

// ---------------------------------------------------------------------------
// Time range
// ---------------------------------------------------------------------------

enum _TimeRange {
  oneMonth('1M'),
  threeMonths('3M'),
  sixMonths('6M'),
  oneYear('1Y'),
  all('All');

  const _TimeRange(this.label);
  final String label;
}

// ---------------------------------------------------------------------------
// PerformanceScreen
// ---------------------------------------------------------------------------

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  _TimeRange _selectedRange = _TimeRange.all;

  Future<void> _refresh() => Future.wait<void>([
        widget.controller.refreshAccounts(showSpinner: false),
        widget.controller.refreshHoldings(showSpinner: false),
      ]);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final isLoading = widget.controller.loadingAccounts ||
            widget.controller.loadingHoldings;
        final hasError = widget.controller.errorMessage != null &&
            widget.controller.holdings.isEmpty;

        if (isLoading && widget.controller.holdings.isEmpty) {
          return const _PerformanceSkeleton();
        }

        if (hasError) {
          return Scaffold(
            appBar: _buildAppBar(context),
            body: ErrorRetryWidget(
              message: widget.controller.errorMessage!,
              onRetry: _refresh,
            ),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(context),
          body: _PerformanceContent(
            holdings: widget.controller.holdings,
            currency: widget.controller.baseCurrency,
            selectedRange: _selectedRange,
            onRangeChanged: (r) => setState(() => _selectedRange = r),
            onRefresh: _refresh,
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Performance'),
      centerTitle: false,
      actions: [
        if (widget.controller.loadingHoldings)
          const Padding(
            padding: EdgeInsets.only(right: AppSpacing.xl),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Main content
// ---------------------------------------------------------------------------

class _PerformanceContent extends StatelessWidget {
  const _PerformanceContent({
    required this.holdings,
    required this.currency,
    required this.selectedRange,
    required this.onRangeChanged,
    required this.onRefresh,
  });

  final List<Holding> holdings;
  final String currency;
  final _TimeRange selectedRange;
  final ValueChanged<_TimeRange> onRangeChanged;
  final Future<void> Function() onRefresh;

  _PortfolioMetrics _computeMetrics(List<Holding> hs) {
    double totalValue = 0;
    double totalGain = 0;
    double totalBook = 0;
    double totalDayChange = 0;

    for (final h in hs) {
      totalValue += h.marketValueConverted;
      totalBook += h.bookValueConverted;
      totalGain += h.unrealizedGain;
      totalDayChange += h.dayChange;
    }

    final totalReturn = totalBook > 0 ? (totalGain / totalBook) * 100 : 0.0;

    return _PortfolioMetrics(
      totalValue: totalValue,
      totalGain: totalGain,
      totalBook: totalBook,
      totalReturn: totalReturn,
      dayChange: totalDayChange,
    );
  }

  /// Holdings sorted by unrealizedGainPercent descending, cash excluded.
  List<Holding> _sortedHoldings(List<Holding> hs) {
    final nonCash = hs.where((h) => h.holdingType != 'CASH').toList();
    nonCash.sort(
      (a, b) => b.unrealizedGainPercent.compareTo(a.unrealizedGainPercent),
    );
    return nonCash;
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _computeMetrics(holdings);
    final sorted = _sortedHoldings(holdings);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Time range selector
          SliverToBoxAdapter(
            child: _TimeRangeSelector(
              selected: selectedRange,
              onChanged: onRangeChanged,
            ),
          ),

          // Summary cards 2x2 grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: _SummaryGrid(metrics: metrics, currency: currency),
            ),
          ),

          // Chart placeholder
          SliverToBoxAdapter(
            child: _ChartPlaceholder(gain: metrics.totalGain),
          ),

          // Section header: holdings table
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xxl,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Holdings Performance',
                badge: sorted.isEmpty ? null : '${sorted.length}',
              ),
            ),
          ),

          // Holdings table
          if (sorted.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              sliver: SliverToBoxAdapter(
                child: EmptyStateCard(
                  icon: Icons.trending_up_outlined,
                  title: 'No holdings yet',
                  subtitle:
                      'Import activities or add holdings to start tracking performance.',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              sliver: SliverToBoxAdapter(
                child: _HoldingsTable(
                  holdings: sorted,
                  currency: currency,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.huge)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Time range selector
// ---------------------------------------------------------------------------

class _TimeRangeSelector extends StatelessWidget {
  const _TimeRangeSelector({
    required this.selected,
    required this.onChanged,
  });

  final _TimeRange selected;
  final ValueChanged<_TimeRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Row(
        spacing: AppSpacing.md,
        children: _TimeRange.values.map((range) {
          final isSelected = range == selected;
          return _RangeChip(
            label: range.label,
            selected: isSelected,
            onTap: () => onChanged(range),
          );
        }).toList(),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary
              : AppColors.outline(theme).withValues(alpha: 0.5),
          borderRadius: AppRadius.pill,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? cs.onPrimary : AppColors.mutedText(theme),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2x2 summary grid
// ---------------------------------------------------------------------------

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.metrics, required this.currency});

  final _PortfolioMetrics metrics;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final dayChangeColor = AppColors.gainLossColor(metrics.dayChange);
    final gainColor = AppColors.gainLossColor(metrics.totalGain);
    final returnColor = AppColors.gainLossColor(metrics.totalReturn);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryTile(
                label: 'Total Value',
                value: formatCurrency(
                  metrics.totalValue,
                  currency: currency,
                  compact: true,
                ),
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: SummaryTile(
                label: 'Total Gain / Loss',
                value: formatCurrency(
                  metrics.totalGain,
                  currency: currency,
                  compact: true,
                ),
                valueColor: gainColor,
                icon: Icons.show_chart_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: SummaryTile(
                label: 'Total Return',
                value: formatPercent(metrics.totalReturn),
                valueColor: returnColor,
                icon: Icons.percent_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: SummaryTile(
                label: 'Day Change',
                value: formatCurrency(
                  metrics.dayChange,
                  currency: currency,
                  compact: true,
                ),
                valueColor: dayChangeColor,
                icon: Icons.today_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Chart placeholder
// ---------------------------------------------------------------------------

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.gain});

  final double gain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = gain >= 0;
    final lineColor = isPositive ? AppColors.gain : AppColors.loss;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        0,
      ),
      child: SectionCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: AppRadius.base,
          child: SizedBox(
            height: 200,
            child: Stack(
              children: [
                // Gradient fill
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        lineColor.withValues(alpha: 0.15),
                        lineColor.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
                // Decorative sparkline
                CustomPaint(
                  size: const Size(double.infinity, 200),
                  painter: _SparklinePainter(
                    color: lineColor,
                    positive: isPositive,
                  ),
                ),
                // Label row at top
                Positioned(
                  top: AppSpacing.xl,
                  left: AppSpacing.xl,
                  child: Text(
                    'Performance Chart',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                // Coming soon badge
                Positioned(
                  bottom: AppSpacing.xl,
                  right: AppSpacing.xl,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: lineColor.withValues(alpha: 0.12),
                      borderRadius: AppRadius.pill,
                      border: Border.all(
                        color: lineColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      'Chart coming soon',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: lineColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.color, required this.positive});

  final Color color;
  final bool positive;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Decorative data points (not real data) — normalized [x, y]
    final pts = positive
        ? <double>[
            0.02, 0.78, 0.10, 0.68, 0.18, 0.72, 0.26, 0.60, 0.34, 0.52,
            0.42, 0.55, 0.50, 0.44, 0.58, 0.38, 0.66, 0.42, 0.74, 0.30,
            0.82, 0.25, 0.90, 0.28, 0.98, 0.18,
          ]
        : <double>[
            0.02, 0.22, 0.10, 0.28, 0.18, 0.24, 0.26, 0.36, 0.34, 0.42,
            0.42, 0.38, 0.50, 0.48, 0.58, 0.55, 0.66, 0.52, 0.74, 0.62,
            0.82, 0.68, 0.90, 0.65, 0.98, 0.74,
          ];

    final path = Path();
    for (var i = 0; i < pts.length - 1; i += 2) {
      final x = pts[i] * size.width;
      final y = pts[i + 1] * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = pts[i - 2] * size.width;
        final prevY = pts[i - 1] * size.height;
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.color != color || old.positive != positive;
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.badge});

  final String title;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.outline(theme).withValues(alpha: 0.6),
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              badge!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedText(theme),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Holdings performance table
// ---------------------------------------------------------------------------

class _HoldingsTable extends StatelessWidget {
  const _HoldingsTable({
    required this.holdings,
    required this.currency,
  });

  final List<Holding> holdings;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Table header row
          _TableHeaderRow(theme: theme),
          const Divider(height: 1),
          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: holdings.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) => _HoldingRow(
              holding: holdings[index],
              currency: currency,
              rank: index + 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.mutedText(theme),
      letterSpacing: 0.3,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('SYMBOL', style: labelStyle),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'MARKET VALUE',
              style: labelStyle,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'GAIN / LOSS',
              style: labelStyle,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'RETURN',
              style: labelStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({
    required this.holding,
    required this.currency,
    required this.rank,
  });

  final Holding holding;
  final String currency;
  final int rank;

  Color _symbolColor(String type) {
    return switch (type.toUpperCase()) {
      'EQUITY' => AppColors.blueLight,
      'ETF' => AppColors.cyanLight,
      'CRYPTO' => AppColors.orangeLight,
      'FIXED_INCOME' || 'BOND' => AppColors.yellowLight,
      'REAL_ESTATE' => AppColors.purpleLight,
      _ => AppColors.tx2,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final gainColor = AppColors.gainLossColor(holding.unrealizedGain);
    final symbolColor = _symbolColor(holding.holdingType);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          // Symbol + avatar
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: symbolColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.xs,
                  ),
                  child: Center(
                    child: Text(
                      holding.symbol.length > 3
                          ? holding.symbol.substring(0, 3)
                          : holding.symbol,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: symbolColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        holding.symbol,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        holding.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.mutedText(theme),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Market value
          Expanded(
            flex: 3,
            child: Text(
              formatCurrency(
                holding.marketValueConverted,
                currency: currency,
                compact: true,
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          // Gain / loss absolute
          Expanded(
            flex: 3,
            child: Text(
              formatCurrency(
                holding.unrealizedGain,
                currency: currency,
                compact: true,
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: gainColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          // Return percent
          Expanded(
            flex: 2,
            child: _ReturnBadge(percent: holding.unrealizedGainPercent),
          ),
        ],
      ),
    );
  }
}

class _ReturnBadge extends StatelessWidget {
  const _ReturnBadge({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.gainLossColor(percent);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: AppRadius.xs,
        ),
        child: Text(
          formatPercent(percent),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loading state
// ---------------------------------------------------------------------------

class _PerformanceSkeleton extends StatelessWidget {
  const _PerformanceSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shimmer = AppColors.skeleton(theme);

    return Scaffold(
      appBar: AppBar(title: const Text('Performance'), centerTitle: false),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Range chips skeleton
            Row(
              spacing: AppSpacing.md,
              children: List.generate(
                5,
                (_) => _SkeletonBox(width: 44, height: 32, color: shimmer, radius: AppRadius.pill),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            // 2x2 grid skeleton
            Row(
              children: [
                Expanded(
                  child: _SkeletonBox(
                    width: double.infinity,
                    height: 88,
                    color: shimmer,
                    radius: AppRadius.base,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _SkeletonBox(
                    width: double.infinity,
                    height: 88,
                    color: shimmer,
                    radius: AppRadius.base,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _SkeletonBox(
                    width: double.infinity,
                    height: 88,
                    color: shimmer,
                    radius: AppRadius.base,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _SkeletonBox(
                    width: double.infinity,
                    height: 88,
                    color: shimmer,
                    radius: AppRadius.base,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            // Chart skeleton
            _SkeletonBox(
              width: double.infinity,
              height: 200,
              color: shimmer,
              radius: AppRadius.base,
            ),
            const SizedBox(height: AppSpacing.xxl),
            // Table header
            _SkeletonBox(width: 180, height: 16, color: shimmer),
            const SizedBox(height: AppSpacing.lg),
            _SkeletonBox(
              width: double.infinity,
              height: 240,
              color: shimmer,
              radius: AppRadius.base,
            ),
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

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _PortfolioMetrics {
  const _PortfolioMetrics({
    required this.totalValue,
    required this.totalGain,
    required this.totalBook,
    required this.totalReturn,
    required this.dayChange,
  });

  final double totalValue;
  final double totalGain;
  final double totalBook;
  final double totalReturn;
  final double dayChange;
}
