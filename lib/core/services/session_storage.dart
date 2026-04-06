import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wealthfolio_flutter/core/models/session.dart';

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

abstract class SessionStorage {
  Future<void> saveSession(AppSession session);
  Future<AppSession?> loadSession();
  Future<void> clearSession();
  Future<void> saveLastServerUrl(String url);
  Future<String?> loadLastServerUrl();
}

// ---------------------------------------------------------------------------
// Secure implementation (production)
// ---------------------------------------------------------------------------

class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _serverUrlKey = 'wealthfolio.server_url';
  static const _tokenKey = 'wealthfolio.token';
  static const _usernameKey = 'wealthfolio.username';

  final FlutterSecureStorage _secureStorage;

  @override
  Future<void> saveSession(AppSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, session.serverUrl);
    if (session.token != null) {
      await _secureStorage.write(key: _tokenKey, value: session.token);
    }
    if (session.username != null) {
      await _secureStorage.write(key: _usernameKey, value: session.username);
    }
  }

  @override
  Future<AppSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString(_serverUrlKey);
    if (serverUrl == null || serverUrl.isEmpty) {
      return null;
    }

    final token = await _secureStorage.read(key: _tokenKey);
    final username = await _secureStorage.read(key: _usernameKey);

    // A session without a token is considered unauthenticated.
    if (token == null || token.isEmpty) {
      return null;
    }

    return AppSession(
      serverUrl: serverUrl,
      token: token,
      username: username,
    );
  }

  @override
  Future<void> clearSession() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _usernameKey);
  }

  @override
  Future<void> saveLastServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url.trim());
  }

  @override
  Future<String?> loadLastServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey);
  }
}

// ---------------------------------------------------------------------------
// In-memory implementation (tests)
// ---------------------------------------------------------------------------

class MemorySessionStorage implements SessionStorage {
  AppSession? _session;
  String? _lastServerUrl;

  @override
  Future<void> saveSession(AppSession session) async {
    _session = session;
    _lastServerUrl = session.serverUrl;
  }

  @override
  Future<AppSession?> loadSession() async => _session;

  @override
  Future<void> clearSession() async {
    _session = null;
  }

  @override
  Future<void> saveLastServerUrl(String url) async {
    _lastServerUrl = url;
  }

  @override
  Future<String?> loadLastServerUrl() async => _lastServerUrl;
}
