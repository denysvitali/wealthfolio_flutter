import 'package:flutter/material.dart';

/// Flexoki-inspired color palette matching the Wealthfolio web frontend.
abstract final class AppColors {
  // ── Core surfaces ──────────────────────────────────────────────────────

  /// Warm paper white (Flexoki bg) - #fffcf0
  static const Color paper = Color(0xFFFFFCF0);

  /// Near-black (Flexoki tx) - #100f0f
  static const Color black = Color(0xFF100F0F);

  /// Light mode canvas / scaffold background
  static const Color canvas = paper;

  /// Primary text color
  static const Color ink = Color(0xFF0F0E0E);

  // ── Flexoki background scale ──────────────────────────────────────────

  /// bg - warm off-white
  static const Color bg = Color(0xFFFFFCF0);

  /// bg-2 - slightly darker warm white
  static const Color bg2 = Color(0xFFF2F0E5);

  /// ui - borders / chrome
  static const Color ui = Color(0xFFE6E4D9);

  /// ui-2 - secondary UI elements
  static const Color ui2 = Color(0xFFDAD8CE);

  /// ui-3 - ring/focus
  static const Color ui3 = Color(0xFFCECDC3);

  // ── Flexoki text scale ────────────────────────────────────────────────

  /// tx - primary text (near-black)
  static const Color tx = Color(0xFF100F0F);

  /// tx-2 - muted/secondary text
  static const Color tx2 = Color(0xFF6F6E69);

  /// tx-3 - tertiary text
  static const Color tx3 = Color(0xFFB7B5AC);

  // ── Accent colors (Flexoki named scales) ──────────────────────────────

  /// Red (destructive)
  static const Color red = Color(0xFFAF3029);
  static const Color redLight = Color(0xFFD14D41);

  /// Orange
  static const Color orange = Color(0xFFBC5215);
  static const Color orangeLight = Color(0xFFDA702C);

  /// Yellow (warning)
  static const Color yellow = Color(0xFFAD8301);
  static const Color yellowLight = Color(0xFFD0A215);

  /// Green (success)
  static const Color green = Color(0xFF66800B);
  static const Color greenLight = Color(0xFF879A39);

  /// Cyan
  static const Color cyan = Color(0xFF24837B);
  static const Color cyanLight = Color(0xFF3AA99F);

  /// Blue
  static const Color blue = Color(0xFF205EA6);
  static const Color blueLight = Color(0xFF4385BE);

  /// Purple
  static const Color purple = Color(0xFF5E409D);
  static const Color purpleLight = Color(0xFF8B7EC8);

  /// Magenta
  static const Color magenta = Color(0xFFA02F6F);
  static const Color magentaLight = Color(0xFFCE5D97);

  // ── Semantic ──────────────────────────────────────────────────────────

  static const Color success = green;
  static const Color successLight = greenLight;
  static const Color error = red;
  static const Color errorLight = redLight;
  static const Color warning = yellow;
  static const Color warningLight = yellowLight;
  static const Color info = blue;
  static const Color infoLight = blueLight;

  // ── Status colors for gains/losses ────────────────────────────────────

  static const Color gain = Color(0xFF66800B); // green
  static const Color loss = Color(0xFFAF3029); // red

  // ── Dark mode surfaces ────────────────────────────────────────────────

  static const Color darkBg = Color(0xFF100F0F);
  static const Color darkBg2 = Color(0xFF1C1B1A);
  static const Color darkUi = Color(0xFF282726);
  static const Color darkUi2 = Color(0xFF343331);
  static const Color darkUi3 = Color(0xFF403E3C);
  static const Color darkTx = Color(0xFFCECDC3);
  static const Color darkTx2 = Color(0xFF878580);
  static const Color darkTx3 = Color(0xFF575653);

  // ── Navigation bar ────────────────────────────────────────────────────

  static const Color navBarLight = Color(0xFFFFFCF0);
  static const Color navBarDark = Color(0xFF1C1B1A);

  // ── Theme-aware helpers ───────────────────────────────────────────────

  static Color surface(ThemeData theme) {
    return theme.brightness == Brightness.dark ? darkBg2 : paper;
  }

  static Color cardBackground(ThemeData theme) {
    return theme.brightness == Brightness.dark ? darkBg2 : bg2;
  }

  static Color outline(ThemeData theme) {
    return theme.brightness == Brightness.dark ? darkUi2 : ui;
  }

  static Color mutedText(ThemeData theme) {
    return theme.brightness == Brightness.dark ? darkTx2 : tx2;
  }

  static Color tertiaryText(ThemeData theme) {
    return theme.brightness == Brightness.dark ? darkTx3 : tx3;
  }

  static Color inputFill(ThemeData theme) {
    return theme.brightness == Brightness.dark ? darkUi : bg2;
  }

  static Color gainLossColor(double value) {
    if (value > 0) return gain;
    if (value < 0) return loss;
    return tx2;
  }

  static Color skeleton(ThemeData theme, {double alpha = 0.08}) {
    final base = theme.brightness == Brightness.dark ? darkTx : ink;
    return base.withValues(alpha: alpha);
  }
}
