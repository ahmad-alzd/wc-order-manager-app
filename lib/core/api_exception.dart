/// Thrown by [ApiClient] whenever the WordPress REST API returns an
/// error response. Mirrors the shape of a WP_Error JSON body:
/// `{ "code": "...", "message": "...", "data": { "status": 401 } }`.
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.code,
    this.statusCode,
  });

  /// Human-readable message, suitable for showing directly to the user
  /// (the plugin's error messages are already written for that).
  final String message;

  /// Machine-readable error code, e.g. "wcom_auth_bad_signature".
  final String? code;

  /// HTTP status code, when known.
  final int? statusCode;

  /// Whether this looks like an authentication/authorization failure
  /// (bad or revoked credentials) rather than a transient or
  /// validation error.
  bool get isAuthError =>
      statusCode == 401 || statusCode == 403 || (code?.startsWith('wcom_auth_') ?? false);

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
