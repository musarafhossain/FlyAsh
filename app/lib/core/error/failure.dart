/// Everything that can go wrong when talking to the API, as one sealed type.
/// The UI shows [message]; validation failures also carry field errors.
sealed class Failure implements Exception {
  const Failure(this.message, {this.statusCode});

  /// Already translated by the server (Accept-Language), or a local fallback.
  final String message;
  final int? statusCode;

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// No connection, timeout, DNS … (no response from the server).
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

/// 401: missing/invalid token or deactivated user → back to login.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message) : super(statusCode: 401);
}

/// 422: field errors to show under each input.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {required this.fieldErrors, this.data})
    : super(statusCode: 422);

  /// field → message (first message per field)
  final Map<String, String> fieldErrors;

  /// Extra data, e.g. `existing_customer_id` for a duplicate phone.
  final Map<String, Object?>? data;

  String? operator [](String field) => fieldErrors[field];
}

/// Any other error response (400 business rule, 404, 409, 429, 500 …).
class ServerFailure extends Failure {
  const ServerFailure(
    super.message, {
    required int super.statusCode,
    this.data,
  });

  final Object? data;
}

/// Result of a repository call: either a value or a [Failure].
sealed class Result<T> {
  const Result();

  /// Runs [action] and turns a thrown [Failure] into [Err].
  static Future<Result<T>> guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Failure catch (f) {
      return Err(f);
    }
  }

  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) => switch (this) {
    Ok<T>(:final value) => ok(value),
    Err<T>(:final failure) => err(failure),
  };
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
