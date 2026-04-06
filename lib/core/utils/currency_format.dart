import 'package:intl/intl.dart';

String formatCurrency(
  double amount, {
  String currency = 'USD',
  bool compact = false,
}) {
  if (compact) {
    return NumberFormat.compactCurrency(
      symbol: _currencySymbol(currency),
    ).format(amount);
  }
  return NumberFormat.currency(
    symbol: _currencySymbol(currency),
    decimalDigits: 2,
  ).format(amount);
}

String formatPercent(double value, {int decimals = 2}) {
  return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(decimals)}%';
}

String formatNumber(double value, {int decimals = 2}) {
  return NumberFormat('#,##0.${'0' * decimals}').format(value);
}

String _currencySymbol(String currency) {
  return switch (currency.toUpperCase()) {
    'USD' => '\$',
    'EUR' => '€',
    'GBP' => '£',
    'CHF' => 'CHF ',
    'JPY' => '¥',
    'CAD' => 'CA\$',
    'AUD' => 'A\$',
    _ => '$currency ',
  };
}
