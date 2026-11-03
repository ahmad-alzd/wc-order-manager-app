/// The three pieces of data needed to call the WC Order Manager REST
/// API for one store: its URL and the API Key/Secret pair issued by
/// the WordPress plugin (see wc-order-manager-plugin's
/// `WCOM_Credentials`).
class StoreCredentials {
  const StoreCredentials({
    required this.siteUrl,
    required this.apiKey,
    required this.apiSecret,
  });

  /// Normalized site URL, e.g. "https://example.com" — no trailing
  /// slash, scheme always present.
  final String siteUrl;

  final String apiKey;

  final String apiSecret;
}
