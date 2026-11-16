import 'dart:js_interop';

@JS('history')
external _History get _history;

extension type _History(JSObject _) implements JSObject {
  external JSAny? get state;
  external void go(int delta);
}

/// Flutter web stores `{serialCount: n, state: …}` in each history entry it
/// creates; n counts from 0 for the app's first entry.
int? browserHistorySerial() {
  final state = _history.state?.dartify();
  if (state is Map && state['serialCount'] is num) {
    return (state['serialCount'] as num).toInt();
  }
  return null;
}

void browserHistoryGo(int delta) => _history.go(delta);

bool get hasBrowserHistory => true;
