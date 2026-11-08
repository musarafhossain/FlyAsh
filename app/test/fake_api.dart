import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:flyash/core/network/api_response.dart';

typedef Reply = (int status, Object? body, Map<String, String> headers);

/// Answers requests without a network; records the last request.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final Reply Function(RequestOptions options) handler;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    last = options;
    final (status, json, headers) = handler(options);
    return ResponseBody.fromString(
      jsonEncode(json),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        for (final e in headers.entries) e.key: [e.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Json envelope(int status, String message, Object? data) => {
  'success': status < 400,
  'status_code': status,
  'message': message,
  'data': data,
};
