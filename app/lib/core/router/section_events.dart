import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The section the user just left (its path, e.g. "/sales") and a counter,
/// so the same section left twice is two events.
class SectionLeft extends Notifier<(String, int)> {
  @override
  (String, int) build() => ('', 0);

  void left(String path) => state = (path, state.$2 + 1);
}

final sectionLeftProvider = NotifierProvider<SectionLeft, (String, int)>(
  SectionLeft.new,
);

extension SectionLeftRef on WidgetRef {
  /// Calls [onLeft] when the user leaves the section at [path] (another
  /// section is opened). Lists use it to clear their search, so a section
  /// opened again shows everything (03-AppFlow §13). Use in build.
  void onSectionLeft(String path, VoidCallback onLeft) =>
      listen(sectionLeftProvider, (_, next) {
        if (next.$1 == path) onLeft();
      });
}
