import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/settings.dart';

void main() {
  group('Settings.fromJson', () {
    test('parses a valid settings map', () {
      final json = <String, dynamic>{
        'instanceId': 'settings-1',
        'theme': 'dark',
        'font': 'inter',
        'baseCurrency': 'EUR',
      };

      final settings = Settings.fromJson(json);
      expect(settings.id, 'settings-1');
      expect(settings.theme, 'dark');
      expect(settings.font, 'inter');
      expect(settings.baseCurrency, 'EUR');
    });

    test('uses sensible defaults when fields are absent', () {
      final settings = Settings.fromJson(<String, dynamic>{'instanceId': 'x'});
      expect(settings.theme, 'system');
      expect(settings.font, 'inter');
      expect(settings.baseCurrency, 'USD');
    });

    test('handles null input', () {
      final settings = Settings.fromJson(null);
      expect(settings.id, '');
      expect(settings.baseCurrency, 'USD');
    });
  });
}
