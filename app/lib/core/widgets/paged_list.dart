import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../network/api_response.dart';
import '../network/optimistic.dart';
import '../network/query_cache.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'state_views.dart';
import 'skeletons.dart';

/// Tells a [PagedList] to load again.
class PagedListController extends ChangeNotifier {
  bool _silent = false;

  /// Start again from page 1 with a skeleton (search or filter changed).
  void refresh() {
    _silent = false;
    notifyListeners();
  }

  /// Load the same pages again in the background (data changed): the rows
  /// stay on screen and are swapped when the new data arrives.
  void revalidate() {
    _silent = true;
    notifyListeners();
  }
}

/// A paginated API list (`page` + `limit`) with every state handled:
/// skeleton while loading, error + retry, empty state, pull to refresh, and
/// the next page loaded when the user scrolls near the end.
///
/// Pull to refresh and Retry skip the API cache. With [itemId], optimistic
/// patches ([optimisticProvider]) show at once: a row being deleted
/// disappears and a changed row shows its new state before the server
/// answers.
///
/// [builder] turns the loaded items into the content (cards on phones,
/// a [DataTableCard] on desktop …).
class PagedList<T> extends ConsumerStatefulWidget {
  const PagedList({
    super.key,
    required this.fetch,
    required this.builder,
    required this.empty,
    this.controller,
    this.header,
    this.maxWidth = 1200,
    this.showCount = false,
    this.onRefresh,
    this.itemId,
    this.skeleton,
    this.headerGap = Space.s3,
  });

  final Future<Paginated<T>> Function(int page) fetch;
  final Widget Function(BuildContext context, List<T> items) builder;

  /// Shown when page 1 has no items.
  final Widget empty;
  final PagedListController? controller;

  /// Above the items (e.g. a search field); scrolls with the list.
  final Widget? header;
  final double maxWidth;

  /// "Showing 20 of 54" under the items. Off for endless lists, which only
  /// show a spinner while the next page loads.
  final bool showCount;

  /// Also run on pull to refresh (e.g. a detail page reloads its header).
  final Future<void> Function()? onRefresh;

  /// Space between [header] and the rows.
  final double headerGap;

  /// Placeholder rows while page 1 loads on phones / tablets, shaped like
  /// this list's rows (default: generic rows). Desktop shows a table.
  final Widget? skeleton;

  /// The item's id, to apply optimistic patches.
  final String Function(T item)? itemId;

  @override
  ConsumerState<PagedList<T>> createState() => _PagedListState<T>();
}

class _PagedListState<T> extends ConsumerState<PagedList<T>> {
  final List<T> _items = [];
  int _page = 0;
  int _total = 0;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  /// Ignores answers that arrive after a newer refresh.
  int _generation = 0;

  /// When the rows on screen were requested; patches made after this are
  /// applied on top of them.
  DateTime _loadedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onController);
    _loadMore();
  }

  void _onController() => widget.controller!._silent && _items.isNotEmpty
      ? _revalidate()
      : _reload();

  @override
  void didUpdateWidget(PagedList<T> old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onController);
      widget.controller?.addListener(_onController);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onController);
    super.dispose();
  }

  Future<void> _reload() async {
    _generation++;
    setState(() {
      _items.clear();
      _page = 0;
      _hasMore = true;
      _loading = false;
      _error = null;
    });
    await _loadMore();
  }

  /// Loads pages 1…[_page] again and swaps them in, without a skeleton.
  /// On failure the old rows stay.
  Future<void> _revalidate() async {
    final generation = ++_generation;
    final started = DateTime.now();
    final pages = _page < 1 ? 1 : _page;
    final fresh = <T>[];
    Paginated<T>? last;
    try {
      for (var p = 1; p <= pages; p++) {
        last = await widget.fetch(p);
        fresh.addAll(last.items);
        if (!last.hasMore) break;
      }
    } catch (_) {
      return;
    }
    if (!mounted || generation != _generation) return;
    setState(() {
      _items
        ..clear()
        ..addAll(fresh);
      _page = last!.page;
      _total = last.total;
      _hasMore = last.hasMore;
      _loading = false;
      _error = null;
      _loadedAt = started;
    });
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    final generation = _generation;
    final started = DateTime.now();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.fetch(_page + 1);
      if (!mounted || generation != _generation) return;
      setState(() {
        if (_page == 0) _loadedAt = started;
        _items.addAll(result.items);
        _page = result.page;
        _total = result.total;
        _hasMore = result.hasMore;
      });
    } catch (e) {
      if (mounted && generation == _generation) setState(() => _error = e);
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.extentAfter < 400 && _error == null) _loadMore();
    return false;
  }

  /// Retry and pull to refresh go to the server, not the cache.
  Future<void> _retry() => QueryCache.fresh(_loadMore);

  @override
  Widget build(BuildContext context) {
    final gutter = Breakpoints.gutter(MediaQuery.sizeOf(context).width);
    final id = widget.itemId;
    final items = id == null
        ? _items
        : applyPatches(_items, ref.watch(optimisticProvider), id, _loadedAt);
    final firstLoad = items.isEmpty;

    final Widget content;
    if (firstLoad && _loading) {
      // Desktop lists are tables; phones and tablets show rows.
      content = MediaQuery.sizeOf(context).width >= Breakpoints.expanded
          ? const SkeletonTable()
          : widget.skeleton ?? const SkeletonList();
    } else if (firstLoad && _error != null) {
      content = ErrorState(
        message: failureText(context, _error!),
        onRetry: _retry,
      );
    } else if (firstLoad && !_loading) {
      content = widget.empty;
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.builder(context, items),
          if (widget.showCount || _loading || _error != null) ...[
            const SizedBox(height: Space.s3),
            _Footer(
              loading: _loading,
              error: _error,
              shown: items.length,
              total: _total,
              onRetry: _retry,
            ),
          ],
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => QueryCache.fresh(
        () => Future.wait([
          _reload(),
          if (widget.onRefresh != null) widget.onRefresh!(),
        ]),
      ),
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(gutter, gutter, gutter, gutter + 72),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.header != null) ...[
                      widget.header!,
                      SizedBox(height: widget.headerGap),
                    ],
                    content,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.loading,
    required this.error,
    required this.shown,
    required this.total,
    required this.onRetry,
  });

  final bool loading;
  final Object? error;
  final int shown;
  final int total;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (loading) {
      return const Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (error != null) {
      return Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(context.l10n.retry),
        ),
      );
    }
    return Text(
      context.l10n.showingCount('$shown', '$total'),
      textAlign: TextAlign.center,
      style: AppTypography.caption.copyWith(color: t.textTertiary),
    );
  }
}
