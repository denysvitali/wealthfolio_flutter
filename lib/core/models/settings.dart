import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

class Settings {
  const Settings({
    required this.id,
    required this.theme,
    required this.font,
    required this.baseCurrency,
  });

  final String id;

  /// e.g. 'light', 'dark', 'system'
  final String theme;

  /// e.g. 'inter', 'system'
  final String font;

  /// ISO 4217 currency code, e.g. 'USD', 'EUR'
  final String baseCurrency;

  factory Settings.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return Settings(
      id: parseString(map['id']),
      theme: parseString(map['theme'], fallback: 'system'),
      font: parseString(map['font'], fallback: 'inter'),
      baseCurrency: parseString(map['base_currency'], fallback: 'USD'),
    );
  }
}
