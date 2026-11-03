import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'store_credentials.dart';

/// Persists the signed-in store's credentials in the platform's
/// secure storage (Android Keystore-backed), so the app stays logged
/// in between launches without keeping the API secret in plain
/// SharedPreferences.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _keySiteUrl = 'wcom_site_url';
  static const _keyApiKey = 'wcom_api_key';
  static const _keyApiSecret = 'wcom_api_secret';
  static const _keySiteName = 'wcom_site_name';
  static const _keyCredentialLabel = 'wcom_credential_label';

  Future<void> saveSession({
    required StoreCredentials credentials,
    required String siteName,
    required String credentialLabel,
  }) async {
    await Future.wait([
      _storage.write(key: _keySiteUrl, value: credentials.siteUrl),
      _storage.write(key: _keyApiKey, value: credentials.apiKey),
      _storage.write(key: _keyApiSecret, value: credentials.apiSecret),
      _storage.write(key: _keySiteName, value: siteName),
      _storage.write(key: _keyCredentialLabel, value: credentialLabel),
    ]);
  }

  Future<StoreCredentials?> readCredentials() async {
    final siteUrl = await _storage.read(key: _keySiteUrl);
    final apiKey = await _storage.read(key: _keyApiKey);
    final apiSecret = await _storage.read(key: _keyApiSecret);

    if (siteUrl == null || apiKey == null || apiSecret == null) {
      return null;
    }

    return StoreCredentials(siteUrl: siteUrl, apiKey: apiKey, apiSecret: apiSecret);
  }

  Future<String?> readSiteName() => _storage.read(key: _keySiteName);

  Future<String?> readCredentialLabel() => _storage.read(key: _keyCredentialLabel);

  /// Wipes everything — used on logout, or if the server tells us the
  /// credential has been revoked.
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _keySiteUrl),
      _storage.delete(key: _keyApiKey),
      _storage.delete(key: _keyApiSecret),
      _storage.delete(key: _keySiteName),
      _storage.delete(key: _keyCredentialLabel),
    ]);
  }
}
