import 'package:flutter/material.dart';

/// How pages change everywhere in the app (2026-11-16): the new page fades
/// in over the old one, which stays fully drawn underneath (it is never
/// faded or moved, so no plain background flashes through). Every app bar
/// has the same background, so the bar seems to stay in place while its
/// title and buttons change: the existing app bar is "updated" rather than
/// a new one sliding in. Going back is the same fade, reversed.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  /// The part of the route's 300 ms the fade uses (≈ 210 ms).
  static const curve = Interval(0, 0.7, curve: Curves.easeOut);

  /// For things that change with a page (the bottom sections' titles).
  static const duration = Duration(milliseconds: 210);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(
    opacity: CurvedAnimation(
      parent: animation,
      curve: curve,
      reverseCurve: curve.flipped,
    ),
    child: child,
  );
}

/// The same transition on every platform.
final appPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    for (final p in TargetPlatform.values) p: const AppPageTransitionsBuilder(),
  },
);
