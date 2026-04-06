import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/session.dart';

void main() {
  group('AppSession', () {
    test('isAuthenticated is true when token is non-empty', () {
      const session = AppSession(
        serverUrl: 'http://localhost:7472',
        token: 'abc123',
      );
      expect(session.isAuthenticated, true);
    });

    test('isAuthenticated is false when token is null', () {
      const session = AppSession(serverUrl: 'http://localhost:7472');
      expect(session.isAuthenticated, false);
    });

    test('isAuthenticated is false when token is empty string', () {
      const session = AppSession(
        serverUrl: 'http://localhost:7472',
        token: '',
      );
      expect(session.isAuthenticated, false);
    });

    test('fromJson parses a valid map', () {
      final json = <String, dynamic>{
        'serverUrl': 'https://wealthfolio.example.com',
        'token': 'tok-xyz',
        'username': 'alice',
      };

      final session = AppSession.fromJson(json);
      expect(session.serverUrl, 'https://wealthfolio.example.com');
      expect(session.token, 'tok-xyz');
      expect(session.username, 'alice');
      expect(session.isAuthenticated, true);
    });

    test('fromJson handles null input', () {
      final session = AppSession.fromJson(null);
      expect(session.serverUrl, '');
      expect(session.token, null);
      expect(session.isAuthenticated, false);
    });
  });
}
