import 'package:flutter/material.dart';
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

  runApp(
    WealthfolioApp(controller: controller, themeController: themeController),
  );
}
