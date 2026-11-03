import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import 'order_models.dart';
import 'orders_repository.dart';

/// Drives the order detail screen: loading one order plus the list of
/// statuses it can be moved to, and applying a status change.
class OrderDetailController extends ChangeNotifier {
  OrderDetailController(this._repository, this.orderId);

  final OrdersRepository _repository;
  final int orderId;

  OrderDetail? order;
  List<OrderStatusOption> statusOptions = [];

  bool isLoading = false;
  bool isUpdatingStatus = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait<Object>([
        _repository.fetchOrder(orderId),
        _repository.fetchStatuses(),
      ]);
      order = results[0] as OrderDetail;
      statusOptions = results[1] as List<OrderStatusOption>;
    } catch (e) {
      error = e is ApiException ? e.message : 'خطا در دریافت اطلاعات سفارش.';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> changeStatus(String newStatus) async {
    final current = order;
    if (current == null || current.status == newStatus) return false;

    isUpdatingStatus = true;
    notifyListeners();

    try {
      final (status, statusLabel) = await _repository.updateOrderStatus(orderId, newStatus);
      order = current.copyWithStatus(status: status, statusLabel: statusLabel);
      isUpdatingStatus = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e is ApiException ? e.message : 'تغییر وضعیت سفارش ناموفق بود.';
      isUpdatingStatus = false;
      notifyListeners();
      return false;
    }
  }
}
