/// Not on the web: there is no browser history.
int? browserHistorySerial() => null;

void browserHistoryGo(int delta) {}

/// Not on the web.
bool get hasBrowserHistory => false;
