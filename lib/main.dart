import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wealthfolio_flutter/core/api/wealthfolio_api.dart';
import 'package:wealthfolio_flutter/core/services/app_controller.dart';
import 'package:wealthfolio_flutter/core/services/session_storage.dart';
import 'package:wealthfolio_flutter/core/services/theme_controller.dart';
import 'package:wealthfolio_flutter/ui/app_root.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeController = ThemeController();
  final controller = AppController(
    storage: SecureSessionStorage(),
    api: NetworkWealthfolioApi(),
  );

  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment(
        'SENTRY_DSN',
        defaultValue:
            'https://abb48f20f49a4c0d85094952e5c856da@glitchtip.k2.k8s.best/5',
      );
      options.release = const String.fromEnvironment(
        'SENTRY_RELEASE',
        defaultValue: '1.0.0+1',
      );
      options.environment = const String.fromEnvironment(
        'SENTRY_ENVIRONMENT',
        defaultValue: 'development',
      );
      options.tracesSampleRate = 0.01;
      options.enableAutoSessionTracking = false;
      options.attachStacktrace = true;
    },
    appRunner: () => runApp(
      WealthfolioApp(controller: controller, themeController: themeController),
    ),
  );
}
