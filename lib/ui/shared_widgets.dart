import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:wealthfolio_flutter/ui/app_colors.dart';
import 'package:wealthfolio_flutter/ui/design_tokens.dart';

const EdgeInsets kPagePadding = EdgeInsets.fromLTRB(16, 8, 16, 16);

/// A card with Flexoki styling.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.xl),
      decoration: AppCardDecoration.card(
        backgroundColor: theme.colorScheme.surface,
        borderColor: AppColors.outline(theme),
      ),
      child: child,
    );
  }
}

/// Summary metric tile used on dashboard and detail screens.
class SummaryTile extends StatelessWidget {
  const SummaryTile({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
    this.icon,
  });
  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppIconSize.sm, color: AppColors.mutedText(theme)),
                const SizedBox(width: AppSpacing.md),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText(theme),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 13, color: AppColors.mutedText(theme)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Gain/loss indicator with arrow and color.
class GainLossText extends StatelessWidget {
  const GainLossText({
    super.key,
    required this.value,
    required this.formatted,
    this.fontSize = 14,
  });
  final double value;
  final String formatted;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.gainLossColor(value);
    final icon = value >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: fontSize + 6),
        Text(
          formatted,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Empty state card with icon and message.
class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      padding: const EdgeInsets.symmetric(
        vertical: 48,
        horizontal: AppSpacing.xxl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIconSize.huge, color: AppColors.tertiaryText(theme)),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 14, color: AppColors.mutedText(theme)),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Error + retry widget.
class ErrorRetryWidget extends StatelessWidget {
  const ErrorRetryWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: kPagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.xl),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText(Theme.of(context))),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleLineChartPoint {
  const SimpleLineChartPoint({
    required this.date,
    required this.value,
  });

  final DateTime date;
  final double value;
}

class SimpleLineChartCard extends StatelessWidget {
  const SimpleLineChartCard({
    super.key,
    required this.title,
    required this.points,
    required this.color,
    this.height = 180,
    this.emptyLabel = 'No chart data yet',
    this.valueFormatter,
  });

  final String title;
  final List<SimpleLineChartPoint> points;
  final Color color;
  final double height;
  final String emptyLabel;
  final String Function(double value)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: height,
            child: points.length < 2
                ? Center(
                    child: Text(
                      emptyLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedText(theme),
                      ),
                    ),
                  )
                : _SimpleLineChart(
                    points: points,
                    color: color,
                    valueFormatter: valueFormatter,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SimpleLineChart extends StatelessWidget {
  const _SimpleLineChart({
    required this.points,
    required this.color,
    this.valueFormatter,
  });

  final List<SimpleLineChartPoint> points;
  final Color color;
  final String Function(double value)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minY = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final span = (maxY - minY).abs();
    final paddedMinY = minY - (span == 0 ? (minY == 0 ? 1 : minY.abs() * 0.05) : span * 0.12);
    final paddedMaxY = maxY + (span == 0 ? (maxY == 0 ? 1 : maxY.abs() * 0.05) : span * 0.12);
    final bottomStyle = TextStyle(fontSize: 11, color: AppColors.tertiaryText(theme));
    final leftStyle = TextStyle(fontSize: 11, color: AppColors.tertiaryText(theme));

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: paddedMinY,
        maxY: paddedMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (paddedMaxY - paddedMinY) / 3,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.outline(theme).withValues(alpha: 0.35),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: (paddedMaxY - paddedMinY) / 2,
              getTitlesWidget: (value, _) => Text(
                valueFormatter?.call(value) ?? NumberFormat.compact().format(value),
                style: leftStyle,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: points.length > 6 ? ((points.length - 1) / 3).ceilToDouble() : 1,
              getTitlesWidget: (value, _) {
                final index = value.round();
                if (index < 0 || index >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(DateFormat.MMMd().format(points[index].date), style: bottomStyle),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.surface,
            tooltipRoundedRadius: 10,
            getTooltipItems: (spots) => spots.map((spot) {
              final point = points[spot.x.round()];
              return LineTooltipItem(
                '${DateFormat.yMMMd().format(point.date)}\n${valueFormatter?.call(point.value) ?? point.value.toStringAsFixed(2)}',
                TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.02),
                ],
              ),
            ),
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].value),
            ],
          ),
        ],
      ),
    );
  }
}
