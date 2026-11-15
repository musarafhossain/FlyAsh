import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A change shown on screen before the server has answered.
class OptimisticPatch {
  const OptimisticPatch(this.value, this.removed, this.at);

  /// The item as it will look (null when [removed]).
  final Object? value;
  final bool removed;

  /// When it was made. A list or detail page loaded after this time already
  /// has the server's answer and ignores the patch.
  final DateTime at;
}

/// Optimistic updates for the whole app, by item id.
///
/// An action (deactivate, delete …) calls [replace] or [remove] before the
/// request and calls the returned undo if the request fails. Lists
/// ([PagedList] with `itemId`) and detail pages apply the patch at once;
/// when they load again after the change, the server's data takes over.
class OptimisticStore extends Notifier<Map<String, OptimisticPatch>> {
  @override
  Map<String, OptimisticPatch> build() => const {};

  /// Shows [value] in place of the item with [id]. Returns the undo.
  VoidCallback replace(String id, Object value) =>
      _put(id, OptimisticPatch(value, false, DateTime.now()));

  /// Hides the item with [id]. Returns the undo.
  VoidCallback remove(String id) =>
      _put(id, OptimisticPatch(null, true, DateTime.now()));

  VoidCallback _put(String id, OptimisticPatch patch) {
    state = {...state, id: patch};
    return () {
      if (identical(state[id], patch)) state = {...state}..remove(id);
    };
  }
}

final optimisticProvider =
    NotifierProvider<OptimisticStore, Map<String, OptimisticPatch>>(
      OptimisticStore.new,
    );

/// Applies the patches made after [loadedAt] to [items].
List<T> applyPatches<T>(
  List<T> items,
  Map<String, OptimisticPatch> patches,
  String Function(T) id,
  DateTime loadedAt,
) {
  if (patches.isEmpty) return items;
  final out = <T>[];
  for (final item in items) {
    final p = patches[id(item)];
    if (p == null || !p.at.isAfter(loadedAt)) {
      out.add(item);
    } else if (!p.removed && p.value is T) {
      out.add(p.value as T);
    }
  }
  return out;
}

extension OptimisticRef on WidgetRef {
  /// [item] with its optimistic patch (made after [loadedAt]) applied, for
  /// detail pages. Use in build. Returns the item unchanged when there is
  /// no newer patch.
  T? patched<T>(T? item, String Function(T) id, DateTime loadedAt) {
    if (item == null) return null;
    final p = watch(optimisticProvider.select((m) => m[id(item)]));
    if (p == null || !p.at.isAfter(loadedAt) || p.removed) return item;
    return p.value is T ? p.value as T : item;
  }

  /// True while item [id] is hidden by an optimistic delete (or after it
  /// was deleted). For rows inside a detail page. Use in build.
  bool isRemoved(String id) =>
      watch(optimisticProvider.select((m) => m[id]?.removed ?? false));

  /// Runs [request] with [preview] shown at once for item [id]; undoes it
  /// when [request] throws.
  Future<R> optimistic<R>(
    String id,
    Object preview,
    Future<R> Function() request,
  ) async {
    final undo = read(optimisticProvider.notifier).replace(id, preview);
    try {
      return await request();
    } catch (_) {
      undo();
      rethrow;
    }
  }

  /// Runs [request] with item [id] hidden at once; shows it again when
  /// [request] throws.
  Future<R> optimisticRemove<R>(String id, Future<R> Function() request) async {
    final undo = read(optimisticProvider.notifier).remove(id);
    try {
      return await request();
    } catch (_) {
      undo();
      // The row comes back: a stronger buzz says "that did not work".
      unawaited(HapticFeedback.heavyImpact());
      rethrow;
    }
  }
}
