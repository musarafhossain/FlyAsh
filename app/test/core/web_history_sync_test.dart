import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/core/router/web_history_sync.dart';

/// A fake browser history: entries with serials 0…n, like Flutter web.
class FakeHistory {
  final pages = <String>[];
  int index = -1;
  final moves = <int>[];

  int? serial() => index < 0 ? null : index;

  /// The router adds an entry (push / go / pop all add one in Flutter).
  void push(String page) {
    pages
      ..removeRange(index + 1, pages.length)
      ..add(page);
    index = pages.length - 1;
  }

  void go(int delta) {
    moves.add(delta);
    index += delta;
  }

  String get current => pages[index];
}

void main() {
  late FakeHistory history;
  late WebHistorySync sync;

  setUp(() {
    history = FakeHistory();
    sync =
        WebHistorySync(
            serial: history.serial,
            go: history.go,
            webOverride: true,
          )
          ..currentLocation = (() => history.current)
          ..settle = () async {};
  });

  Future<void> open(String page) async {
    history.push(page);
    await sync.navigated();
  }

  test('save on a form opened from the list: back to the list entry, so '
      'browser back does not open the form again', () async {
    await open('/products');
    await open('/products/1/edit');
    // The form pops; the router adds a new entry for the list
    history.push('/products');
    await sync.pagePopped();
    expect(history.moves, [-2]);
    expect(history.current, '/products');
    expect(history.index, 0, reason: 'the edit entry is behind us now');
  });

  test('← on a detail page works the same way', () async {
    await open('/sales');
    await open('/sales/104');
    history.push('/sales');
    await sync.pagePopped();
    expect(history.moves, [-2]);
  });

  test('a form opened from a link (nothing behind it): left alone', () async {
    await open('/products/1/edit');
    history.push('/products');
    await sync.pagePopped();
    expect(history.moves, isEmpty, reason: 'going back would leave the app');
  });

  test('the entry two steps back shows another page: left alone', () async {
    await open('/products');
    await open('/sales/104'); // e.g. opened with go(), list below is /sales
    history.push('/sales');
    await sync.pagePopped();
    expect(history.moves, isEmpty);
  });

  test('pages closed by the browser back button: left alone', () async {
    await open('/products');
    await open('/products/1');
    history.go(-1); // the user pressed back
    final moving = sync.browserMoved();
    await sync.pagePopped();
    await moving;
    expect(history.moves, [-1], reason: 'only the user\'s own back');
  });

  test(
    'one close reported twice (two navigators): steps back only once',
    () async {
      await open('/products');
      await open('/products/1/edit');
      history.push('/products');
      await Future.wait([sync.pagePopped(), sync.pagePopped()]);
      expect(history.moves, [-2]);
    },
  );

  test('not on the web: does nothing', () async {
    sync.webOverride = false;
    await open('/products');
    await open('/products/1/edit');
    history.push('/products');
    await sync.pagePopped();
    expect(history.moves, isEmpty);
  });
}
