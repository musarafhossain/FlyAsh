import 'dart:js_interop';

@JS('location')
external _Location get _location;

extension type _Location(JSObject _) implements JSObject {
  external void reload();
}

/// Loads the new web build (Nginx serves index.html, flutter_bootstrap.js
/// and main.dart.js with `no-cache`, so the browser asks for fresh files).
void reloadPage() => _location.reload();
