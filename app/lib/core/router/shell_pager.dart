import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_spacing.dart';
import 'nav_items.dart';
import 'section_app_bar.dart';
import '../theme/app_theme.dart' show kBarShadow;

/// Holds the section navigators of the app shell (03-AppFlow §3.1).
///
/// Phone and tablet: the four bottom-bar sections (Home · Sales ·
/// Attendance · Expenses) sit side by side in a [PageView], like WhatsApp:
/// swipe left / right to move to the next section, and the page follows the
/// finger. A tap on the bottom bar slides to that section too. Swiping only
/// works on a section's own first screen (its list), not on a detail page
/// or form, so horizontal gestures inside those stay theirs.
///
/// Desktop, and drawer sections (Customers, Reports …): one section at a
/// time, as before.
class ShellPager extends StatefulWidget {
  const ShellPager({super.key, required this.shell, required this.children});

  final StatefulNavigationShell shell;

  /// One navigator per section, in [kNavItems] order.
  final List<Widget> children;

  @override
  State<ShellPager> createState() => _ShellPagerState();
}

class _ShellPagerState extends State<ShellPager> {
  late final PageController _pages = PageController(
    initialPage: _pageOf(widget.shell.currentIndex) ?? 0,
  );

  /// The sections' app bars, drawn in the fixed bar (SectionAppBar).
  final _bars = SectionBars();

  /// True while the pager slides because of a bottom-bar tap (not a finger),
  /// so the pages it passes do not switch the section.
  bool _sliding = false;

  int? _pageOf(int branch) {
    final i = kPrimaryBranches.indexOf(branch);
    return i < 0 ? null : i;
  }

  @override
  void didUpdateWidget(ShellPager old) {
    super.didUpdateWidget(old);
    final page = _pageOf(widget.shell.currentIndex);
    if (page == null || !_pages.hasClients) return;
    final shown = _pages.page?.round();
    if (shown == page) return;
    // The section changed from outside (bottom bar, Home's cards …).
    if (old.shell.currentIndex == widget.shell.currentIndex) return;
    final animate =
        _pageOf(old.shell.currentIndex) != null &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (!animate) {
      _pages.jumpToPage(page);
      return;
    }
    _sliding = true;
    _pages
        .animateToPage(
          page,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() => _sliding = false);
  }

  @override
  void dispose() {
    _bars.dispose();
    _pages.dispose();
    super.dispose();
  }

  /// Where each section was last (path), to know if it is on its list.
  final _lastPath = <int, String>{};

  void _onPageChanged(int page) {
    if (_sliding) return;
    final branch = kPrimaryBranches[page];
    if (branch == widget.shell.currentIndex) return;
    // A swipe always lands on the section's list (03-AppFlow §3.1). It
    // normally is already (AppShell resets a section left on an inner page);
    // e.g. after the browser's back button it may not be.
    final onList =
        (_lastPath[branch] ?? kNavItems[branch].path) == kNavItems[branch].path;
    widget.shell.goBranch(branch, initialLocation: !onList);
  }

  /// The current section is on its own first screen (not a detail / form).
  bool _atSectionRoot() {
    final path = GoRouter.of(context).state.uri.path;
    return path == kNavItems[widget.shell.currentIndex].path;
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.shell.currentIndex;
    _lastPath[current] = GoRouter.of(context).state.uri.path;
    final desktop = MediaQuery.sizeOf(context).width >= Breakpoints.expanded;

    if (desktop) {
      return IndexedStack(
        index: current,
        children: [
          for (final (i, child) in widget.children.indexed)
            _branch(child, active: i == current),
        ],
      );
    }

    final page = _pageOf(current);
    final drawerBranches = [
      for (var i = 0; i < widget.children.length; i++)
        if (!kPrimaryBranches.contains(i)) i,
    ];
    final swipe = page != null && _atSectionRoot();

    return IndexedStack(
      index: page != null ? 0 : 1 + drawerBranches.indexOf(current),
      children: [
        _branch(
          active: page != null,
          keepTicking: true,
          _withFixedBar(
            context,
            showBars: swipe,
            PageView(
              key: const Key('shellPager'),
              controller: _pages,
              // Builds the sections next to the current one ahead of time, so
              // their content (not a skeleton) shows while the finger moves.
              allowImplicitScrolling: true,
              onPageChanged: _onPageChanged,
              physics: swipe
                  ? const PageScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              children: [
                for (final (i, b) in kPrimaryBranches.indexed)
                  _KeepAlive(
                    child: ShellPagerSlot(
                      index: i,
                      controller: _pages,
                      bars: _bars,
                      // Animations keep running in sections that are not
                      // shown: a card's press highlight that is fading
                      // when the user leaves would otherwise freeze and
                      // still show when they come back.
                      child: widget.children[b],
                    ),
                  ),
              ],
            ),
          ),
        ),
        for (final b in drawerBranches)
          _branch(widget.children[b], active: b == current),
      ],
    );
  }

  /// The page background and one fixed app bar (with its shadow) behind the
  /// pager: the sections' own bars are see-through and only their titles and
  /// buttons move (SectionAppBar).
  /// [showBars]: the section is on its first screen. On a detail page or
  /// form (pushed inside the section) that page's own app bar shows, so the
  /// pager's bar and titles step aside.
  Widget _withFixedBar(
    BuildContext context,
    Widget pager, {
    required bool showBars,
  }) {
    final theme = Theme.of(context);
    final barHeight = MediaQuery.paddingOf(context).top + kToolbarHeight;
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: theme.scaffoldBackgroundColor),
        ),
        // Hidden, not removed, off a section's first screen: removing them
        // would move the pager in the tree and reset it to the first page.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: barHeight,
          child: Offstage(
            offstage: !showBars,
            child: DecoratedBox(
              key: const Key('shellFixedBar'),
              decoration: BoxDecoration(
                color: theme.appBarTheme.backgroundColor,
                boxShadow: kBarShadow,
              ),
            ),
          ),
        ),
        Positioned.fill(child: pager),
        // The sections' titles and buttons, fading as the pages slide.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Offstage(
            offstage: !showBars,
            child: ListenableBuilder(
              listenable: _bars,
              builder: (context, _) => Stack(
                children: [
                  SizedBox(height: barHeight, width: double.infinity),
                  for (final MapEntry(key: i, value: bar) in _bars.bars.entries)
                    PagerSectionBar(index: i, bar: bar, controller: _pages),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// A section that is not shown: hidden from layout, paint and tickers.
  /// [keepTicking]: animations run on while hidden (the bottom-bar
  /// sections, see above).
  Widget _branch(
    Widget child, {
    required bool active,
    bool keepTicking = false,
  }) => Offstage(
    offstage: !active,
    child: TickerMode(enabled: active || keepTicking, child: child),
  );
}

/// Keeps a section alive while it is scrolled out of the pager, so its
/// list, scroll position and stack are still there when it comes back.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
