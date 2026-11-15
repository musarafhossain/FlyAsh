import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'query_cache.dart' show DataTag;

/// A version number per data tag ([DataTag]). After every successful
/// create / update / delete, `ApiClient` bumps the tags the change affects
/// (e.g. a new sale → sales, customers, dashboard, reports), so only the
/// screens showing that data reload, in the background.
class DataVersions {
  const DataVersions([this._v = const {}]);

  final Map<String, int> _v;

  int of(String tag) => _v[tag] ?? 0;

  /// One number that changes when any of [tags] changes.
  int sum(Iterable<String> tags) => tags.fold(0, (a, t) => a + of(t));

  DataVersions bump(Set<String> tags) =>
      DataVersions({..._v, for (final t in tags) t: of(t) + 1});
}

class DataChanged extends Notifier<DataVersions> {
  @override
  DataVersions build() => const DataVersions();

  void bump(Set<String> tags) {
    if (tags.isNotEmpty) state = state.bump(tags);
  }
}

final dataChangedProvider = NotifierProvider<DataChanged, DataVersions>(
  DataChanged.new,
);

extension DataChangedRef on WidgetRef {
  /// Calls [onChange] when data with one of [tags] changes. Use in build.
  void onDataChanged(Set<String> tags, VoidCallback onChange) => listen(
    dataChangedProvider.select((v) => v.sum(tags)),
    (_, _) => onChange(),
  );
}
