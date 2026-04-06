import 'package:flutter/material.dart';
import 'package:wealthfolio_flutter/core/models/account.dart';
import 'package:wealthfolio_flutter/core/models/income_summary.dart';
import 'package:wealthfolio_flutter/core/services/app_controller.dart';
import 'package:wealthfolio_flutter/core/utils/currency_format.dart';
import 'package:wealthfolio_flutter/ui/app_colors.dart';
import 'package:wealthfolio_flutter/ui/design_tokens.dart';
import 'package:wealthfolio_flutter/ui/shared_widgets.dart';

// ---------------------------------------------------------------------------
// IncomeScreen
// ---------------------------------------------------------------------------

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  IncomeSummary? _summary;
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
      final result = await widget.controller.fetchIncomeSummary(
        accountId: _selectedAccountId,
      );
      if (!mounted) return;
      setState(() {
        _summary = result;
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

  Future<void> _refresh() async {
    try {
      final result = await widget.controller.fetchIncomeSummary(
        accountId: _selectedAccountId,
      );
      if (!mounted) return;
      setState(() {
        _summary = result;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Income')),
      body: _loading
          ? _IncomeSkeleton(theme: Theme.of(context))
          : _error != null
              ? ErrorRetryWidget(
                  message: _error!,
                  onRetry: _loadData,
                )
              : _summary == null
                  ? const EmptyStateCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No income data',
                      subtitle: 'Income summary will appear here once available.',
                    )
                  : _IncomeContent(
                      summary: _summary!,
                      accounts: widget.controller.accounts,
                      selectedAccountId: _selectedAccountId,
                      onAccountChanged: _onAccountChanged,
                      onRefresh: _refresh,
                    ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main content
// ---------------------------------------------------------------------------

class _IncomeContent extends StatelessWidget {
  const _IncomeContent({
    required this.summary,
    required this.accounts,
    required this.selectedAccountId,
    required this.onAccountChanged,
    required this.onRefresh,
  });

  final IncomeSummary summary;
  final List<Account> accounts;
  final String? selectedAccountId;
  final ValueChanged<String?> onAccountChanged;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: kPagePadding,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Account filter
          _AccountFilter(
            accounts: accounts,
            selectedAccountId: selectedAccountId,
            onChanged: onAccountChanged,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Summary grid
          Row(
            children: [
              Expanded(
                child: SummaryTile(
                  label: 'Total Dividends',
                  value: formatCurrency(
                    summary.totalDividends,
                    currency: summary.currency,
                  ),
                  icon: Icons.payments_outlined,
                  valueColor: AppColors.gainLossColor(summary.totalDividends),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: SummaryTile(
                  label: 'Total Interest',
                  value: formatCurrency(
                    summary.totalInterest,
                    currency: summary.currency,
                  ),
                  icon: Icons.percent_outlined,
                  valueColor: AppColors.gainLossColor(summary.totalInterest),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxxl),

          // Chart placeholder
          const _ChartPlaceholder(),
          const SizedBox(height: AppSpacing.xxxl),

          // Monthly breakdown
          _MonthlyBreakdown(summary: summary),
          const SizedBox(height: AppSpacing.huge),
        ],
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.inputFill(theme),
        borderRadius: AppRadius.base,
        border: Border.all(color: AppColors.outline(theme)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedAccountId,
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
            for (final Account account in accounts)
              DropdownMenuItem<String?>(
                value: account.id,
                child: Text(account.name),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chart placeholder
// ---------------------------------------------------------------------------

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = AppColors.greenLight;

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  baseColor.withValues(alpha: 0.20),
                  baseColor.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 140),
                  painter: _SparklinePainter(color: baseColor),
                ),
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
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.show_chart,
                  size: AppIconSize.sm,
                  color: AppColors.mutedText(theme),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Income over time',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedText(theme),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Decorative sparkline painter.
class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const points = [
      0.05, 0.75, 0.15, 0.60, 0.25, 0.70, 0.35, 0.50, 0.45, 0.55,
      0.55, 0.40, 0.65, 0.45, 0.75, 0.30, 0.85, 0.35, 0.95, 0.20,
    ];

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
  bool shouldRepaint(_SparklinePainter old) => old.color != color;
}

// ---------------------------------------------------------------------------
// Monthly breakdown section
// ---------------------------------------------------------------------------

class _MonthlyBreakdown extends StatelessWidget {
  const _MonthlyBreakdown({required this.summary});

  final IncomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byMonth = summary.byMonth;

    if (byMonth.isEmpty) {
      return const EmptyStateCard(
        icon: Icons.calendar_today_outlined,
        title: 'No monthly data',
        subtitle: 'Monthly income breakdown will appear as data accumulates.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Breakdown',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: byMonth.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = byMonth[index];
              return _MonthlyIncomeTile(
                item: item,
                currency: summary.currency,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MonthlyIncomeTile extends StatelessWidget {
  const _MonthlyIncomeTile({
    required this.item,
    required this.currency,
  });

  final MonthlyIncome item;
  final String currency;

  String _formatMonth(String isoMonth) {
    try {
      final parts = isoMonth.split('-');
      final year = parts[0];
      final month = int.parse(parts[1]);
      const monthNames = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${monthNames[month]} $year';
    } on Exception {
      return isoMonth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = item.dividends + item.interest;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          // Month label
          Expanded(
            flex: 2,
            child: Text(
              _formatMonth(item.month),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          // Dividends
          Expanded(
            flex: 3,
            child: Text(
              formatCurrency(item.dividends, currency: currency),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.gainLossColor(item.dividends),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Interest
          Expanded(
            flex: 3,
            child: Text(
              formatCurrency(item.interest, currency: currency),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.gainLossColor(item.interest),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Total
          Expanded(
            flex: 3,
            child: Text(
              formatCurrency(total, currency: currency),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.right,
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

class _IncomeSkeleton extends StatelessWidget {
  const _IncomeSkeleton({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: kPagePadding,
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.skeleton(theme),
            borderRadius: AppRadius.base,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.skeleton(theme),
                  borderRadius: AppRadius.base,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.skeleton(theme),
                  borderRadius: AppRadius.base,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.skeleton(theme),
            borderRadius: AppRadius.base,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Container(
          height: 18,
          width: 140,
          decoration: BoxDecoration(
            color: AppColors.skeleton(theme),
            borderRadius: AppRadius.xs,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < 4; i++) ...[
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.skeleton(theme),
              borderRadius: AppRadius.base,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
