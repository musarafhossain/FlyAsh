import 'package:flutter/widgets.dart';

/// 4-point spacing scale (04-UI-UX §7.1).
abstract final class Space {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
}

/// Corner radius scale (04-UI-UX §7.2).
abstract final class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));
}

/// Layout breakpoints (04-UI-UX §11).
abstract final class Breakpoints {
  /// Below this: phone (bottom navigation).
  static const double medium = 600;

  /// From this: desktop (persistent sidebar).
  static const double expanded = 1024;

  /// Screen side padding for a given width.
  static double gutter(double width) => width >= expanded
      ? Space.s8
      : width >= medium
      ? Space.s6
      : Space.s4;
}

/// Minimum touch target (04-UI-UX §13).
const double kMinTouchTarget = 48;
