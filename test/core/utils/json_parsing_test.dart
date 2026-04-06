import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

void main() {
  group('parseMap', () {
    test('returns empty map for null', () {
      expect(parseMap(null), <String, dynamic>{});
    });

    test('passes through Map<String, dynamic>', () {
      final input = <String, dynamic>{'a': 1};
      expect(parseMap(input), input);
    });

    test('converts Map with non-string keys', () {
      final input = {1: 'one', 2: 'two'};
      expect(parseMap(input), {'1': 'one', '2': 'two'});
    });

    test('returns empty map for non-map types', () {
      expect(parseMap(42), <String, dynamic>{});
      expect(parseMap('string'), <String, dynamic>{});
      expect(parseMap([1, 2]), <String, dynamic>{});
    });
  });

  group('parseList', () {
    test('returns empty list for null', () {
      expect(parseList(null), <dynamic>[]);
    });

    test('passes through a List', () {
      expect(parseList([1, 2, 3]), [1, 2, 3]);
    });

    test('returns empty list for non-list types', () {
      expect(parseList(42), <dynamic>[]);
      expect(parseList('hello'), <dynamic>[]);
    });
  });

  group('parseString', () {
    test('returns fallback for null', () {
      expect(parseString(null), '');
      expect(parseString(null, fallback: 'N/A'), 'N/A');
    });

    test('trims whitespace', () {
      expect(parseString('  hello  '), 'hello');
    });

    test('returns fallback for empty/whitespace-only string', () {
      expect(parseString('   '), '');
      expect(parseString('   ', fallback: 'default'), 'default');
    });

    test('converts non-string to string', () {
      expect(parseString(42), '42');
      expect(parseString(3.14), '3.14');
    });
  });

  group('parseDouble', () {
    test('returns fallback for null', () {
      expect(parseDouble(null), 0.0);
      expect(parseDouble(null, fallback: 1.5), 1.5);
    });

    test('passes through double', () {
      expect(parseDouble(3.14), 3.14);
    });

    test('converts int to double', () {
      expect(parseDouble(42), 42.0);
    });

    test('parses valid string', () {
      expect(parseDouble('1.23'), 1.23);
    });

    test('returns fallback for invalid string', () {
      expect(parseDouble('abc'), 0.0);
      expect(parseDouble('abc', fallback: -1.0), -1.0);
    });

    test('returns fallback for unsupported type', () {
      expect(parseDouble(true), 0.0);
    });
  });

  group('parseInt', () {
    test('returns fallback for null', () {
      expect(parseInt(null), 0);
      expect(parseInt(null, fallback: 99), 99);
    });

    test('passes through int', () {
      expect(parseInt(7), 7);
    });

    test('truncates double to int', () {
      expect(parseInt(4.9), 4);
    });

    test('parses valid string', () {
      expect(parseInt('2024'), 2024);
    });

    test('returns fallback for invalid string', () {
      expect(parseInt('nope'), 0);
    });
  });

  group('parseBool', () {
    test('returns fallback for null', () {
      expect(parseBool(null), false);
      expect(parseBool(null, fallback: true), true);
    });

    test('passes through bool', () {
      expect(parseBool(true), true);
      expect(parseBool(false), false);
    });

    test('parses true string case-insensitively', () {
      expect(parseBool('true'), true);
      expect(parseBool('TRUE'), true);
      expect(parseBool('True'), true);
    });

    test('returns false for non-true strings', () {
      expect(parseBool('false'), false);
      expect(parseBool('yes'), false);
      expect(parseBool('1'), false);
    });

    test('returns fallback for unsupported type', () {
      expect(parseBool(1), false);
    });
  });
}
