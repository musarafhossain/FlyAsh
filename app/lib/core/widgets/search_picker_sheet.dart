import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../network/api_response.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'paged_list.dart';
import 'state_views.dart';

/// Bottom sheet to pick one item from a paginated, searchable API list
/// (customer, product …). Pops with the chosen item, or null.
///
/// [header] goes above the list (e.g. a "+ New customer" button).
Future<T?> showSearchPicker<T>(
  BuildContext context, {
  required String title,
  required String searchHint,
  required Future<Paginated<T>> Function(int page, String search) fetch,
  required Widget Function(BuildContext context, T item) itemBuilder,
  Widget? header,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (context) => FractionallySizedBox(
    heightFactor: 0.85,
    child: _SearchPicker<T>(
      title: title,
      searchHint: searchHint,
      fetch: fetch,
      itemBuilder: itemBuilder,
      header: header,
    ),
  ),
);

class _SearchPicker<T> extends StatefulWidget {
  const _SearchPicker({
    required this.title,
    required this.searchHint,
    required this.fetch,
    required this.itemBuilder,
    this.header,
  });

  final String title;
  final String searchHint;
  final Future<Paginated<T>> Function(int page, String search) fetch;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget? header;

  @override
  State<_SearchPicker<T>> createState() => _SearchPickerState<T>();
}

class _SearchPickerState<T> extends State<_SearchPicker<T>> {
  final _list = PagedListController();
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _list.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: AppTypography.h3.copyWith(color: t.textPrimary),
              ),
              const SizedBox(height: Space.s3),
              TextField(
                controller: _search,
                autofocus: MediaQuery.sizeOf(context).width >= 600,
                textInputAction: TextInputAction.search,
                onChanged: (_) {
                  _debounce?.cancel();
                  _debounce = Timer(
                    const Duration(milliseconds: 300),
                    _list.refresh,
                  );
                },
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              if (widget.header != null) ...[
                const SizedBox(height: Space.s2),
                widget.header!,
              ],
            ],
          ),
        ),
        Expanded(
          child: PagedList<T>(
            controller: _list,
            fetch: (page) => widget.fetch(page, _search.text.trim()),
            empty: EmptyState(icon: Icons.search_off, title: l.noResults),
            builder: (context, items) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in items) ...[
                  widget.itemBuilder(context, item),
                  const SizedBox(height: Space.s2),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
