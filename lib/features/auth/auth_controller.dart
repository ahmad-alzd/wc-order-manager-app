import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../core/secure_storage_service.dart';
import '../../core/store_credentials.dart';

enum AuthStatus {
  /// Still checking secure storage for a saved session.
  unknown,
  authenticating,
  authenticated,
  unauthenticated,
}

/// Owns the app's single sign-in session: the store currently
/// connected to, and the [ApiClient] every other feature uses to talk
/// to it.
class AuthController extends ChangeNotifier {
  AuthController({SecureStorageService? storageService})
      : _storage = storageService ?? SecureStorageService();

  final SecureStorageService _storage;

  AuthStatus status = AuthStatus.unknown;
  String? errorMessage;
  String? siteName;

  ApiClient? _apiClient;

  /// The authenticated API client. Only valid when [status] is
  /// [AuthStatus.authenticated] — every screen that reads this is
  /// reachable only from behind that gate (see AuthGate in app.dart).
  ApiClient get apiClient {
    final client = _apiClient;
    if (client == null) {
      throw StateError('apiClient accessed before a successful login.');
    }
    return client;
  }

  /// Called once at app startup: restores a previously saved session
  /// without making a network call, so the app opens straight to the
  /// orders list even if the device is briefly offline.
  Future<void> tryAutoLogin() async {
    final credentials = await _storage.readCredentials();

    if (credentials == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _apiClient = ApiClient(credentials: credentials);
    siteName = await _storage.readSiteName();
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Verifies a Key/Secret pair against [siteUrl] and, on success,
  /// persists the session for next time.
  Future<bool> login({
    required String siteUrl,
    required String apiKey,
    required String apiSecret,
  }) async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();

    final credentials = StoreCredentials(
      siteUrl: _normalizeSiteUrl(siteUrl),
      apiKey: apiKey.trim(),
      apiSecret: apiSecret.trim(),
    );
    final client = ApiClient(credentials: credentials);

    try {
      final response = await client.get('/verify');

      final resolvedSiteName = (response['site_name'] as String?) ?? credentials.siteUrl;
      final credentialLabel = (response['credential_label'] as String?) ?? '';

      await _storage.saveSession(
        credentials: credentials,
        siteName: resolvedSiteName,
        credentialLabel: credentialLabel,
      );

      _apiClient = client;
      siteName = resolvedSiteName;
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'ارتباط با فروشگاه برقرار نشد. آدرس سایت و اتصال اینترنت را بررسی کنید.';
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    _apiClient = null;
    siteName = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _normalizeSiteUrl(String input) {
    var url = input.trim();

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    return url;
  }
}
