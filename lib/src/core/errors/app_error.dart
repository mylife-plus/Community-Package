/// What went wrong, in terms the UI can show a message for.
enum AppErrorType {
  /// No connection to the backend (no internet, DNS failure, refused).
  offline,

  /// The request started but failed: timeout, dropped connection or a
  /// response the app can't read.
  network,

  /// The backend rejected the request as malformed.
  badRequest,

  /// Admin token missing, wrong or expired.
  unauthorized,

  /// The user is blocked from posting on this item.
  blocked,

  /// The item no longer exists.
  notFound,

  /// Too many posts in a short time.
  rateLimited,

  /// The backend failed.
  server,

  /// Reading or saving on the phone failed (Keychain, preferences).
  storage,
}

/// The only error type that reaches controllers and the UI.
///
/// [message] comes from the backend and is meant for logs. The UI shows its
/// own translated text for [type].
class AppError implements Exception {
  const AppError(this.type, {this.code, this.message, this.details});

  /// Builds an error from a non-2xx response with the backend's
  /// `{ "error": { "code", "message", "details" } }` body.
  factory AppError.fromResponse(int statusCode, Object? body) {
    final error = body is Map<String, dynamic> ? body['error'] : null;
    final code = error is Map<String, dynamic> ? error['code'] as String? : null;
    final message = error is Map<String, dynamic> ? error['message'] as String? : null;
    final details = error is Map<String, dynamic> ? error['details'] : null;
    return AppError(
      _typeFor(code, statusCode),
      code: code,
      message: message,
      details: details is Map<String, dynamic> ? details : null,
    );
  }

  final AppErrorType type;

  /// The backend's error code, for example `blocked`.
  final String? code;
  final String? message;
  final Map<String, dynamic>? details;

  static AppErrorType _typeFor(String? code, int statusCode) {
    switch (code) {
      case 'bad_request':
        return AppErrorType.badRequest;
      case 'unauthorized':
        return AppErrorType.unauthorized;
      case 'blocked':
        return AppErrorType.blocked;
      case 'not_found':
        return AppErrorType.notFound;
      case 'rate_limited':
        return AppErrorType.rateLimited;
      case 'server_error':
        return AppErrorType.server;
    }
    if (statusCode == 400) return AppErrorType.badRequest;
    if (statusCode == 401 || statusCode == 403) return AppErrorType.unauthorized;
    if (statusCode == 404) return AppErrorType.notFound;
    if (statusCode == 429) return AppErrorType.rateLimited;
    return AppErrorType.server;
  }

  @override
  String toString() => 'AppError($type, code: $code, message: $message)';
}
