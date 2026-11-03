import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'store_credentials.dart';

/// Talks to the WC Order Manager plugin's REST API
/// (`/wp-json/wcom/v1/...`), signing every request with HMAC-SHA256
/// exactly the way the plugin's `WCOM_Auth` class verifies it:
///
///   string_to_sign = METHOD \n PATH \n TIMESTAMP \n NONCE \n sha256_hex(body)
///   signature      = hex( HMAC-SHA256(string_to_sign, api_secret) )
///
/// `PATH` is the route inside the `wcom/v1` namespace only (e.g.
/// "/wcom/v1/orders/123"), never the full `/wp-json` URL and never
/// including the query string — see the plugin's
/// `WCOM_REST_API::check_auth()` for why.
class ApiClient {
  ApiClient({required this.credentials, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final StoreCredentials credentials;
  final http.Client _http;

  static const String _apiNamespace = '/wcom/v1';

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) {
    return _send('GET', path, query: query);
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) {
    return _send('POST', path, body: body);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final signedPath = _apiNamespace + path;
    final bodyString = body == null ? '' : jsonEncode(body);

    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final nonce = _generateNonce();
    final signature = _sign(
      method: method,
      path: signedPath,
      timestamp: timestamp,
      nonce: nonce,
      body: bodyString,
    );

    var uri = Uri.parse('${credentials.siteUrl}/wp-json$signedPath');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-WCOM-Api-Key': credentials.apiKey,
      'X-WCOM-Timestamp': timestamp,
      'X-WCOM-Nonce': nonce,
      'X-WCOM-Signature': signature,
    };

    late http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await _http.post(uri, headers: headers, body: bodyString);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
    } on http.ClientException catch (e) {
      throw ApiException(message: 'Network error: ${e.message}');
    }

    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic>? json;

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          json = decoded;
        }
      } catch (_) {
        // Non-JSON body (e.g. an HTML error page from the host) —
        // fall through to the generic status-code message below.
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json ?? <String, dynamic>{};
    }

    throw ApiException(
      message: (json?['message'] as String?) ??
          'Request failed with status ${response.statusCode}.',
      code: json?['code'] as String?,
      statusCode: response.statusCode,
    );
  }

  String _sign({
    required String method,
    required String path,
    required String timestamp,
    required String nonce,
    required String body,
  }) {
    final bodyHash = sha256.convert(utf8.encode(body)).toString();

    final stringToSign = <String>[
      method.toUpperCase(),
      path,
      timestamp,
      nonce,
      bodyHash,
    ].join('\n');

    final hmac = Hmac(sha256, utf8.encode(credentials.apiSecret));
    return hmac.convert(utf8.encode(stringToSign)).toString();
  }

  /// A random per-request nonce. 16 random bytes, hex-encoded — large
  /// enough that two requests from the same device never collide
  /// within the server's replay window.
  String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
