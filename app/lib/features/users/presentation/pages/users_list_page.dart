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
  Future<void> _open(String location) async {
    await context.push(location);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    ref.listen(dataChangedProvider, (_, _) => _list.refresh());
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
        onPressed: () => _open('/users/new'),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l.addUser),
      ),
      body: PagedList<AppUser>(
        controller: _list,
        fetch: (page) => repo.list(page: page, search: _search.text),
        header: TextField(
          controller: _search,
          onChanged: _onSearch,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l.searchNamePhone,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searching
                ? IconButton(
                    tooltip: l.clear,
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _search.clear();
                      _onSearch('');
                    },
                  )
                : null,
          ),
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
            ? _UsersTable(users: users, onOpen: (u) => _open('/users/${u.id}'))
            : ListGroup(
                children: [
                  for (final u in users)
                    EntityListTile(
                      leading: InitialsAvatar(u.name),
                      title: u.name,
                      subtitle: u.phone,
                      meta: l.lastLogin(lastLoginText(context, u)),
                      status: u.isActive ? l.active : l.inactive,
                      statusTone: u.isActive
                          ? StatusTone.success
                          : StatusTone.neutral,
                      onTap: () => _open('/users/${u.id}'),
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
        TableColumnDef(l.lastLoginColumn, flex: 2),
        TableColumnDef(l.status, flex: 2, alignEnd: true),
      ],
      rows: [
        for (final u in users)
          [
            Row(
              children: [
                InitialsAvatar(u.name, size: 32),
                const SizedBox(width: Space.s3),
                Expanded(child: CellText(u.name, strong: true)),
              ],
            ),
            CellText(u.phone),
            CellText(u.email ?? '—'),
            CellText(lastLoginText(context, u)),
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
