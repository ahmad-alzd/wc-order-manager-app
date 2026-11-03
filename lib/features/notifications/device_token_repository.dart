import '../auth/auth_controller.dart';

/// Registers this device's FCM token with the store, via
/// POST /wcom/v1/device-token (see wc-order-manager-plugin's
/// WCOM_REST_API::register_device_token()).
///
/// Like OrdersRepository, this holds the AuthController rather than a
/// concrete ApiClient so it can be provided above the Navigator,
/// before login happens — see OrdersRepository's doc comment for why
/// that matters.
class DeviceTokenRepository {
  DeviceTokenRepository(this._auth);

  final AuthController _auth;

  Future<void> register(String fcmToken) async {
    await _auth.apiClient.post('/device-token', body: {'fcm_token': fcmToken});
  }
}
