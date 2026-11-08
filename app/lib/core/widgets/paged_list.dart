import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../network/api_response.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'state_views.dart';

/// Tells a [PagedList] to load again from page 1 (after a search change,
/// an edit, a new item …).
class PagedListController extends ChangeNotifier {
  void refresh() => notifyListeners();
}

/// A paginated API list (`page` + `limit`) with every state handled:
/// skeleton while loading, error + retry, empty state, pull to refresh, and
/// the next page loaded when the user scrolls near the end.
///
/// [builder] turns the loaded items into the content (cards on phones,
/// a [DataTableCard] on desktop …).
class PagedList<T> extends StatefulWidget {
  const PagedList({
    super.key,
    required this.fetch,
    required this.builder,
    required this.empty,
    this.controller,
    this.header,
    this.maxWidth = 1200,
  });

  final Future<Paginated<T>> Function(int page) fetch;
  final Widget Function(BuildContext context, List<T> items) builder;

  /// Shown when page 1 has no items.
  final Widget empty;
  final PagedListController? controller;

  /// Above the items (e.g. a search field); scrolls with the list.
  final Widget? header;
  final double maxWidth;

  @override
  State<PagedList<T>> createState() => _PagedListState<T>();
}

class _PagedListState<T> extends State<PagedList<T>> {
  final List<T> _items = [];
  int _page = 0;
  int _total = 0;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  /// Ignores answers that arrive after a newer refresh.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_reload);
    _loadMore();
  }

  @override
  void didUpdateWidget(PagedList<T> old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_reload);
      widget.controller?.addListener(_reload);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_reload);
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

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    final generation = _generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.fetch(_page + 1);
      if (!mounted || generation != _generation) return;
      setState(() {
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

  @override
  Widget build(BuildContext context) {
    final gutter = Breakpoints.gutter(MediaQuery.sizeOf(context).width);
    final firstLoad = _items.isEmpty;

    final Widget content;
    if (firstLoad && _loading) {
      content = const SkeletonList();
    } else if (firstLoad && _error != null) {
      content = ErrorState(
        message: failureText(context, _error!),
        onRetry: _loadMore,
      );
    } else if (firstLoad) {
      content = widget.empty;
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.builder(context, _items),
          const SizedBox(height: Space.s3),
          _Footer(
            loading: _loading,
            error: _error,
            shown: _items.length,
            total: _total,
            onRetry: _loadMore,
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _reload,
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
                      const SizedBox(height: Space.s3),
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
