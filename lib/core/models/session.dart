import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

class AppSession {
  const AppSession({
    required this.serverUrl,
    this.token,
    this.username,
  });

  final String serverUrl;
  final String? token;
  final String? username;

  factory AppSession.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return AppSession(
      serverUrl: parseString(map['serverUrl']),
      token: map['token'] as String?,
      username: map['username'] as String?,
    );
  }

  bool get isAuthenticated => token != null && token!.isNotEmpty;
}
