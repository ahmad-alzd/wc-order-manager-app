import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import 'order_models.dart';
import 'orders_repository.dart';

/// Drives the orders list screen: the current page of orders, the
/// active status filter, pagination, and pull-to-refresh.
class OrdersController extends ChangeNotifier {
  OrdersController(this._repository);

  final OrdersRepository _repository;

  static const int _perPage = 20;

  List<OrderSummary> orders = [];
  List<OrderStatusOption> statusOptions = [];

  bool isLoading = false;
  bool isLoadingMore = false;
  String? error;

  String? statusFilter;
  int _page = 1;
  int _totalPages = 1;

  bool get hasMore => _page < _totalPages;

  Future<void> loadStatusOptions() async {
    try {
      statusOptions = await _repository.fetchStatuses();
      notifyListeners();
    } catch (_) {
      // Non-critical: the filter row just stays empty. The list
      // itself doesn't depend on this.
    }
  }

  Future<void> refresh() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _repository.fetchOrders(status: statusFilter, page: 1, perPage: _perPage);
      orders = result.orders;
      _page = result.page;
      _totalPages = result.totalPages;
    } catch (e) {
      error = e is ApiException ? e.message : 'خطا در دریافت سفارشات. اتصال اینترنت را بررسی کنید.';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (isLoadingMore || isLoading || !hasMore) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _repository.fetchOrders(
        status: statusFilter,
        page: _page + 1,
        perPage: _perPage,
      );
      orders = [...orders, ...result.orders];
      _page = result.page;
      _totalPages = result.totalPages;
    } catch (_) {
      // Keep whatever we already have; the user can scroll and retry.
    }

    isLoadingMore = false;
    notifyListeners();
  }

  Future<void> setStatusFilter(String? status) async {
    if (statusFilter == status) return;
    statusFilter = status;
    await refresh();
  }
}
