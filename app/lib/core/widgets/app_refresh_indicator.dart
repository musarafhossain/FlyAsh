import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Pull to refresh with a clear shadow under the circle, used everywhere
/// instead of [RefreshIndicator].
///
/// The app's shadow colour is very light (cards), so the circle got lost on
/// the page. The circle's Material takes its shadow from
/// `colorScheme.shadow`; only the indicator gets a darker one: the page
/// under it keeps the normal theme.
class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final RefreshCallback onRefresh;
  final Widget child;

  /// How high the circle sits (Flutter's default is 2).
  static const double elevation = 6;

  /// The circle's shadow.
  static const Color shadow = Color(0x59000000);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(shadow: shadow),
      ),
      child: RefreshIndicator(
        onRefresh: onRefresh,
        elevation: elevation,
        color: t.primary,
        backgroundColor: t.surfaceElevated,
        // The page itself keeps the normal theme.
        child: Theme(data: theme, child: child),
      ),
    );
  }
}
