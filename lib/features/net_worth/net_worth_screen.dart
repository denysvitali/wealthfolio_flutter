import 'package:flutter/material.dart';
import 'package:wealthfolio_flutter/core/models/net_worth.dart';
import 'package:wealthfolio_flutter/core/services/app_controller.dart';
import 'package:wealthfolio_flutter/core/utils/currency_format.dart';
import 'package:wealthfolio_flutter/ui/app_colors.dart';
import 'package:wealthfolio_flutter/ui/design_tokens.dart';
import 'package:wealthfolio_flutter/ui/shared_widgets.dart';

// ---------------------------------------------------------------------------
// NetWorthScreen
// ---------------------------------------------------------------------------

class NetWorthScreen extends StatefulWidget {
  const NetWorthScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends State<NetWorthScreen> {
  NetWorthResponse? _data;
  List<NetWorthHistoryPoint> _history = const <NetWorthHistoryPoint>[];
  bool _loading = true;
  String? _error;

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
      final now = DateTime.now();
      final start = DateTime(now.year - 1, now.month, now.day);
      final futures = await Future.wait<dynamic>([
        widget.controller.fetchNetWorth(),
        widget.controller.fetchNetWorthHistory(
          startDate: _toApiDate(start),
          endDate: _toApiDate(now),
        ),
      ]);
      final result = futures[0] as NetWorthResponse;
      final history = futures[1] as List<NetWorthHistoryPoint>;
      if (!mounted) return;
      setState(() {
        _data = result;
        _history = history;
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

  String _toApiDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Net Worth'),
        centerTitle: false,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return _buildSkeleton(context);
    }

    if (_error != null) {
      return ErrorRetryWidget(
        message: _error!,
        onRetry: _loadData,
      );
    }

    final data = _data;
    if (data == null || data.total == 0) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: kPagePadding,
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            EmptyStateCard(
              icon: Icons.account_balance_outlined,
              title: 'No net worth data',
              subtitle: 'Add accounts and holdings to see your net worth breakdown.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: _buildContent(context, data),
    );
  }

  Widget _buildContent(BuildContext context, NetWorthResponse data) {
    final theme = Theme.of(context);
    final currency = widget.controller.baseCurrency;

    return ListView(
      padding: kPagePadding,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // -----------------------------------------------------------------
        // Hero card: total net worth
        // -----------------------------------------------------------------
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Net Worth',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mutedText(theme),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                formatCurrency(data.total, currency: currency),
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // -----------------------------------------------------------------
        // Breakdown grid (2 columns)
        // -----------------------------------------------------------------
        Row(
          children: [
            Expanded(
              child: SummaryTile(
                label: 'Investments',
                value: formatCurrency(data.investmentsTotal, currency: currency),
                icon: Icons.trending_up_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: SummaryTile(
                label: 'Cash',
                value: formatCurrency(data.cashTotal, currency: currency),
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: SummaryTile(
                label: 'Alternatives',
                value: formatCurrency(data.alternativesTotal, currency: currency),
                icon: Icons.diamond_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: SummaryTile(
                label: 'Liabilities',
                value: formatCurrency(data.liabilitiesTotal, currency: currency),
                valueColor: AppColors.red,
                icon: Icons.trending_down_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),

        // -----------------------------------------------------------------
        // Chart placeholder
        // -----------------------------------------------------------------
        SimpleLineChartCard(
          title: 'Net Worth History',
          color: AppColors.blue,
          points: _history
              .map((item) => SimpleLineChartPoint(
                    date: DateTime.tryParse(item.date) ?? DateTime.now(),
                    value: item.total,
                  ))
              .toList(growable: false),
          valueFormatter: (value) => formatCurrency(value, currency: currency),
        ),
        const SizedBox(height: AppSpacing.huge),
      ],
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: kPagePadding,
      children: [
        Container(
          height: 120,
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
      ],
    );
  }
}
