import 'package:flutter/material.dart';

/// The app bars of the bottom-bar sections, as their root pages describe
/// them. The swipe pager draws them in its own fixed bar (see `ShellPager`)
/// because a section's navigator clips anything drawn outside its page.
class SectionBars extends ChangeNotifier {
  final Map<int, SectionAppBar> _bars = {};
  bool _scheduled = false;

  Map<int, SectionAppBar> get bars => Map.unmodifiable(_bars);

  /// Called while a root page builds: remembered now, the pager redraws
  /// after the frame (it must not rebuild during this build).
  void put(int index, SectionAppBar bar) {
    _bars[index] = bar;
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      notifyListeners();
    });
  }
}

/// Tells a bottom-bar section's root page that it sits in the swipe pager
/// (see `ShellPager`), and where.
class ShellPagerSlot extends InheritedWidget {
  const ShellPagerSlot({
    super.key,
    required this.index,
    required this.controller,
    required this.bars,
    required super.child,
  });

  /// The page number of this section in the pager.
  final int index;
  final PageController controller;
  final SectionBars bars;

  static ShellPagerSlot? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellPagerSlot>();

  @override
  bool updateShouldNotify(ShellPagerSlot old) =>
      index != old.index || controller != old.controller || bars != old.bars;
}

/// Page background for a bottom-bar section's root page: see-through inside
/// the swipe pager (the pager paints the background and the fixed bar).
Color? sectionBackground(BuildContext context) =>
    ShellPagerSlot.maybeOf(context) == null ? null : Colors.transparent;

/// App bar of a bottom-bar section (Home, Sales, Attendance, Expenses).
///
/// Outside the swipe pager it is a normal [AppBar]. Inside it the page only
/// keeps an empty space of the same height; the pager draws this bar in its
/// fixed bar, which stays in place while the pages slide (03-AppFlow §3.1):
/// each section's title and buttons fade in and out as the finger moves.
class SectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SectionAppBar({super.key, this.leading, this.title, this.actions});

  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final slot = ShellPagerSlot.maybeOf(context);
    if (slot == null) {
      return AppBar(leading: leading, title: title, actions: actions);
    }
    slot.bars.put(slot.index, this);
    // Keeps the page's layout: the body starts below the (pager's) bar.
    return SizedBox(
      height: kToolbarHeight + MediaQuery.paddingOf(context).top,
      width: double.infinity,
    );
  }
}

/// The bar the pager draws for one section: transparent (the pager paints
/// the background) and faded by how far its page is from the screen.
class PagerSectionBar extends StatelessWidget {
  const PagerSectionBar({
    super.key,
    required this.index,
    required this.bar,
    required this.controller,
  });

  final int index;
  final SectionAppBar bar;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final ready =
            controller.hasClients && controller.position.haveDimensions;
        // Not measured for a moment (e.g. the frame a detail page opens):
        // keep the last real position, not the first page (Home).
        final page = ready
            ? (_lastPage[controller] = controller.page!)
            : (_lastPage[controller] ?? controller.initialPage * 1.0);
        final distance = (page - index).abs();
        if (distance >= 1) return const SizedBox.shrink();
        final away = distance >= 0.5;
        return IgnorePointer(
          ignoring: away,
          child: ExcludeSemantics(
            excluding: away,
            child: Opacity(opacity: 1 - distance, child: child),
          ),
        );
      },
      child: AppBar(
        key: ValueKey('sectionBar-$index'),
        leading: bar.leading,
        title: bar.title,
        actions: bar.actions,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}

/// The last measured page of each pager (see [PagerSectionBar]).
final _lastPage = Expando<double>('lastPage');
