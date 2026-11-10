import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Goes up by one after every successful create / update / delete sent to
/// the API (see `ApiClient`). Lists listen to it and load again, so a change
/// shows everywhere, also in lists that stay alive in other tabs.
class DataChanged extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final dataChangedProvider = NotifierProvider<DataChanged, int>(DataChanged.new);
