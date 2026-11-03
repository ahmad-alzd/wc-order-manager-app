import '../auth/auth_controller.dart';
import 'order_models.dart';

/// Wraps the `wcom/v1` order endpoints.
///
/// This takes the [AuthController] itself, not a concrete [ApiClient],
/// and reads `authController.apiClient` lazily on every call. That
/// lets this repository be provided once, above the app's Navigator,
/// before login even happens — a screen pushed later with
/// `Navigator.push` can still read it, which it couldn't if it (or
/// the controllers built from it) were provided *inside* the
/// authenticated route instead.
class OrdersRepository {
  OrdersRepository(this._auth);

  final AuthController _auth;

  Future<OrdersPage> fetchOrders({String? status, int page = 1, int perPage = 20}) async {
    final query = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
    };
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }

    final json = await _auth.apiClient.get('/orders', query: query);

    final orders = (json['orders'] as List<dynamic>? ?? [])
        .map((item) => OrderSummary.fromJson(item as Map<String, dynamic>))
        .toList();

    return OrdersPage(
      orders: orders,
      page: (json['page'] as num?)?.toInt() ?? page,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? orders.length,
    );
  }

  Future<OrderDetail> fetchOrder(int id) async {
    final json = await _auth.apiClient.get('/orders/$id');
    return OrderDetail.fromJson(json);
  }

  /// Returns the new status + its label, as confirmed by the server.
  Future<(String status, String statusLabel)> updateOrderStatus(int id, String status) async {
    final json = await _auth.apiClient.post('/orders/$id/status', body: {'status': status});
    return (
      (json['status'] as String?) ?? status,
      (json['status_label'] as String?) ?? status,
    );
  }

  Future<List<OrderStatusOption>> fetchStatuses() async {
    final json = await _auth.apiClient.get('/order-statuses');
    return (json['statuses'] as List<dynamic>? ?? [])
        .map((item) => OrderStatusOption.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
