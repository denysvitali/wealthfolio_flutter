import 'package:flutter/material.dart';
import 'package:wealthfolio_flutter/core/models/account.dart';
import 'package:wealthfolio_flutter/core/models/holding.dart';
import 'package:wealthfolio_flutter/core/services/app_controller.dart';
import 'package:wealthfolio_flutter/core/utils/currency_format.dart';
import 'package:wealthfolio_flutter/features/goals/goals_screen.dart';
import 'package:wealthfolio_flutter/features/income/income_screen.dart';
import 'package:wealthfolio_flutter/features/insights/insights_screen.dart';
import 'package:wealthfolio_flutter/features/net_worth/net_worth_screen.dart';
import 'package:wealthfolio_flutter/ui/app_colors.dart';
import 'package:wealthfolio_flutter/ui/design_tokens.dart';
import 'package:wealthfolio_flutter/ui/shared_widgets.dart';

// ---------------------------------------------------------------------------
// DashboardScreen
// ---------------------------------------------------------------------------

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isLoading =
            controller.loadingAccounts || controller.loadingHoldings;
        final hasError = controller.errorMessage != null &&
            controller.accounts.isEmpty &&
            controller.holdings.isEmpty;

        // Show a full-screen loader only on the very first load when there's
        // no data at all yet.
        if (isLoading && controller.accounts.isEmpty && controller.holdings.isEmpty) {
          return const _DashboardSkeleton();
        }

        if (hasError) {
          return _DashboardError(
            message: controller.errorMessage!,
            onRetry: () async {
              await Future.wait<void>([
                controller.refreshAccounts(showSpinner: false),
                controller.refreshHoldings(showSpinner: false),
              ]);
            },
          );
        }

        return _DashboardContent(controller: controller);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Main scrollable content
// ---------------------------------------------------------------------------

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.controller});

  final AppController controller;

  /// Compute portfolio totals from holdings.
  _PortfolioTotals _computeTotals(List<Holding> holdings) {
    double marketValue = 0;
    double bookValue = 0;
    for (final h in holdings) {
      marketValue += h.marketValueConverted;
      bookValue += h.bookValueConverted;
    }
    final gain = marketValue - bookValue;
    final gainPercent = bookValue > 0 ? (gain / bookValue) * 100 : 0.0;
    return _PortfolioTotals(
      marketValue: marketValue,
      bookValue: bookValue,
      gain: gain,
      gainPercent: gainPercent,
    );
  }

  /// Top 5 holdings by market value (excluding CASH type).
  List<Holding> _topHoldings(List<Holding> holdings) {
    final nonCash =
        holdings.where((h) => h.holdingType != 'CASH').toList();
    nonCash.sort((a, b) =>
        b.marketValueConverted.compareTo(a.marketValueConverted));
    return nonCash.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final holdings = controller.holdings;
    final accounts = controller.accounts.where((a) => a.isActive).toList();
    final currency = controller.baseCurrency;
    final totals = _computeTotals(holdings);
    final top5 = _topHoldings(holdings);

    return RefreshIndicator(
      onRefresh: () => Future.wait<void>([
        controller.refreshAccounts(showSpinner: false),
        controller.refreshHoldings(showSpinner: false),
      ]),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // -----------------------------------------------------------------
          // Hero section: total portfolio value + gain
          // -----------------------------------------------------------------
          SliverToBoxAdapter(
            child: _HeroSection(totals: totals, currency: currency),
          ),

          // -----------------------------------------------------------------
          // Chart area (gradient placeholder)
          // -----------------------------------------------------------------
          SliverToBoxAdapter(
            child: _ChartPlaceholder(gain: totals.gain),
          ),

          // -----------------------------------------------------------------
          // Body content: accounts + top holdings
          // -----------------------------------------------------------------
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xxl,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionHeader(
                  title: 'Accounts',
                  badge: accounts.isEmpty ? null : '${accounts.length}',
                ),
                const SizedBox(height: AppSpacing.lg),
                if (accounts.isEmpty)
                  const EmptyStateCard(
                    icon: Icons.account_balance_outlined,
                    title: 'No accounts yet',
                    subtitle: 'Add an account to track your portfolio.',
                  )
                else
                  _AccountsList(
                    accounts: accounts,
                    holdings: holdings,
                    currency: currency,
                  ),
                const SizedBox(height: AppSpacing.xxxl),
                const _SectionHeader(title: 'Top Holdings'),
                const SizedBox(height: AppSpacing.lg),
                if (top5.isEmpty)
                  const EmptyStateCard(
                    icon: Icons.pie_chart_outline,
                    title: 'No holdings yet',
                    subtitle:
                        'Import activities or add holdings to get started.',
                  )
                else
                  _TopHoldingsList(holdings: top5, currency: currency),
                const SizedBox(height: AppSpacing.xxxl),
                const _SectionHeader(title: 'Explore'),
                const SizedBox(height: AppSpacing.lg),
                _QuickLinksGrid(controller: controller),
                // Bottom safe area padding
                const SizedBox(height: AppSpacing.huge),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero section
// ---------------------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.totals, required this.currency});

  final _PortfolioTotals totals;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.huge,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portfolio',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedText(theme),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatCurrency(totals.marketValue, currency: currency),
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              GainLossText(
                value: totals.gain,
                formatted: formatCurrency(totals.gain, currency: currency),
                fontSize: 15,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  '|',
                  style: TextStyle(
                    color: AppColors.tertiaryText(theme),
                    fontSize: 15,
                  ),
                ),
              ),
              GainLossText(
                value: totals.gainPercent,
                formatted: formatPercent(totals.gainPercent),
                fontSize: 15,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'All time',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.tertiaryText(theme),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chart placeholder — gradient rectangle
// ---------------------------------------------------------------------------

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.gain});

  final double gain;

  @override
  Widget build(BuildContext context) {
    final positiveGain = gain >= 0;
    final baseColor = positiveGain ? AppColors.gain : AppColors.loss;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            baseColor.withValues(alpha: 0.20),
            baseColor.withValues(alpha: 0.04),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Fake sparkline to suggest a chart
          CustomPaint(
            size: const Size(double.infinity, 180),
            painter: _SparklinePainter(color: baseColor, positive: positiveGain),
          ),
          // "Chart coming soon" hint
          Positioned(
            bottom: 12,
            right: 16,
            child: Text(
              'Chart coming soon',
              style: TextStyle(
                fontSize: 11,
                color: baseColor.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple decorative sparkline painter.
class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.color, required this.positive});

  final Color color;
  final bool positive;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Hardcoded decorative path — not real data.
    final points = positive
        ? [0.05, 0.80, 0.15, 0.65, 0.25, 0.70, 0.35, 0.55, 0.45, 0.45,
           0.55, 0.50, 0.65, 0.35, 0.75, 0.25, 0.85, 0.30, 0.95, 0.20]
        : [0.05, 0.20, 0.15, 0.30, 0.25, 0.25, 0.35, 0.40, 0.45, 0.50,
           0.55, 0.45, 0.65, 0.60, 0.75, 0.65, 0.85, 0.70, 0.95, 0.80];

    final path = Path();
    for (var i = 0; i < points.length - 1; i += 2) {
      final x = points[i] * size.width;
      final y = points[i + 1] * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = points[i - 2] * size.width;
        final prevY = points[i - 1] * size.height;
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }
    canvas.drawPath(path, paint);
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
// Accounts list
// ---------------------------------------------------------------------------

class _AccountsList extends StatelessWidget {
  const _AccountsList({
    required this.accounts,
    required this.holdings,
    required this.currency,
  });

  final List<Account> accounts;
  final List<Holding> holdings;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: accounts.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final account = accounts[index];
          return _AccountTile(
            account: account,
            holdings: holdings
                .where((h) => h.accountId == account.id)
                .toList(),
            currency: currency,
          );
        },
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.holdings,
    required this.currency,
  });

  final Account account;
  final List<Holding> holdings;
  final String currency;

  double get _marketValue =>
      holdings.fold(0, (sum, h) => sum + h.marketValueConverted);

  double get _bookValue =>
      holdings.fold(0, (sum, h) => sum + h.bookValueConverted);

  double get _gain => _marketValue - _bookValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final marketValue = _marketValue;
    final gain = _gain;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          // Account icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cyanLight.withValues(alpha: 0.12),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(
              _accountIcon(account.accountType),
              size: AppIconSize.md,
              color: AppColors.cyanLight,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // Name + type badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                _AccountTypeBadge(type: account.accountType),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // Value + gain
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency(marketValue, currency: currency),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              GainLossText(
                value: gain,
                formatted: formatCurrency(gain, currency: currency, compact: true),
                fontSize: 12,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _accountIcon(String type) {
    return switch (type.toUpperCase()) {
      'BROKERAGE' => Icons.bar_chart,
      'SAVINGS' || 'CHECKING' => Icons.savings_outlined,
      'CRYPTO' => Icons.currency_bitcoin,
      'RETIREMENT' || 'IRA' || 'ROTH_IRA' => Icons.elderly_outlined,
      'TFSA' || 'RRSP' => Icons.shield_outlined,
      _ => Icons.account_balance_outlined,
    };
  }
}

class _AccountTypeBadge extends StatelessWidget {
  const _AccountTypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.outline(theme).withValues(alpha: 0.5),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.mutedText(theme),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top holdings list
// ---------------------------------------------------------------------------

class _TopHoldingsList extends StatelessWidget {
  const _TopHoldingsList({required this.holdings, required this.currency});

  final List<Holding> holdings;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: holdings.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => _HoldingTile(
          holding: holdings[index],
          currency: currency,
          rank: index + 1,
        ),
      ),
    );
  }
}

class _HoldingTile extends StatelessWidget {
  const _HoldingTile({
    required this.holding,
    required this.currency,
    required this.rank,
  });

  final Holding holding;
  final String currency;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          // Symbol avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _holdingColor(holding.holdingType).withValues(alpha: 0.12),
              borderRadius: AppRadius.sm,
            ),
            child: Center(
              child: Text(
                holding.symbol.length > 3
                    ? holding.symbol.substring(0, 3)
                    : holding.symbol,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _holdingColor(holding.holdingType),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // Symbol + name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holding.symbol,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // Market value + day change
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency(
                  holding.marketValueConverted,
                  currency: currency,
                  compact: true,
                ),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              GainLossText(
                value: holding.dayChangePercent,
                formatted: formatPercent(holding.dayChangePercent),
                fontSize: 12,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _holdingColor(String type) {
    return switch (type.toUpperCase()) {
      'EQUITY' => AppColors.blueLight,
      'ETF' => AppColors.cyanLight,
      'CRYPTO' => AppColors.orangeLight,
      'FIXED_INCOME' || 'BOND' => AppColors.yellowLight,
      'REAL_ESTATE' => AppColors.purpleLight,
      _ => AppColors.tx2,
    };
  }
}

// ---------------------------------------------------------------------------
// Skeleton / loading state
// ---------------------------------------------------------------------------

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shimmer = AppColors.skeleton(theme);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              _SkeletonBox(width: 80, height: 14, color: shimmer),
              const SizedBox(height: AppSpacing.md),
              _SkeletonBox(width: 220, height: 36, color: shimmer),
              const SizedBox(height: AppSpacing.md),
              _SkeletonBox(width: 150, height: 18, color: shimmer),
              const SizedBox(height: AppSpacing.xl),
              _SkeletonBox(
                width: double.infinity,
                height: 180,
                color: shimmer,
                radius: AppRadius.base,
              ),
              const SizedBox(height: AppSpacing.xxl),
              _SkeletonBox(width: 100, height: 18, color: shimmer),
              const SizedBox(height: AppSpacing.lg),
              _SkeletonBox(
                width: double.infinity,
                height: 160,
                color: shimmer,
                radius: AppRadius.base,
              ),
              const SizedBox(height: AppSpacing.xxl),
              _SkeletonBox(width: 120, height: 18, color: shimmer),
              const SizedBox(height: AppSpacing.lg),
              _SkeletonBox(
                width: double.infinity,
                height: 200,
                color: shimmer,
                radius: AppRadius.base,
              ),
            ],
          ),
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
// Error state
// ---------------------------------------------------------------------------

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ErrorRetryWidget(message: message, onRetry: onRetry),
    );
  }
}

// ---------------------------------------------------------------------------
// Portfolio totals value object
// ---------------------------------------------------------------------------

class _PortfolioTotals {
  const _PortfolioTotals({
    required this.marketValue,
    required this.bookValue,
    required this.gain,
    required this.gainPercent,
  });

  final double marketValue;
  final double bookValue;
  final double gain;
  final double gainPercent;
}

// ---------------------------------------------------------------------------
// Quick Links grid — Phase 4 secondary screens
// ---------------------------------------------------------------------------

class _QuickLinksGrid extends StatelessWidget {
  const _QuickLinksGrid({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <_QuickLinkItem>[
      _QuickLinkItem(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Net Worth',
        color: AppColors.blue,
        onTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => NetWorthScreen(controller: controller),
          ),
        ),
      ),
      _QuickLinkItem(
        icon: Icons.savings_outlined,
        label: 'Goals',
        color: AppColors.green,
        onTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => GoalsScreen(controller: controller),
          ),
        ),
      ),
      _QuickLinkItem(
        icon: Icons.payments_outlined,
        label: 'Income',
        color: AppColors.purple,
        onTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => IncomeScreen(controller: controller),
          ),
        ),
      ),
      _QuickLinkItem(
        icon: Icons.insights_outlined,
        label: 'Insights',
        color: AppColors.orange,
        onTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => InsightsScreen(controller: controller),
          ),
        ),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.xl,
      crossAxisSpacing: AppSpacing.xl,
      childAspectRatio: 2.2,
      children: items.map((item) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outline(theme)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 24, color: item.color),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickLinkItem {
  const _QuickLinkItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}
