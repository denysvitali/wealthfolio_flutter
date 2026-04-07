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
  Future<void> clearCredentials();
  Future<void> saveCredentials({
    required String serverUrl,
    required String username,
    required String password,
  });
  Future<StoredCredentials?> loadCredentials();
  Future<void> saveLastServerUrl(String url);
  Future<String?> loadLastServerUrl();
}

class StoredCredentials {
  const StoredCredentials({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  final String serverUrl;
  final String username;
  final String password;
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
  static const _passwordKey = 'wealthfolio.password';

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

    return AppSession(serverUrl: serverUrl, token: token, username: username);
  }

  @override
  Future<void> clearSession() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  @override
  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _usernameKey);
    await _secureStorage.delete(key: _passwordKey);
  }

  @override
  Future<void> saveCredentials({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, serverUrl.trim());
    await _secureStorage.write(key: _usernameKey, value: username.trim());
    await _secureStorage.write(key: _passwordKey, value: password);
  }

  @override
  Future<StoredCredentials?> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString(_serverUrlKey);
    final username = await _secureStorage.read(key: _usernameKey);
    final password = await _secureStorage.read(key: _passwordKey);
    if (serverUrl == null ||
        serverUrl.isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }

    return StoredCredentials(
      serverUrl: serverUrl,
      username: username ?? '',
      password: password,
    );
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
  StoredCredentials? _credentials;

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
  Future<void> clearCredentials() async {
    _session = null;
    _credentials = null;
  }

  @override
  Future<void> saveCredentials({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    _credentials = StoredCredentials(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
    _lastServerUrl = serverUrl;
  }

  @override
  Future<StoredCredentials?> loadCredentials() async => _credentials;

  @override
  Future<void> saveLastServerUrl(String url) async {
    _lastServerUrl = url;
  }

  @override
  Future<String?> loadLastServerUrl() async => _lastServerUrl;
}
