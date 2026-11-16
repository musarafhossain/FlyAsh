import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_bar_actions.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_shell.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_table_card.dart';
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/paged_list.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/network/data_changed.dart';
import '../../../auth/domain/app_user.dart';
import '../../data/users_repository_impl.dart';
import '../user_actions.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../core/router/section_events.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

/// Users list (03-AppFlow §10): everyone except the logged-in user.
/// Phone/tablet: cards. Desktop: a table.
class UsersListPage extends ConsumerStatefulWidget {
  const UsersListPage({super.key});

  @override
  ConsumerState<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends ConsumerState<UsersListPage> {
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

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _list.refresh);
    setState(() {}); // clear button
  }

  /// Opens a page and reloads the list when the user comes back.
  /// [extra]: the row's record, so the detail page shows at once (and the
  /// avatar can fly to it) while it loads the latest data.
  Future<void> _open(String location, {Object? extra}) async {
    await context.push(location, extra: extra);
  }

  @override
  Widget build(BuildContext context) {
    // Leaving the section clears the search (03-AppFlow §13).
    ref.onSectionLeft('/users', () {
      if (_search.text.isEmpty) return;
      setState(_search.clear);
      _debounce?.cancel();
      _list.refresh();
    });
    final l = context.l10n;
    ref.onDataChanged({DataTag.users}, _list.revalidate);
    final repo = ref.watch(usersRepositoryProvider);
    final desktop = MediaQuery.sizeOf(context).width >= Breakpoints.expanded;
    final searching = _search.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: ShellMenuButton.maybe(context),
        title: Text(l.navUsers),
        actions: const [AppBarActions()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        // Own tag: several sections are alive at once (swipe pager).
        heroTag: 'fab-users',
        onPressed: () => _open('/users/new'),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l.addUser),
      ),
      body: PagedList<AppUser>(
        skeleton: const SkeletonRows(trailing: SkeletonTrailing.none),
        itemId: (item) => item.id,
        showCount: false,
        controller: _list,
        fetch: (page) => repo.list(page: page, search: _search.text),
        header: SearchField(
          controller: _search,
          hintText: l.searchNamePhone,
          onChanged: _onSearch,
        ),
        empty: searching
            ? EmptyState(icon: Icons.search_off, title: l.noResults)
            : EmptyState(
                icon: Icons.group_outlined,
                title: l.usersEmptyTitle,
                message: l.usersEmptyMessage,
                actionLabel: l.addUser,
                onAction: () => _open('/users/new'),
              ),
        builder: (context, users) => desktop
            ? _UsersTable(
                users: users,
                onOpen: (u) => _open('/users/${u.id}', extra: u),
              )
            : ListGroup(
                flat: true,
                children: [
                  for (final u in users)
                    UserTile(
                      user: u,
                      onTap: () => _open('/users/${u.id}', extra: u),
                      onLongPress: (row) => showUserMenu(
                        row,
                        ref,
                        u,
                        onOpen: () => _open('/users/${u.id}', extra: u),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// "Never" or the local date and time of the last login.
String lastLoginText(BuildContext context, AppUser user) =>
    user.lastLoginAt == null
    ? context.l10n.never
    : Fmt.dateTime(user.lastLoginAt);

class _UsersTable extends StatelessWidget {
  const _UsersTable({required this.users, required this.onOpen});

  final List<AppUser> users;
  final ValueChanged<AppUser> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DataTableCard(
      columns: [
        TableColumnDef(l.nameField, flex: 3),
        TableColumnDef(l.phoneField, flex: 2),
        TableColumnDef(l.emailField, flex: 3),
        TableColumnDef(l.status, flex: 2, alignEnd: true),
      ],
      rows: [
        for (final u in users)
          [
            Row(
              children: [
                InitialsAvatar(u.name, size: 32, heroTag: 'user-${u.id}'),
                const SizedBox(width: Space.s3),
                Expanded(child: CellText(u.name, strong: true)),
              ],
            ),
            CellText(u.phone),
            CellText(u.email ?? '—'),
            StatusPill(
              u.isActive ? l.active : l.inactive,
              tone: u.isActive ? StatusTone.success : StatusTone.neutral,
            ),
          ],
      ],
      onTapRow: (i) => onOpen(users[i]),
    );
  }
}

/// Phone/tablet row, the same as a customer row: initials · name · phone
/// (or "-") | "Inactive" when deactivated. No last login in the list.
class UserTile extends StatelessWidget {
  const UserTile({super.key, required this.user, this.onTap, this.onLongPress});

  final AppUser user;
  final VoidCallback? onTap;

  /// Opens the action menu next to this row (gets the row's context).
  final ValueChanged<BuildContext>? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final u = user;
    return Opacity(
      opacity: u.isActive ? 1 : 0.6,
      child: ListRowSurface(
        onTap: onTap,
        onLongPress: onLongPress == null ? null : () => onLongPress!(context),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.s4,
          vertical: Space.s3,
        ),
        child: Row(
          children: [
            InitialsAvatar(u.name, heroTag: 'user-${u.id}'),
            const SizedBox(width: Space.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title.copyWith(color: t.textPrimary),
                  ),
                  Text(
                    u.phone.isEmpty ? '-' : u.phone,
                    style: AppTypography.caption.copyWith(
                      color: t.textSecondary,
                      fontFeatures: AppTypography.tabular,
                    ),
                  ),
                ],
              ),
            ),
            if (!u.isActive) ...[
              const SizedBox(width: Space.s2),
              StatusPill(l.inactive),
            ],
          ],
        ),
      ),
    );
  }
}
