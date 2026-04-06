import 'package:flutter/painting.dart';

abstract final class AppSpacing {
  static const double xs = 2;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double xxxl = 24;
  static const double huge = 32;
}

abstract final class AppRadius {
  static final BorderRadius xs = BorderRadius.circular(4);
  static final BorderRadius sm = BorderRadius.circular(6);
  static final BorderRadius base = BorderRadius.circular(10);
  static final BorderRadius md = BorderRadius.circular(12);
  static final BorderRadius lg = BorderRadius.circular(16);
  static final BorderRadius pill = BorderRadius.circular(100);
}

abstract final class AppOpacity {
  static const double subtle = 0.06;
  static const double light = 0.08;
  static const double soft = 0.10;
  static const double medium = 0.12;
  static const double moderate = 0.14;
  static const double strong = 0.2;
  static const double bold = 0.3;
  static const double heavy = 0.4;
  static const double intense = 0.5;
  static const double dense = 0.6;
  static const double prominent = 0.7;
  static const double opaque = 0.8;
}

abstract final class AppIconSize {
  static const double xs = 14;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 28;
  static const double xxl = 32;
  static const double huge = 48;
}

abstract final class AppElevation {
  static const List<BoxShadow> none = <BoxShadow>[];

  static List<BoxShadow> subtle(Color shadowColor) => <BoxShadow>[
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.03),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> light(Color shadowColor, {double alpha = 0.08}) =>
      <BoxShadow>[
        BoxShadow(
          color: shadowColor.withValues(alpha: alpha),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
}

abstract final class AppCardDecoration {
  static BoxDecoration card({
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: AppRadius.base,
      border: Border.all(color: borderColor),
    );
  }

  static BoxDecoration elevated({
    required Color backgroundColor,
    required Color borderColor,
    required Color shadowColor,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: AppRadius.base,
      border: Border.all(color: borderColor),
      boxShadow: AppElevation.subtle(shadowColor),
    );
  }
}
