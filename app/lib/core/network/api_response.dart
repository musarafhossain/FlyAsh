typedef Json = Map<String, Object?>;

/// The API envelope: `{ success, status_code, message, data }` (07-API §1.1).
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  final bool success;
  final int statusCode;
  final String message;
  final T data;

  static ApiResponse<T> fromJson<T>(
    Json json,
    T Function(Object? data) parse,
  ) => ApiResponse(
    success: json['success'] == true,
    statusCode: (json['status_code'] as num?)?.toInt() ?? 0,
    message: json['message'] as String? ?? '',
    data: parse(json['data']),
  );
}

/// A paginated list: `data = { items, page, limit, total, last_page, ...extra }`.
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.lastPage,
    this.extra = const {},
  });

  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int lastPage;

  /// Extra keys some lists send, e.g. `period_total`, `totals`, `month`.
  final Json extra;

  bool get hasMore => page < lastPage;
  bool get isEmpty => items.isEmpty;

  static const _keys = {'items', 'page', 'limit', 'total', 'last_page'};

  static Paginated<T> fromJson<T>(
    Object? data,
    T Function(Json item) parseItem,
  ) {
    final json = data as Json;
    return Paginated(
      items: [
        for (final item in json['items'] as List<Object?>)
          parseItem(item as Json),
      ],
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      lastPage: (json['last_page'] as num).toInt(),
      extra: {
        for (final e in json.entries)
          if (!_keys.contains(e.key)) e.key: e.value,
      },
    );
  }
}
