import 'package:flutter/material.dart';
import 'package:wealthfolio_flutter/core/services/app_controller.dart';
import 'package:wealthfolio_flutter/core/services/theme_controller.dart';
import 'package:wealthfolio_flutter/features/activities/activities_screen.dart';
import 'package:wealthfolio_flutter/features/auth/connect_screen.dart';
import 'package:wealthfolio_flutter/features/dashboard/dashboard_screen.dart';
import 'package:wealthfolio_flutter/features/holdings/holdings_screen.dart';
import 'package:wealthfolio_flutter/features/performance/performance_screen.dart';
import 'package:wealthfolio_flutter/features/settings/settings_screen.dart';
import 'package:wealthfolio_flutter/ui/app_colors.dart';

// ---------------------------------------------------------------------------
// Root application widget
// ---------------------------------------------------------------------------

class WealthfolioApp extends StatefulWidget {
  const WealthfolioApp({
    super.key,
    required this.controller,
    required this.themeController,
  });

  final AppController controller;
  final ThemeController themeController;

  @override
  State<WealthfolioApp> createState() => _WealthfolioAppState();
}

class _WealthfolioAppState extends State<WealthfolioApp> {
  @override
  void initState() {
    super.initState();
    widget.controller.initialize();
    widget.themeController.initialize();
    widget.controller.addListener(_onControllerChange);
    widget.themeController.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    widget.themeController.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onControllerChange() => setState(() {});
  void _onThemeChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wealthfolio',
      debugShowCheckedModeBanner: false,
      themeMode: widget.themeController.themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    return switch (widget.controller.stage) {
      AppStage.booting => const BootstrapScreen(),
      AppStage.unauthenticated => ConnectScreen(controller: widget.controller),
      AppStage.authenticated => HomeShell(
        controller: widget.controller,
        themeController: widget.themeController,
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// Theme builders
// ---------------------------------------------------------------------------

ThemeData _buildLightTheme() {
  const seedColor = AppColors.tx;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
    surface: AppColors.paper,
    onSurface: AppColors.tx,
    surfaceContainerHighest: AppColors.bg2,
    outline: AppColors.ui,
    outlineVariant: AppColors.ui2,
    error: AppColors.red,
    onError: Colors.white,
  ).copyWith(
    primary: AppColors.tx,
    onPrimary: AppColors.paper,
    secondary: AppColors.tx2,
    onSecondary: AppColors.paper,
    tertiary: AppColors.tx3,
  );

  return _applyCommonTheme(
    ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.paper,
      brightness: Brightness.light,
    ),
    navBarColor: AppColors.navBarLight,
  );
}

ThemeData _buildDarkTheme() {
  const seedColor = AppColors.darkTx;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
    surface: AppColors.darkBg2,
    onSurface: AppColors.darkTx,
    surfaceContainerHighest: AppColors.darkUi,
    outline: AppColors.darkUi2,
    outlineVariant: AppColors.darkUi3,
    error: AppColors.redLight,
    onError: Colors.black,
  ).copyWith(
    primary: AppColors.darkTx,
    onPrimary: AppColors.darkBg,
    secondary: AppColors.darkTx2,
    onSecondary: AppColors.darkBg,
    tertiary: AppColors.darkTx3,
  );

  return _applyCommonTheme(
    ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBg,
      brightness: Brightness.dark,
    ),
    navBarColor: AppColors.navBarDark,
  );
}

ThemeData _applyCommonTheme(ThemeData base, {required Color navBarColor}) {
  final cs = base.colorScheme;

  return base.copyWith(
    textTheme: _buildTextTheme(base.textTheme),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: navBarColor,
      indicatorColor: cs.primary.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: 'DMSans',
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? cs.primary : cs.secondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? cs.primary : cs.secondary,
          size: 22,
        );
      }),
      elevation: 0,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: navBarColor,
      foregroundColor: cs.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: cs.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.outline),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontFamily: 'DMSans',
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.onSurface,
        side: BorderSide(color: cs.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontFamily: 'DMSans',
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: DividerThemeData(color: cs.outline, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

TextTheme _buildTextTheme(TextTheme base) {
  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.w700,
    ),
    displayMedium: base.displayMedium?.copyWith(
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.w700,
    ),
    displaySmall: base.displaySmall?.copyWith(
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.w700,
    ),
    headlineLarge: base.headlineLarge?.copyWith(
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.w600,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontFamily: 'DMSans',
      fontWeight: FontWeight.w600,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontFamily: 'DMSans',
      fontWeight: FontWeight.w600,
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontFamily: 'DMSans',
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: base.bodyLarge?.copyWith(fontFamily: 'DMSans'),
    bodyMedium: base.bodyMedium?.copyWith(fontFamily: 'DMSans'),
    bodySmall: base.bodySmall?.copyWith(fontFamily: 'DMSans'),
    labelLarge: base.labelLarge?.copyWith(
      fontFamily: 'DMSans',
      fontWeight: FontWeight.w600,
    ),
    labelMedium: base.labelMedium?.copyWith(fontFamily: 'DMSans'),
    labelSmall: base.labelSmall?.copyWith(fontFamily: 'DMSans'),
  );
}

// ---------------------------------------------------------------------------
// Bootstrap / loading screen
// ---------------------------------------------------------------------------

class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monetization_on_outlined, size: 64, color: cs.primary),
            const SizedBox(height: 24),
            Text(
              'Wealthfolio',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.primary.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home shell with 5-tab bottom navigation
// ---------------------------------------------------------------------------

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.controller,
    required this.themeController,
  });

  final AppController controller;
  final ThemeController themeController;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  static const _tabs = <({IconData icon, IconData activeIcon, String label})>[
    (
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Dashboard',
    ),
    (
      icon: Icons.pie_chart_outline,
      activeIcon: Icons.pie_chart,
      label: 'Holdings',
    ),
    (
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'Activities',
    ),
    (
      icon: Icons.trending_up_outlined,
      activeIcon: Icons.trending_up,
      label: 'Performance',
    ),
    (icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _IndexedStackWithTickerMode(
        currentIndex: _selectedIndex,
        children: [
          DashboardScreen(controller: widget.controller),
          HoldingsScreen(controller: widget.controller),
          ActivitiesScreen(controller: widget.controller),
          PerformanceScreen(controller: widget.controller),
          SettingsScreen(
            controller: widget.controller,
            themeController: widget.themeController,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: _tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Indexed stack that pauses animation tickers on inactive tabs
// ---------------------------------------------------------------------------

class _IndexedStackWithTickerMode extends StatelessWidget {
  const _IndexedStackWithTickerMode({
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: currentIndex,
      children: children
          .asMap()
          .entries
          .map(
            (entry) => TickerMode(
              enabled: entry.key == currentIndex,
              child: entry.value,
            ),
          )
          .toList(),
    );
  }
}
