import 'package:flutter/material.dart';
import 'package:wealthfolio_flutter/core/models/account.dart';
import 'package:wealthfolio_flutter/core/models/holding.dart';
import 'package:wealthfolio_flutter/core/services/app_controller.dart';
import 'package:wealthfolio_flutter/core/utils/currency_format.dart';
import 'package:wealthfolio_flutter/ui/app_colors.dart';
import 'package:wealthfolio_flutter/ui/design_tokens.dart';
import 'package:wealthfolio_flutter/ui/shared_widgets.dart';

// ---------------------------------------------------------------------------
// HoldingDetailScreen
// ---------------------------------------------------------------------------

class HoldingDetailScreen extends StatelessWidget {
  const HoldingDetailScreen({
    super.key,
    required this.holding,
    this.controller,
  });

  final Holding holding;
  final AppController? controller;

  @override
  Widget build(BuildContext context) {
    // If a controller is provided, listen to it so that account data stays
    // reactive. Otherwise render statically from the passed-in holding.
    if (controller != null) {
      return ListenableBuilder(
        listenable: controller!,
        builder: (context, _) => _buildScaffold(
          context,
          account: _findAccount(controller!.accounts),
        ),
      );
    }

    return _buildScaffold(context, account: null);
  }

  Account? _findAccount(List<Account> accounts) {
    try {
      return accounts.firstWhere((a) => a.id == holding.accountId);
    } catch (_) {
      return null;
    }
  }

  Widget _buildScaffold(BuildContext context, {required Account? account}) {
    return Scaffold(
      appBar: AppBar(
        title: Text(holding.symbol),
        leading: const BackButton(),
        actions: [
          if (controller != null)
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () =>
                  controller!.refreshHoldings(showSpinner: false),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (controller != null) {
            await controller!.refreshHoldings(showSpinner: false);
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.huge,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Hero card ─────────────────────────────────────────────
                  _HeroCard(holding: holding),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Day change banner ─────────────────────────────────────
                  _DayChangeBanner(holding: holding),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Info grid ─────────────────────────────────────────────
                  _SectionLabel(label: 'Position Details'),
                  const SizedBox(height: AppSpacing.lg),
                  _InfoGrid(holding: holding),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Chart placeholder ─────────────────────────────────────
                  _SectionLabel(label: 'Price Chart'),
                  const SizedBox(height: AppSpacing.lg),
                  _ChartPlaceholder(symbol: holding.symbol),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Account info ──────────────────────────────────────────
                  _SectionLabel(label: 'Account'),
                  const SizedBox(height: AppSpacing.lg),
                  _AccountCard(
                    accountId: holding.accountId,
                    account: account,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.mutedText(theme),
        letterSpacing: 0.6,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero card: symbol, name, market value
// ---------------------------------------------------------------------------

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.holding});

  final Holding holding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final typeColor = _holdingTypeColor(holding.holdingType);

    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    holding.symbol.isNotEmpty
                        ? holding.symbol[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: typeColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      holding.symbol,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      holding.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedText(theme),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _HoldingTypeBadge(type: holding.holdingType),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Market Value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedText(theme),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatCurrency(
              holding.marketValueConverted,
              currency: holding.baseCurrency,
            ),
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              height: 1.1,
            ),
          ),
          if (holding.currency != holding.baseCurrency) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${formatCurrency(holding.marketValue, currency: holding.currency)} '
              '${holding.currency}',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.mutedText(theme),
              ),
            ),
          ],
        ],
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
// Day change banner
// ---------------------------------------------------------------------------

class _DayChangeBanner extends StatelessWidget {
  const _DayChangeBanner({required this.holding});

  final Holding holding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gain = holding.dayChange;
    final gainPct = holding.dayChangePercent;
    final color = AppColors.gainLossColor(gain);
    final isPositive = gain >= 0;
    final arrowIcon =
        isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down;

    return SectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Icon(arrowIcon, color: color, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Today\'s change',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.mutedText(theme),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency(gain,
                    currency: holding.baseCurrency, compact: true),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                formatPercent(gainPct),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info grid (2 columns)
// ---------------------------------------------------------------------------

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.holding});

  final Holding holding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final items = <({String label, Widget value})>[
      (
        label: 'Quantity',
        value: _plainValue(
          formatNumber(holding.quantity,
              decimals: holding.quantity == holding.quantity.truncate() ? 0 : 4),
          cs.onSurface,
        ),
      ),
      (
        label: 'Average Cost',
        value: _plainValue(
          formatCurrency(holding.averageCost, currency: holding.currency),
          cs.onSurface,
        ),
      ),
      (
        label: 'Book Value',
        value: _plainValue(
          formatCurrency(
            holding.bookValueConverted,
            currency: holding.baseCurrency,
          ),
          cs.onSurface,
        ),
      ),
      (
        label: 'Currency',
        value: _plainValue(
          holding.currency == holding.baseCurrency
              ? holding.currency
              : '${holding.currency} / ${holding.baseCurrency}',
          cs.onSurface,
        ),
      ),
      (
        label: 'Unrealized Gain',
        value: GainLossText(
          value: holding.unrealizedGain,
          formatted: formatCurrency(
            holding.unrealizedGain,
            currency: holding.baseCurrency,
            compact: true,
          ),
          fontSize: 14,
        ),
      ),
      (
        label: 'Gain %',
        value: GainLossText(
          value: holding.unrealizedGainPercent,
          formatted: formatPercent(holding.unrealizedGainPercent),
          fontSize: 14,
        ),
      ),
    ];

    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Wrap(
        runSpacing: AppSpacing.xxl,
        children: [
          for (var i = 0; i < items.length; i++)
            SizedBox(
              width: MediaQuery.sizeOf(context).width / 2 -
                  AppSpacing.xl * 2 -
                  AppSpacing.xl,
              child: _InfoCell(
                label: items[i].label,
                value: items[i].value,
              ),
            ),
        ],
      ),
    );
  }

  Widget _plainValue(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({required this.label, required this.value});

  final String label;
  final Widget value;

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
            fontWeight: FontWeight.w500,
            color: AppColors.mutedText(theme),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 5),
        value,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Chart placeholder
// ---------------------------------------------------------------------------

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: AppRadius.base,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.outline(theme).withValues(alpha: 0.4),
              AppColors.outline(theme).withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.candlestick_chart_outlined,
              size: AppIconSize.xxl,
              color: AppColors.tertiaryText(theme),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Price chart coming soon',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedText(theme),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$symbol historical data',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.tertiaryText(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account info card
// ---------------------------------------------------------------------------

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.accountId,
    required this.account,
  });

  final String accountId;
  final Account? account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (account == null) {
      return SectionCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.outline(theme).withValues(alpha: 0.5),
                borderRadius: AppRadius.sm,
              ),
              child: Icon(
                Icons.account_balance_outlined,
                size: AppIconSize.md,
                color: AppColors.mutedText(theme),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unknown account',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedText(theme),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: $accountId',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.tertiaryText(theme),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final accountTypeLabel = account!.accountType
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');

    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cyanLight.withValues(alpha: 0.12),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(
              _accountIcon(account!.accountType),
              size: AppIconSize.md,
              color: AppColors.cyanLight,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account!.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _SmallBadge(label: accountTypeLabel),
                    const SizedBox(width: AppSpacing.md),
                    _SmallBadge(label: account!.currency),
                  ],
                ),
              ],
            ),
          ),
          if (!account!.isActive)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: _SmallBadge(
                label: 'Archived',
                color: AppColors.mutedText(theme),
              ),
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

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.outline(theme).withValues(alpha: 0.5),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color ?? AppColors.mutedText(theme),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Holding type badge (shared with hero card)
// ---------------------------------------------------------------------------

class _HoldingTypeBadge extends StatelessWidget {
  const _HoldingTypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final (bgColor, fgColor) = _badgeColors(type, isDark);
    final label = type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fgColor,
        ),
      ),
    );
  }

  (Color, Color) _badgeColors(String type, bool isDark) {
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
      _ => (AppColors.tx3.withValues(alpha: 0.3), AppColors.tx2),
    };
  }
}
